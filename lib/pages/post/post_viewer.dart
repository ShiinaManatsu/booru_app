import 'dart:ui';
import 'package:adaptive_aura/adaptive_aura.dart';
import 'package:booru_app/main.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:booru_app/utils/aura_controller.dart';

class PostViewer extends StatefulWidget {
  const PostViewer({super.key, required this.post});

  final Post post;

  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  AuraHandle? _auraHandle;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
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
    final heroThumbUrl = _heroThumbUrl(widget.post);
    return AdaptiveAuraContainer(
      image: CachedNetworkImageProvider(
        heroThumbUrl,
      ),
      auraStyle: AuraStyle.gradient,
      variety: 0.7,
      colorIntensity: 0.8,
      blurStrength: 15.0,
      animationValue: 0.4,
      animationDuration: Duration(milliseconds: 800),
      colorTransitionDuration: Duration(milliseconds: 300),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if ((event.buttons & kBackMouseButton) != 0) {
            Navigator.of(context).maybePop();
          }
        },
        child: Stack(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 800),
              builder: (context, value, child) => Positioned.fill(
                child: PhotoView.customChild(
                  backgroundDecoration: BoxDecoration(color: Color.lerp(Colors.black, Colors.transparent, value)),
                  child: Hero(
                    tag: 'post-${widget.post.id}',
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: widget.post.jpegUrl ?? widget.post.fileUrl ?? widget.post.sampleUrl ?? heroThumbUrl,
                      progressIndicatorBuilder: (context, url, progress) => CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: heroThumbUrl,
                      ),
                    ),
                  ),
                  childSize: Size(widget.post.width.toDouble(), widget.post.height.toDouble()),
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
                            await taskBloc.downloadNow(widget.post);
                            if (!mounted) return;
                            setState(() => _downloading = false);
                          },
                  ),
                  const SizedBox(height: 12),
                  _GlassButton(
                    icon: FontAwesomeIcons.heart,
                    onTap: () => BooruAPI.votePost(
                      postID: widget.post.id,
                      type: VoteType.Favorite,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _heroThumbUrl(Post post) {
    if (AppSettings.previewQuality == PreviewQuality.Medium) {
      return post.sampleUrl ?? post.previewUrl;
    }
    return post.previewUrl;
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
