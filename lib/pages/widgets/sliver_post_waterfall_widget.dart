import 'package:flutter/material.dart';
import 'package:yande_web/models/booru_posts.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:yande_web/extensions/list_extension.dart';
import 'post_preview.dart';

class SliverPostWaterfall extends StatefulWidget {
  // The width this widght will take
  @required
  final double panelWidth;
  final ScrollController controller;

  SliverPostWaterfall({this.panelWidth,this.controller, Key key}) : super(key: key);

  @override
  _SliverPostWaterfallState createState() => _SliverPostWaterfallState();
}

class _SliverPostWaterfallState extends State<SliverPostWaterfall> {
  ScrollController _controller;
  bool isFinishedFetch = true;
  List<Post> posts = List<Post>();
  List<List<Post>> fixedPosts = List<List<Post>>();
  BooruPosts _booruPosts;

  _SliverPostWaterfallState() {
    _booruPosts = new BooruPosts();
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([_buildSliver()]),
    );
  }

  Widget _buildSliver() {
    if (fixedPosts.length == 0) {
      return Center(child: Text("Loading"));
    } else {
      return buildWidght();
    }
  }

  // Page content
  Container buildWidght() {
    var s = Container(
        child: SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 40, 0, 0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[]..addAll(_buildPostPreview()),
          )),
    ));
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

  @override
  void initState() {
    super.initState();
    _controller=widget.controller;
    _controller.addListener(_scrollListener);

    isFinishedFetch = false;
    _booruPosts.setType(FetchType.Post).fetchPosts().then((value) {
      setState(() {
        posts.addAll(value);
        fixedPosts.addAllPost(posts, widget.panelWidth - 15);
        isFinishedFetch = true;
      });
    });
  }
}
