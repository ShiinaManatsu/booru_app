import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';

class PostPreview extends StatefulWidget {
  final Post post;
  PostPreview({this.post});

  @override
  _PostPreviewState createState() => _PostPreviewState();
}

class _PostPreviewState extends State<PostPreview> with AutomaticKeepAliveClientMixin {
  final double fixedHeight = 256.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
        onTap: () {},
        child: Image(
          image: Image.network(widget.post.previewUrl).image,
          height: AppSettings.fixedPostHeight,
          width: widget.post.widthInPanel-10,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}
