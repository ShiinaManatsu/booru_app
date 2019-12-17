import 'package:flutter/material.dart';
import 'package:yande_web/main.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';

class PostPreview extends StatefulWidget {
  final Post post;
  PostPreview({this.post});

  @override
  _PostPreviewState createState() => _PostPreviewState();
}

class _PostPreviewState extends State<PostPreview>
    with AutomaticKeepAliveClientMixin {
  final double fixedHeight = 256.0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, postViewPage,
              arguments: {"post": widget.post});
        },
        child: Hero(
          tag: widget.post,
          child: Image.network(
            widget.post.previewUrl,
            height: AppSettings.fixedPostHeight,
            width: widget.post.widthInPanel - 10,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
