import 'dart:async';

import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/models/yande/pool.dart';
import 'package:booru_app/pages/pool/pool_detail_page.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:booru_app/utils/damped_scroll.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PoolPage extends StatefulWidget {
  const PoolPage({super.key, required this.booruApi});

  final BooruAPI booruApi;

  @override
  State<PoolPage> createState() => _PoolPageState();
}

class _PoolPageState extends State<PoolPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final DampedScrollController _scrollController = DampedScrollController(
    wheelDamping: 1.25,
    wheelAnimDuration: const Duration(milliseconds: 300),
  );

  ClientType _client = AppSettings.currentClient;
  late final VoidCallback _clientListener;

  Timer? _debounce;
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;

  String _query = '';
  int _page = 1;
  bool _hasMore = true;
  final List<Pool> _pools = <Pool>[];

  final Map<int, Post?> _coverPostByPoolId = <int, Post?>{};
  final Set<int> _coverLoading = <int>{};
  final Set<int> _coverFailed = <int>{};

  @override
  void initState() {
    super.initState();

    _clientListener = _handleClientChanged;
    AppSettings.currentClientListenable.addListener(_clientListener);
    unawaited(_fetchFirstPage());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _controller.dispose();
    AppSettings.currentClientListenable.removeListener(_clientListener);
    super.dispose();
  }

  void _handleClientChanged() {
    final next = AppSettings.currentClientListenable.value;
    if (next == _client) return;
    _client = next;
    unawaited(_fetchFirstPage());
  }

  Future<void> _fetchFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
      _pools.clear();
      _coverPostByPoolId.clear();
      _coverLoading.clear();
      _coverFailed.clear();
    });

    try {
      final result = await BooruAPI.fetchPools(
        query: _query.trim().isEmpty ? null : _query.trim(),
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _pools.addAll(result);
        _hasMore = result.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchMore() async {
    if (!_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final nextPage = _page + 1;
      final result = await BooruAPI.fetchPools(
        query: _query.trim().isEmpty ? null : _query.trim(),
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _pools.addAll(result);
        if (result.isEmpty) _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      unawaited(_fetchFirstPage());
    });
  }

  void _openPool(Pool pool) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PoolDetailPage(pool: pool, booruApi: widget.booruApi),
      ),
    );
  }

  void _ensureCover(Pool pool) {
    final id = pool.id;

    // If API already provided posts, no need to fetch.
    if (pool.posts != null && pool.posts!.isNotEmpty) return;

    if (_coverPostByPoolId.containsKey(id)) return;
    if (_coverLoading.contains(id)) return;
    if (_coverFailed.contains(id)) return;

    _coverLoading.add(id);
    unawaited(() async {
      try {
        final full = await BooruAPI.fetchPoolShow(id: id, page: 1);
        final cover = (full.posts != null && full.posts!.isNotEmpty) ? full.posts!.first : null;

        if (!mounted) return;
        setState(() {
          _coverPostByPoolId[id] = cover;
          if (cover == null) {
            _coverFailed.add(id);
          }
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _coverFailed.add(id));
      } finally {
        _coverLoading.remove(id);
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _controller.clear();
                _onQueryChanged('');
                _inputFocusNode.requestFocus();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                unawaited(_fetchFirstPage());
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _controller,
              focusNode: _inputFocusNode,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(FontAwesomeIcons.layerGroup),
                hintText: language.content.pools,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchFirstPage,
            child: Builder(
              builder: (context) {
                if (_loading && _pools.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null && _pools.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text('Error: $_error')),
                    ],
                  );
                }

                if (_pools.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(language.content.nothingToShow)),
                    ],
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollUpdateNotification || n is OverscrollNotification) {
                      final metrics = n.metrics;
                      if (_hasMore && !_loadingMore && !_loading && metrics.extentAfter <= 800) {
                        unawaited(_fetchMore());
                      }
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const DampedScrollPhysics(
                      parent: ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: _columnsForWidth(MediaQuery.of(context).size.width),
                          mainAxisSpacing: AppSettings.masonryGridSpacing,
                          crossAxisSpacing: AppSettings.masonryGridSpacing,
                          childCount: _pools.length,
                          itemBuilder: (context, index) {
                            final pool = _pools[index];
                            final coverPost = (pool.posts != null && pool.posts!.isNotEmpty) ? pool.posts!.first : _coverPostByPoolId[pool.id];
                            if (coverPost == null) {
                              _ensureCover(pool);
                            }
                            return _PoolCard(
                              pool: pool,
                              coverPost: coverPost,
                              onTap: () => _openPool(pool),
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 110),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _loadingMore
                                  ? const SizedBox(
                                      key: ValueKey('loading_more'),
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const SizedBox(key: ValueKey('loading_more_idle'), height: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  int _columnsForWidth(double width) {
    final target = width ~/ 280;
    return target.clamp(2, 6);
  }
}

class _PoolCard extends StatefulWidget {
  const _PoolCard({
    required this.pool,
    required this.coverPost,
    required this.onTap,
  });

  final Pool pool;
  final Post? coverPost;
  final VoidCallback onTap;

  @override
  State<_PoolCard> createState() => _PoolCardState();
}

class _PoolCardState extends State<_PoolCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final pool = widget.pool;
    final coverPost = widget.coverPost;
    final coverUrl = coverPost == null ? null : _pickPostUrl(coverPost);
    final ratio = coverPost == null ? 1.0 : _safeAspectRatio(coverPost);
    final radius = BorderRadius.circular(AppSettings.masonryGridBorderRadius);

    final title = pool.name.isEmpty ? 'Pool #${pool.id}' : pool.name;
    final subtitle = pool.postCount > 0 ? '${pool.postCount} posts' : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: _hover ? 3 : 1,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: ratio,
                  child: coverUrl == null
                      ? ColoredBox(
                          color: Colors.black.withValues(alpha: 0.18),
                        )
                      : CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ColoredBox(
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _safeAspectRatio(Post post) {
    final w = post.width <= 0 ? 1 : post.width;
    final h = post.height <= 0 ? 1 : post.height;
    final r = w / h;
    return r.clamp(0.2, 5.0);
  }

  String _pickPostUrl(Post post) {
    if (AppSettings.previewQuality == PreviewQuality.Medium) {
      return post.sampleUrl ?? post.previewUrl;
    }
    return post.previewUrl;
  }
}
