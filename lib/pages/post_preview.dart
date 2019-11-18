import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yande_web/models/yande/post.dart';

class PostPreview extends StatefulWidget {
  final Post post;
  PostPreview({this.post});

  @override
  _PostPreviewState createState() => _PostPreviewState();
}

class _PostPreviewState extends State<PostPreview> {
  final double fixedHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 10, 10),
      child: GestureDetector(
        onTap: () {},
        child: Image(
          image: Image.network(widget.post.preview_url).image,
          height: fixedHeight,
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }
}
