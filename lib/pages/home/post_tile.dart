import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/pages/post/post_viewer.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PostTile extends StatefulWidget {
  const PostTile({super.key, required this.post});

  final Post post;

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final url = _pickUrl(widget.post);
    final radius = BorderRadius.circular(AppSettings.masonryGridBorderRadius);
    final ratio = _safeAspectRatio(widget.post);
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedScale(
        scale: hover ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: hover ? 3 : 1,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PostViewer(post: widget.post)),
              );
            },
            child: Hero(
              // tag: 'post-${widget.post.id}',
              tag: widget.post,
              flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                // During pop, the destination grid tile may briefly rebuild into its
                // placeholder while the image provider resolves again. Avoid showing
                // a spinner/placeholder in the hero transition.
                if (flightDirection == HeroFlightDirection.pop) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }

                final fromHero = fromHeroContext.widget as Hero;
                return fromHero.child;
              },
              child: AspectRatio(
                // Keep a stable size in the masonry grid even if the image widget
                // is disposed/recreated by cache/scrolling.
                aspectRatio: ratio,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => ColoredBox(
                    color: Colors.black.withValues(alpha: 0.18),
                    child: const Center(child: Icon(Icons.image_outlined, color: Colors.white24)),
                  ),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                ),
              ),
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
    // Prevent extreme aspect ratios from producing unusably thin tiles.
    return r.clamp(0.2, 5.0);
  }

  String _pickUrl(Post post) {
    if (AppSettings.previewQuality == PreviewQuality.Medium) {
      return post.sampleUrl ?? post.previewUrl;
    }
    return post.previewUrl;
  }
}
