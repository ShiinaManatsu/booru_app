import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:yande_web/controllors/search_box.dart';
import 'package:yande_web/models/booru_posts.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/pages/post_preview.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:yande_web/themes/theme_light.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Post> posts = List<Post>();
  BooruPosts _booruPosts;
  ScrollController _controller;
  bool isFinishedFetch = true;

  _HomePageState() {
    _booruPosts = new BooruPosts();
  }

  @override
  Widget build(BuildContext context) {
    if (posts.length == 0) {
      return Scaffold(
        drawer: _appDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: AppBar(
            title: SearchBox(),
            iconTheme: IconThemeData(color: baseBlackColor),
            centerTitle: true,
          ),
        ),
        body: Center(child: Text("Loading")),
      );
    } else {
      return Scaffold(
        drawer: _appDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: AppBar(
            title: SearchBox(),
            iconTheme: IconThemeData(color: baseBlackColor),
            centerTitle: true,
          ),
        ),
        body: _buildRow(context),
      );
    }
  }

  Row _buildRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Left panel
        Container(
          width: 86,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 20,
              ),
              Container(
                width: 86,
                height: 86,
                child: FlatButton(
                  onPressed: (){},
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.search),
                      Text("Search")
                    ],
                  ),
                  
                  //padding: EdgeInsets.all(10),
                  shape:RoundedRectangleBorder(borderRadius: new BorderRadius.circular(43.0)),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: buildWidght(),
        )
      ],
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
              children: <Widget>[]..addAll(posts
                  .asMap()
                  .map((index, data) {
                    return MapEntry(index, PostPreview(post: data));
                  })
                  .values
                  .toList()),
            ),
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
    }
    // // Reach the top
    // if (_controller.offset <= _controller.position.minScrollExtent &&
    //     !_controller.position.outOfRange) {
    //     }
  }

  Drawer _appDrawer() {
    return Drawer(
      child: Text("Drawer"),
    );
  }

  @override
  void initState() {
    super.initState();
    _booruPosts.setType(FetchType.Weekly).fetchPosts().then((value) {
      setState(() {
        posts.addAll(value);
      });
    });
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.index, this.post);

  final Post post;
  final int index;

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new Column(
        children: <Widget>[
          new Stack(
            children: <Widget>[
              //new Center(child: new CircularProgressIndicator()),
              new Center(
                child: new FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: post.preview_url,
                ),
              ),
            ],
          ),
          new Padding(
            padding: const EdgeInsets.all(4.0),
            child: new Column(
              children: <Widget>[
                new Text(
                  'Image number $index',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                new Text(
                  'Width: ${post.preview_width}',
                  style: const TextStyle(color: Colors.grey),
                ),
                new Text(
                  'Height: ${post.preview_height}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

final Uint8List kTransparentImage = new Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
]);
