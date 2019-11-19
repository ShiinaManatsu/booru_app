import 'package:flutter/material.dart';
import 'package:yande_web/models/booru_posts.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:yande_web/extensions/list_extension.dart';
import 'post_preview.dart';

class PostWaterfall extends StatefulWidget {
  // The width this widght will take
  @required
  final double panelWidth ;

  PostWaterfall({this.panelWidth});

  @override
  _PostWaterfallState createState() => _PostWaterfallState();
}

class _PostWaterfallState extends State<PostWaterfall> {
  ScrollController _controller;
  bool isFinishedFetch = true;
  List<Post> posts = List<Post>();
  List<List<Post>> fixedPosts = List<List<Post>>();
  BooruPosts _booruPosts;

  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }

    // Page content
  Container buildWidght() {
    _controller = ScrollController();
    var s = Container(
        child: SingleChildScrollView(
      controller: _controller,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 40, 0, 0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[]..addAll(_buildPostPreview()),
          )),
    ));
    _controller.addListener(_scrollListener);
    return s;
  }

   _scrollListener() {
    // Reach the bottom
    if (_controller.offset >= _controller.position.maxScrollExtent - 800 &&
        !_controller.position.outOfRange) {
      print('Reach the bottom');

      if (isFinishedFetch) {
        isFinishedFetch = false;
        _booruPosts.page++;
        _booruPosts.setType(FetchType.Post).fetchPosts().then((value) {
          setState(() {
            posts.addAll(value.where((o) => !posts.contains(o)));
            fixedPosts.addAllPost(posts, widget.panelWidth - 10);
            isFinishedFetch = true;
          });
        });
      }
    }
    // //  Reach the top
    // if (_controller.offset <= _controller.position.minScrollExtent &&
    //     !_controller.position.outOfRange) {
    // }
  }

  _buildPostPreview() {
    var list = new List<PostPreview>();
    fixedPosts.forEach((x) {
      x.forEach((f) {
        list.add(PostPreview(
          post: f,
        ));
      });
    });
    return list;
  }
}