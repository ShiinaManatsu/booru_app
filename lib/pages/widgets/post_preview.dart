import 'package:auto_route/auto_route.dart';
import 'package:booru_app/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';

double postPreviewBorder = 2;

class PostPreview extends StatefulWidget {
  final Post post;
  PostPreview({this.post});

  @override
  _PostPreviewState createState() => _PostPreviewState();
}

class _PostPreviewState extends State<PostPreview>
    with AutomaticKeepAliveClientMixin{
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MouseRegion(
      onEnter: (event) => setState(() => _isHover = true),
      onExit: (event) => setState(() => _isHover = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        curve: Curves.ease,
        decoration: BoxDecoration(
          border: Border.all(
              color: !_isHover ? Colors.black12 : Colors.pink,
              width: postPreviewBorder),
        ),
        child: GestureDetector(
          onTap: () => ExtendedNavigator.root.push(Routes.postViewPage,
              arguments: PostViewPageArguments(post: widget.post)),
          child: Hero(
            tag: widget.post,
            child: Image.network(
              widget.post.previewUrl,
              height: AppSettings.fixedPostHeight - postPreviewBorder * 2,
              width: widget.post.widthInPanel - postPreviewBorder * 2,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
