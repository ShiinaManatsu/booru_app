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
  double _borderWidth = 2;
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MouseRegion(
      onEnter: (event) => setState(() => _isHover = true),
      onExit: (event) => setState(() => _isHover = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
        decoration: BoxDecoration(
          border: Border.all(
              color: !_isHover ? Colors.black54 : Colors.pink,
              width: _borderWidth),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, postViewPage,
                arguments: {"post": widget.post});
          },
          child: Hero(
            tag: widget.post,
            child: Image.network(
              widget.post.previewUrl,
              height: AppSettings.fixedPostHeight - _borderWidth * 2,
              width: widget.post.widthInPanel - _borderWidth * 2,
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
