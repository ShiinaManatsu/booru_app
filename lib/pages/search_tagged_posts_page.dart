import 'package:flutter/material.dart';
import 'package:yande_web/controllors/search_box.dart';
import 'package:yande_web/main.dart';
import 'package:yande_web/pages/post_waterfall_widget.dart';
import 'package:yande_web/themes/theme_light.dart';

class SearchTaggedPostsPage extends StatefulWidget {
  @override
  _SearchTaggedPostsPageState createState() => _SearchTaggedPostsPageState();
}

class _SearchTaggedPostsPageState extends State<SearchTaggedPostsPage> {
  Key _searchPageBar = Key("searchPageBar");
  Key _searchWaterfall = Key("searchPage");
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 64,
            title: SearchBox(
              key: _searchPageBar,
            ),
            centerTitle: true,
            iconTheme: IconThemeData(color: baseBlackColor),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // PostWaterfall(
              //   key: _searchWaterfall,
              //   panelWidth: width,
              // )
            ]),
          )
        ],
      ),
    );
  }
}
