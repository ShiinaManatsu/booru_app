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
            width: widget.post.widthInPanel,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
