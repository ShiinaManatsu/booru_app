import 'dart:async';

import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/tag_index.dart';
import 'package:booru_app/pages/home/post_feed.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.booruApi});

  final BooruAPI booruApi;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  String _tags = '';
  final List<String> _selectedTags = <String>[];

  ClientType _client = AppSettings.currentClient;
  late final VoidCallback _clientListener;
  Timer? _debounce;
  Timer? _tagIndexTimeoutTimer;
  bool _loadingSuggestions = false;
  List<String> _suggestions = const <String>[];
  int _suggestSeq = 0;

  @override
  void initState() {
    super.initState();

    _clientListener = _handleClientChanged;
    AppSettings.currentClientListenable.addListener(_clientListener);

    unawaited(_ensureTagIndex());
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _suggestions.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              if (_selectedTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedTags
                              .map(
                                (t) => InputChip(
                                  label: Text(t),
                                  onDeleted: () => _removeTag(t),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: _clearAllTags,
                        icon: const Icon(FontAwesomeIcons.trashCan),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent) return KeyEventResult.ignored;
                        if (event.logicalKey == LogicalKeyboardKey.backspace && _controller.text.isEmpty && _selectedTags.isNotEmpty) {
                          setState(() {
                            _selectedTags.removeLast();
                          });
                          return KeyEventResult.handled;
                        }

                        if (event.logicalKey == LogicalKeyboardKey.space) {
                          // Space = quick accept (commit a tag), but do NOT submit the search.
                          // Keeps the caret in the input for rapid tagging.
                          final hasText = _controller.text.trim().isNotEmpty;
                          if (!hasText) {
                            // Prevent focusing chips / buttons when space is pressed.
                            return KeyEventResult.handled;
                          }

                          if (_suggestions.isNotEmpty) {
                            _addTag(_suggestions.first);
                          } else {
                            _addTypedTag();
                          }

                          _refocusInput();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _inputFocusNode,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                          hintText: language.content.searchTags,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: _onQueryChanged,
                        onSubmitted: (_) => _submitSelected(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitSelected,
                    child: const Icon(FontAwesomeIcons.arrowRight),
                  ),
                ],
              ),
              if (_loadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (showSuggestions)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SuggestionChips(
                    items: _suggestions,
                    onTap: _addTag,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _tags.isEmpty
              ? Center(child: Text(language.content.searchTags))
              : PostFeed(
                  key: ValueKey('search_${_client.name}_$_tags'),
                  title: language.content.search,
                  initialFetchType: FetchType.Search,
                  booruApi: widget.booruApi,
                  tags: _tags,
                ),
        ),
      ],
    );
  }

  void _submitSelected() {
    _addTypedTag();
    final joined = _selectedTags.join(' ').trim();
    setState(() {
      _tags = joined;
      _suggestions = const <String>[];
      _loadingSuggestions = false;
    });
  }

  void _refocusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_inputFocusNode);
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 140), () {
      unawaited(_updateSuggestions(value));
    });
  }

  void _handleClientChanged() {
    final next = AppSettings.currentClientListenable.value;
    if (next == _client) return;

    _suggestSeq++;
    setState(() {
      _client = next;
      _tags = '';
      _selectedTags.clear();
      _controller.clear();
      _suggestions = const <String>[];
      _loadingSuggestions = false;
    });

    unawaited(_ensureTagIndex());
  }

  Future<void> _ensureTagIndex() async {
    // If already built, keep it silent.
    if (TagIndexService.instance.isReady(client: _client)) return;

    // Build index in background; keep UI responsive.
    if (mounted) setState(() => _loadingSuggestions = true);
    try {
      // Avoid Future.timeout here: it creates an internal Timer that can show
      // up as a "pending timer" in widget tests when the tree is disposed
      // quickly. Instead, manage our own cancelable timer.
      _tagIndexTimeoutTimer?.cancel();
      final timeout = Completer<void>();
      _tagIndexTimeoutTimer = Timer(const Duration(seconds: 6), () {
        if (!timeout.isCompleted) timeout.complete();
      });

      await Future.any([
        TagIndexService.instance.ensureLoaded(client: _client).catchError((_) {}),
        timeout.future,
      ]);
    } catch (_) {
      // Ignore failures; remote suggestions still work.
    } finally {
      _tagIndexTimeoutTimer?.cancel();
      _tagIndexTimeoutTimer = null;
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _updateSuggestions(String raw) async {
    final token = raw.trim();
    final seq = ++_suggestSeq;
    if (token.isEmpty) {
      if (mounted) setState(() => _suggestions = const <String>[]);
      return;
    }

    final clientAtRequest = _client;
    final tokenLower = token.toLowerCase();

    // 1) Prefer local cached index (fast, no network).
    if (TagIndexService.instance.isReady(client: _client)) {
      final local =
          TagIndexService.instance.suggest(token, client: _client, limit: 40).where((t) => !_selectedTags.contains(t)).take(24).toList(growable: false);
      if (mounted) setState(() => _suggestions = local);

      // 1b) Refine ordering by count (remote) without blocking typing.
      // Cloudflare/network failures are ignored; local list remains.
      unawaited(_refineSuggestionsByCount(token, seq, clientAtRequest));
      return;
    }

    // 2) Fallback to remote prefix search.
    setState(() => _loadingSuggestions = true);
    try {
      final entries = await BooruAPI.fetchTags(
        limit: 60,
        order: TagOrder.count,
        namePattern: token,
      );
      if (seq != _suggestSeq || clientAtRequest != _client) return;
      if (_controller.text.trim().toLowerCase() != tokenLower) return;

      entries.sort((a, b) => b.count.compareTo(a.count));
      final list = entries
          .map((e) => e.name)
          .where(
            (name) => name.isNotEmpty && !_selectedTags.contains(name) && name.toLowerCase().startsWith(tokenLower),
          )
          .take(24)
          .toList(growable: false);
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {
      if (mounted) setState(() => _suggestions = const <String>[]);
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _refineSuggestionsByCount(String token, int seq, ClientType clientAtRequest) async {
    if (token.isEmpty) return;

    final tokenLower = token.toLowerCase();

    try {
      // Keep suggestions relevant to the user's input:
      // re-rank *local candidates* by remote counts, instead of replacing with
      // remote results (some servers may return broad "top tags" lists).
      final localCandidates = TagIndexService.instance
          .suggest(token, client: clientAtRequest, limit: 160)
          .where((name) => name.isNotEmpty && !_selectedTags.contains(name) && name.toLowerCase().startsWith(tokenLower))
          .toList(growable: false);

      if (localCandidates.isEmpty) return;

      final entries = await BooruAPI.fetchTags(
        limit: 200,
        order: TagOrder.count,
        namePattern: token,
      );

      // Ignore stale results (typing / client switch).
      if (!mounted) return;
      if (seq != _suggestSeq) return;
      if (clientAtRequest != _client) return;
      if (_controller.text.trim().toLowerCase() != tokenLower) return;

      final counts = <String, int>{
        for (final e in entries)
          if (e.name.isNotEmpty) e.name: e.count,
      };

      final ranked = [...localCandidates]..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

      setState(() => _suggestions = ranked.take(24).toList(growable: false));
    } catch (_) {
      // Keep local suggestions.
    }
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return;
    if (_selectedTags.contains(t)) return;

    // Invalidate in-flight suggestion refinements for the previous token.
    _suggestSeq++;

    setState(() {
      _selectedTags.add(t);
      _suggestions = const <String>[];
    });
    _controller.clear();
    _refocusInput();
  }

  void _addTypedTag() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    // Invalidate in-flight suggestion refinements for the previous token.
    _suggestSeq++;

    // Allow typing multiple tags separated by whitespace.
    final parts = raw.split(RegExp(r'\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    var changed = false;
    for (final p in parts) {
      if (_selectedTags.contains(p)) continue;

      final isValid = TagIndexService.instance.isReady(client: _client) ? TagIndexService.instance.containsExact(p, client: _client) : _suggestions.contains(p);

      if (!isValid) continue;

      _selectedTags.add(p);
      changed = true;
    }
    if (changed) {
      setState(() {
        _suggestions = const <String>[];
        _loadingSuggestions = false;
      });
    }
    _controller.clear();
    _refocusInput();
  }

  void _removeTag(String tag) {
    _suggestSeq++;
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _clearAllTags() {
    _suggestSeq++;
    setState(() {
      _selectedTags.clear();
      _tags = '';
      _suggestions = const <String>[];
      _loadingSuggestions = false;
    });
    _controller.clear();
    _refocusInput();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tagIndexTimeoutTimer?.cancel();
    AppSettings.currentClientListenable.removeListener(_clientListener);
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.items, required this.onTap});

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha((0.40 * 255).round()),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (tag) => ActionChip(
                    label: Text(tag, style: const TextStyle(color: Colors.white)),
                    onPressed: () => onTap(tag),
                    backgroundColor: Colors.white.withAlpha((0.14 * 255).round()),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}
