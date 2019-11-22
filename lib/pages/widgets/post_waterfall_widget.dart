import 'package:flutter/material.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/extensions/list_extension.dart';
import 'package:yande_web/models/booru_posts.dart';
import 'package:yande_web/pages/widgets/post_preview.dart';

Function(FetchType) updadePost;

class PostWaterfall extends StatefulWidget {
  // The width this widght will take
  @required
  final double panelWidth;

  PostWaterfall({this.panelWidth, Key key}) : super(key: key){
  }

  @override
  _PostWaterfallState createState() => _PostWaterfallState();
}

class _PostWaterfallState extends State<PostWaterfall> {
  ScrollController _controller;
  bool isFinishedFetch = true;
  List<Post> posts = List<Post>();
  List<List<Post>> fixedPosts = List<List<Post>>();
  FetchType currentFetchType = FetchType.Posts;
  BooruPosts _booruPosts;

  int page = 1;

  _PostWaterfallState() {
    updadePost = _updateCall;
    _booruPosts = new BooruPosts();
  }

  _updateCall(FetchType fetchType) {
    if (fetchType == currentFetchType) {
      return;
    } else {
      setState(() {
        fixedPosts.clear();
        currentFetchType = fetchType;
        page = 1;
        _fetchByType(fetchType);
      });
    }
  }

  _fetchByType(FetchType t) {
    isFinishedFetch = false;
    switch (t) {
      case FetchType.Posts:
        _booruPosts.fetchPosts().then((value) {
          posts.addAll(value.where((o) => !posts.contains(o)));
          fixedPosts.addAllPost(posts, widget.panelWidth - 10);
          isFinishedFetch = true;
        });
        break;
      case FetchType.PopularRecent:
        _booruPosts.fetchPopularRecent().then((value) {
          posts.addAll(value.where((o) => !posts.contains(o)));
          fixedPosts.addAllPost(posts, widget.panelWidth - 10);
          isFinishedFetch = true;
        });
        break;
      case FetchType.PopularByWeek:
        _booruPosts.fetchPopularByWeek().then((value) {
          posts.addAll(value.where((o) => !posts.contains(o)));
          fixedPosts.addAllPost(posts, widget.panelWidth - 10);
          isFinishedFetch = true;
        });
        break;
      case FetchType.PopularByMonth:
        _booruPosts.fetchPopularByMonth().then((value) {
          posts.addAll(value.where((o) => !posts.contains(o)));
          fixedPosts.addAllPost(posts, widget.panelWidth - 10);
          isFinishedFetch = true;
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (fixedPosts.length == 0) {
      return Center(child: Text("Loading"));
    } else {
      return buildWidght();
    }
  }

  // Page content
  Container buildWidght() {
    _controller = ScrollController();
    var s = Container(
        child: Scrollbar(
      child: SingleChildScrollView(
        controller: _controller,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 40, 0, 0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[]..addAll(_buildPostPreview()),
            )),
      ),
    ));
    _controller.addListener(_scrollListener);
    return s;
  }

  _scrollListener() {
    // Reach the bottom
    if (_controller.offset >= _controller.position.maxScrollExtent - 800 &&
        !_controller.position.outOfRange) {
      print('Reach the bottom');

      if (isFinishedFetch && currentFetchType == FetchType.Posts) {
        isFinishedFetch = false;
        page++;
        _booruPosts.fetchPosts(page: page).then((value) {
          setState(() {
            posts.addAll(value.where((o) => !posts.contains(o)));
            fixedPosts.addAllPost(posts, widget.panelWidth - 10);
            isFinishedFetch = true;
          });
        });
      }
    }
    // //  Reach the top, maybe we wanna refresh the page
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
    isFinishedFetch = false;
    _booruPosts.fetchPosts().then((value) {
      setState(() {
        posts.addAll(value);
        fixedPosts.addAllPost(posts, widget.panelWidth - 15);
        isFinishedFetch = true;
      });
    });
  }
}
