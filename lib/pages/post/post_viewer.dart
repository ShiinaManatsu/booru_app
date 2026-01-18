import 'dart:async';
import 'dart:ui';
import 'package:booru_app/main.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/models/yande/tags.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:booru_app/utils/aura_controller.dart';
import 'package:booru_app/utils/clipboard_image.dart';
import 'package:url_launcher/url_launcher.dart';

class PostViewer extends StatefulWidget {
  const PostViewer({super.key, required this.post});

  final Post post;

  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  AuraHandle? _auraHandle;
  bool _downloading = false;
  bool _copyingToClipboard = false;

  late Post _currentPost;
  bool _parentLoading = false;
  List<Post>? _parentGroup;

  static final Map<String, TagType> _tagTypeCache = <String, TagType>{};

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    unawaited(_maybeLoadParentGroup());
  }

  @override
  void dispose() {
    if (_auraHandle != null) {
      AuraController.instance.pop(_auraHandle!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = _currentPost;
    final heroThumbUrl = _heroThumbUrl(post);
    return Stack(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 800),
          builder: (context, time, child) => Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) => _showContextMenu(details.globalPosition, post),
              child: Listener(
                onPointerSignal: (event) {
                  if (event is! PointerScrollEvent) return;
                  if (_parentGroup == null || _parentGroup!.isEmpty) return;
                  if (HardwareKeyboard.instance.isControlPressed) return;

                  final dy = event.scrollDelta.dy;
                  if (dy == 0) return;
                  _stepInParentGroup(dy > 0 ? 1 : -1);
                },
                child: PhotoView.customChild(
                  backgroundDecoration: BoxDecoration(color: Color.lerp(Colors.black, Colors.transparent, time)),
                  child: _buildHeroAwareImage(
                    time: time,
                    heroThumbUrl: heroThumbUrl,
                    post: post,
                  ),
                  childSize: Size(post.width.toDouble(), post.height.toDouble()),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _GlassButton(
            icon: FontAwesomeIcons.arrowLeft,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _GlassButton(
                icon: FontAwesomeIcons.download,
                onTap: _downloading
                    ? () {}
                    : () async {
                        setState(() => _downloading = true);
                        await taskBloc.downloadNow(post);
                        if (!mounted) return;
                        setState(() => _downloading = false);
                      },
              ),
              const SizedBox(height: 12),
              _GlassButton(
                icon: FontAwesomeIcons.heart,
                onTap: () => BooruAPI.votePost(
                  postID: post.id,
                  type: VoteType.Favorite,
                ),
              ),
              const SizedBox(height: 12),
              _GlassButton(
                icon: FontAwesomeIcons.circleInfo,
                onTap: () => _showPostDetails(post),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // Parent navigation strip
        if (_shouldShowParentStrip)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _ParentStrip(
              loading: _parentLoading,
              posts: _parentGroup,
              selectedPostId: post.id,
              onSelect: _selectPost,
              thumbUrlFor: _stripThumbUrl,
            ),
          ),
      ],
    );
  }

  Future<void> _showContextMenu(Offset globalPosition, Post post) async {
    if (!mounted) return;

    final selected = await showDialog<_ViewerMenuAction>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _ViewerContextMenu(
        anchor: globalPosition,
        copying: _copyingToClipboard,
      ),
    );

    if (selected == null) return;
    switch (selected) {
      case _ViewerMenuAction.copyImage:
        await _copyImageToClipboard(post);
        break;
    }
  }

  String _imageUrlForClipboard(Post post, String heroThumbUrl) {
    return post.fileUrl ?? post.jpegUrl ?? post.sampleUrl ?? post.previewUrl ?? heroThumbUrl;
  }

  Future<void> _copyImageToClipboard(Post post) async {
    if (_copyingToClipboard) return;
    final url = _imageUrlForClipboard(post, _heroThumbUrl(post));
    if (url.trim().isEmpty) return;

    setState(() => _copyingToClipboard = true);
    try {
      await ClipboardImage.copyNetworkImageAsPng(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image copied to clipboard')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copy failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _copyingToClipboard = false);
    }
  }

  bool get _shouldShowParentStrip {
    return _parentLoading || (_parentGroup != null && _parentGroup!.isNotEmpty);
  }

  Widget _buildHeroAwareImage({required double time, required String heroThumbUrl, required Post post}) {
    final image = CachedNetworkImage(
      fit: BoxFit.cover,
      imageUrl: post.jpegUrl ?? post.fileUrl ?? post.sampleUrl ?? heroThumbUrl,
      progressIndicatorBuilder: (context, url, progress) => Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 12.0 * time, sigmaY: 12.0 * time),
            child: CachedNetworkImage(
              fit: BoxFit.contain,
              imageUrl: heroThumbUrl,
              width: post.width.toDouble(),
              height: post.height.toDouble(),
            ),
          ),
          const Center(
            child: SizedBox(
              height: 160,
              width: 160,
              child: CircularProgressIndicator(strokeWidth: 12),
            ),
          ),
        ],
      ),
    );

    // Keep the Hero only for the initial post opened from the grid.
    if (post.id != widget.post.id) return image;
    return Hero(
      tag: widget.post,
      child: image,
    );
  }

  String _stripThumbUrl(Post post) {
    // For the strip, always use lightweight thumbs.
    return post.previewUrl;
  }

  Future<void> _maybeLoadParentGroup() async {
    final parentId = widget.post.parentId;
    final hasParent = widget.post.hasParent || (parentId != null && parentId != 0);
    final hasChildren = widget.post.hasChildren;
    if (!hasParent && !hasChildren) return;

    setState(() => _parentLoading = true);
    try {
      // 1) Parent post itself (if available)
      Post? parent;
      if (parentId != null && parentId != 0) {
        final parentList = await BooruAPI.fetchSpecficPost(id: parentId.toString());
        parent = parentList.isNotEmpty ? parentList.first : null;
      }

      // 2) Siblings/current: children of this post's parent
      final siblingOrSelfGroup = <Post>[];
      if (parentId != null && parentId != 0) {
        siblingOrSelfGroup.addAll(
          await BooruAPI.fetchTagged(args: TaggedArgs(tags: 'parent:$parentId', page: 1)),
        );
      }

      // 3) Children group: when this post has children, search parent:<selfId>
      final childGroup = <Post>[];
      if (hasChildren) {
        childGroup.addAll(
          await BooruAPI.fetchTagged(args: TaggedArgs(tags: 'parent:${widget.post.id}', page: 1)),
        );
      }

      final map = <int, Post>{};
      if (parent != null) map[parent.id] = parent;
      for (final p in siblingOrSelfGroup) {
        map[p.id] = p;
      }
      for (final p in childGroup) {
        map[p.id] = p;
      }

      // Ensure current post is present (in case API omits it for some reason).
      map[_currentPost.id] = _currentPost;

      final group = map.values.toList(); //..sort((a, b) => a.id.compareTo(b.id));
      // group.sort((a, b) => a.id.compareTo(b.id));

      if (!mounted) return;
      setState(() {
        _parentGroup = group;
      });
    } catch (_) {
      // Ignore failures; the viewer should still work.
    } finally {
      if (mounted) setState(() => _parentLoading = false);
    }
  }

  void _selectPost(Post post) {
    if (post.id == _currentPost.id) return;
    setState(() {
      _currentPost = post;
    });
  }

  void _stepInParentGroup(int direction) {
    final group = _parentGroup;
    if (group == null || group.isEmpty) return;

    final currentId = _currentPost.id;
    final i = group.indexWhere((p) => p.id == currentId);
    if (i < 0) return;

    var next = i + direction;
    if (next < 0) next = 0;
    if (next >= group.length) next = group.length - 1;
    _selectPost(group[next]);
  }

  String _heroThumbUrl(Post post) {
    if (AppSettings.previewQuality == PreviewQuality.Medium) {
      return post.sampleUrl ?? post.previewUrl;
    }
    return post.previewUrl;
  }

  Future<void> _showPostDetails(Post post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Material(
                  color: Colors.black.withAlpha((0.55 * 255).round()),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.72,
                    ),
                    child: _PostDetailsSheet(
                      post: post,
                      resolveTagTypes: _resolveTagTypes,
                      onOpenUrl: _tryOpenExternalUrl,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _tryOpenExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (uri.scheme != 'http' && uri.scheme != 'https') return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<Map<String, TagType>> _resolveTagTypes(List<String> tags) async {
    const concurrency = 6;
    final normalized = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList(growable: false);

    Future<TagType> fetchOne(String tag) async {
      final key = tag.toLowerCase();
      final cached = _tagTypeCache[key];
      if (cached != null) return cached;

      try {
        var list = await BooruAPI.fetchTags(limit: 1, name: tag);
        if (list.isEmpty) {
          list = await BooruAPI.fetchTags(limit: 1, namePattern: tag);
        }
        final type = list.isNotEmpty ? list.first.type : TagType.None;
        _tagTypeCache[key] = type;
        return type;
      } catch (_) {
        _tagTypeCache[key] = TagType.None;
        return TagType.None;
      }
    }

    final pending = <String>[];
    for (final t in normalized) {
      final key = t.toLowerCase();
      if (!_tagTypeCache.containsKey(key)) pending.add(t);
    }

    for (var i = 0; i < pending.length; i += concurrency) {
      final chunk = pending.sublist(i, (i + concurrency) > pending.length ? pending.length : (i + concurrency));
      await Future.wait(chunk.map(fetchOne));
    }

    final out = <String, TagType>{};
    for (final t in normalized) {
      out[t] = _tagTypeCache[t.toLowerCase()] ?? TagType.None;
    }
    return out;
  }
}

class _ParentStrip extends StatelessWidget {
  const _ParentStrip({
    required this.loading,
    required this.posts,
    required this.selectedPostId,
    required this.onSelect,
    required this.thumbUrlFor,
  });

  final bool loading;
  final List<Post>? posts;
  final int selectedPostId;
  final ValueChanged<Post> onSelect;
  final String Function(Post post) thumbUrlFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasList = posts != null && posts!.isNotEmpty;
        const thumb = 76.0;
        const gap = 8.0;
        const padH = 10.0;
        const padV = 10.0;

        final contentWidth = hasList ? (posts!.length * thumb) + ((posts!.length - 1) * gap) + (padH * 2) + 2.0 : 160.0;
        final unclampedWidth = contentWidth > constraints.maxWidth ? constraints.maxWidth : contentWidth;
        final targetWidth = unclampedWidth.ceilToDouble();

        final contentHeight = hasList ? (thumb + (padV * 2) + 2.0) : 52.0;
        final targetHeight = contentHeight.ceilToDouble();

        return Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: targetWidth,
            height: targetHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.38 * 255).round()),
                    border: Border.all(color: Colors.white.withAlpha((0.10 * 255).round())),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                  child: loading && !hasList
                      ? const Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : _ParentThumbList(
                          posts: posts ?? const <Post>[],
                          selectedPostId: selectedPostId,
                          onSelect: onSelect,
                          thumbUrlFor: thumbUrlFor,
                          thumbSize: thumb,
                          gap: gap,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParentThumbList extends StatefulWidget {
  const _ParentThumbList({
    required this.posts,
    required this.selectedPostId,
    required this.onSelect,
    required this.thumbUrlFor,
    required this.thumbSize,
    required this.gap,
  });

  final List<Post> posts;
  final int selectedPostId;
  final ValueChanged<Post> onSelect;
  final String Function(Post post) thumbUrlFor;
  final double thumbSize;
  final double gap;

  @override
  State<_ParentThumbList> createState() => _ParentThumbListState();
}

class _ParentThumbListState extends State<_ParentThumbList> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (event) {
            if (event is! PointerScrollEvent) return;
            if (!_controller.hasClients) return;

            // Map vertical wheel movement to horizontal scroll.
            final delta = event.scrollDelta.dy;
            if (delta == 0) return;
            final next = (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent);
            _controller.jumpTo(next);
          },
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.posts.length, (index) {
                    final p = widget.posts[index];
                    final selected = p.id == widget.selectedPostId;
                    return Padding(
                      padding: EdgeInsets.only(right: index == widget.posts.length - 1 ? 0 : widget.gap),
                      child: SizedBox(
                        width: widget.thumbSize,
                        height: widget.thumbSize,
                        child: _ThumbTile(
                          post: p,
                          selected: selected,
                          url: widget.thumbUrlFor(p),
                          onTap: () => widget.onSelect(p),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    required this.post,
    required this.selected,
    required this.url,
    required this.onTap,
  });

  final Post post;
  final bool selected;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Colors.white : Colors.white.withAlpha((0.25 * 255).round());
    final bg = selected ? Colors.white.withAlpha((0.14 * 255).round()) : Colors.transparent;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostDetailsSheet extends StatefulWidget {
  const _PostDetailsSheet({
    required this.post,
    required this.resolveTagTypes,
    required this.onOpenUrl,
  });

  final Post post;
  final Future<Map<String, TagType>> Function(List<String> tags) resolveTagTypes;
  final Future<void> Function(String url) onOpenUrl;

  @override
  State<_PostDetailsSheet> createState() => _PostDetailsSheetState();
}

class _PostDetailsSheetState extends State<_PostDetailsSheet> {
  late final List<String> _tags;
  late final Future<Map<String, TagType>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _tags = (widget.post.tags ?? '').split(RegExp(r'\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    _typesFuture = widget.resolveTagTypes(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final mb = (p.fileSize / 1000000.0);
    final source = p.sourceUrl?.trim();
    final sourceIsLink = source != null && source.isNotEmpty && (Uri.tryParse(source)?.hasScheme ?? false);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Post #${p.id}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _kv('Score', '${p.score}'),
              _kv('File', '${mb.toStringAsFixed(1)} MB'),
            ],
          ),
          const SizedBox(height: 10),
          if (source != null && source.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Source', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    if (sourceIsLink)
                      TextButton.icon(
                        onPressed: () => widget.onOpenUrl(source),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  source,
                  style: TextStyle(color: sourceIsLink ? Colors.white : Colors.white70),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const Text('Tags', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<Map<String, TagType>>(
              future: _typesFuture,
              builder: (context, snapshot) {
                final typeMap = snapshot.data ?? const <String, TagType>{};
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((t) {
                      final type = typeMap[t] ?? TagType.None;
                      final color = TagToColorMap[type] ?? const Color.fromARGB(255, 118, 118, 118);
                      return Chip(
                        label: Text(t, style: const TextStyle(color: Colors.white)),
                        backgroundColor: color.withAlpha((0.35 * 255).round()),
                        side: BorderSide(color: color.withAlpha((0.70 * 255).round())),
                      );
                    }).toList(growable: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.06 * 255).round()),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha((0.10 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(k, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 8),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withAlpha((0.08 * 255).round()),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FaIcon(icon, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ViewerMenuAction { copyImage }

class _ViewerContextMenu extends StatelessWidget {
  const _ViewerContextMenu({
    required this.anchor,
    required this.copying,
  });

  final Offset anchor;
  final bool copying;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const menuWidth = 220.0;
    const menuHeight = 54.0;
    const padding = 8.0;

    final left = anchor.dx.clamp(padding, size.width - menuWidth - padding);
    final top = anchor.dy.clamp(padding, size.height - menuHeight - padding);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.55 * 255).round()),
                    border: Border.all(
                      color: Colors.white.withAlpha((0.12 * 255).round()),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: copying ? null : () => Navigator.of(context).pop(_ViewerMenuAction.copyImage),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            copying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    FontAwesomeIcons.copy,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                copying ? 'Copying…' : 'Copy image',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
