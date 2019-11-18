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

  var type = ClientType.Yande;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: _appDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: AppBar(
            title: SearchBox(),
            iconTheme: IconThemeData(color: baseBlackColor),
            centerTitle: true,
            actions: <Widget>[
              Container(
                width: 64,
                child: FlatButton(
                  onPressed: () {},
                  child: Icon(Icons.person),
                  //padding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(32.0)),
                ),
              ),
              Center(
                child: DropdownButton(
                  items: [
                    DropdownMenuItem(
                      child: Text("Yande.re"),
                      value: ClientType.Yande,
                    ),
                    DropdownMenuItem(
                      child: Text("Konachan"),
                      value: ClientType.Konachan,
                    )
                  ],
                  onChanged: (item) {
                    var opt = item as ClientType;
                    switch (opt) {
                      case ClientType.Yande:
                        AppSettings.currentClient = ClientType.Yande;
                        setState(() {
                          type = ClientType.Yande;
                        });
                        break;
                      case ClientType.Konachan:
                        AppSettings.currentClient = ClientType.Konachan;
                        setState(() {
                          type = ClientType.Konachan;
                        });
                        break;
                      default:
                        break;
                    }
                  },
                  icon: Icon(Icons.settings),
                  value: type,
                ),
              ),
            ],
          ),
        ),
        body: _buildRow(context));
  }

  Widget _buildRow(BuildContext context) {
    if (posts.length == 0) {
      return Center(child: Text("Loading"));
    } else {
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
                    onPressed: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.whatshot),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Popular"),
                        )
                      ],
                    ),
                    //padding: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(43.0)),
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

      if (isFinishedFetch) {
        isFinishedFetch = false;
        _booruPosts.page++;
        _booruPosts.setType(FetchType.Home).fetchPosts().then((value) {
              setState(() {
                posts.addAll(value.where((o) => !posts.contains(o)));
                isFinishedFetch = true;
              });
            });
      }
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
    _booruPosts.setType(FetchType.Home).fetchPosts().then((value) {
      setState(() {
        posts.addAll(value);
      });
    });
  }
}
