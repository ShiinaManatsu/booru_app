import 'package:flutter/material.dart';
import 'package:yande_web/controllors/search_box.dart';
import 'package:yande_web/pages/widgets/sliver_post_waterfall_widget.dart';
import 'package:yande_web/themes/theme_light.dart';

class SearchTaggedPostsPage extends StatefulWidget {
  @override
  _SearchTaggedPostsPageState createState() => _SearchTaggedPostsPageState();
}

class _SearchTaggedPostsPageState extends State<SearchTaggedPostsPage> {
  Key _searchPageBar = Key("searchPageBar");
  Key _searchWaterfall = Key("searchPage");
  ScrollController _controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _controller = new ScrollController();
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        controller: _controller,
        slivers: <Widget>[
          SliverAppBar(
            floating: true,
            expandedHeight: 64,
            title: SearchBox(
              key: _searchPageBar,
            ),
            centerTitle: true,
            iconTheme: IconThemeData(color: baseBlackColor),
          ),
          SliverPostWaterfall(
            panelWidth: width,
            controller: _controller,
            key: _searchWaterfall,
          )
        ],
      ),
    );
  }
}
