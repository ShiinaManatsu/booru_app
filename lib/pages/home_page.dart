import 'package:floating_search_bar/ui/sliver_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:yande_web/main.dart';
import 'package:yande_web/pages/widgets/sliver_post_waterfall_widget.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:yande_web/models/booru_posts.dart';

Function(FetchType, {String term}) updadePost;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  double panelWidth = 1000;
  double leftPanelWidth = 86;
  Key _homeWaterfall = Key("_homeWaterfall");
  Key _homePageBar = Key("homePageBar");
  Key _searchPage = Key("searchPage");

  bool fetchCommonPosts = true;

  var type = ClientType.Yande;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    panelWidth = MediaQuery.of(context).size.width;
    var _controller = new ScrollController();
    return Scaffold(
        drawer: _appDrawer(),
        body: Builder(
          builder: (context) => CustomScrollView(
            primary: false,
            controller: _controller,
            physics: BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverFloatingBar(
                automaticallyImplyLeading: false,
                //snap: false,
                pinned: true,
                backgroundColor: Color.fromARGB(240, 255, 255, 255),
                //floating: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu),
                    ),
                    IconButton(
                      onPressed: () => {
                        Navigator.pushNamed(context, searchTaggedPostsPage,
                            arguments: {"key": _searchPage})
                      },
                      icon: Icon(Icons.search),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.person),
                        ),
                        Center(
                          child: DropdownButton(
                            underline: Container(),
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
                            onChanged: onDropdownChanged,
                            icon: Icon(Icons.settings),
                            value: type,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              SliverPostWaterfall(
                controller: _controller,
                panelWidth: panelWidth,
              )
            ],
          ),
        ));
  }

  void onDropdownChanged(item) {
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
    // TODO: This need a indicator
    //updadePost(FetchType.PopularRecent);
  }

  FetchType _type = FetchType.Posts;
  double _drawerButtonHeight = 60;
  Key _drawer = Key("drawer");

  Drawer _appDrawer() {
    return Drawer(
      key: _drawer,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // Title
              Container(
                  margin: EdgeInsets.fromLTRB(15, 20, 0, 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppSettings.currentClient == ClientType.Yande
                        ? "Yande.re"
                        : "Konachan",
                    style: TextStyle(fontSize: 30),
                  )),
              // Spliter
              _spliter("Posts"),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    updadePost(FetchType.Posts);
                  }, "Posts", FetchType.Posts),
                  _buildDrawerButton(
                      () => Navigator.pushNamed(context, searchTaggedPostsPage,
                          arguments: {"key": _searchPage}),
                      "Search",
                      FetchType.Search),
                  // Spliter popular
                  _spliter("Popular Posts"),
                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    updadePost(FetchType.PopularRecent);
                  }, "Popular posts by recent", FetchType.PopularRecent),
                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    updadePost(FetchType.PopularByWeek);
                  }, "Popular posts by week", FetchType.PopularByWeek),
                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    updadePost(FetchType.PopularByMonth);
                  }, "Popular posts by month", FetchType.PopularByMonth),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerButton(
      Function() onPressed, String text, FetchType fetchType) {
    var func = () {
      onPressed();
      setState(() {
        _type = fetchType;
      });
    };
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
      height: _drawerButtonHeight,
      child: FlatButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30),
                topRight: Radius.circular(30))),
        highlightColor: Colors.lightBlue[300],
        color: fetchType == _type ? Colors.lightBlue[50] : Colors.transparent,
        hoverColor: Colors.lightBlue[100],
        splashColor: Colors.lightBlue[200],
        onPressed: func,
        child: Container(alignment: Alignment.centerLeft, child: Text(text)),
      ),
    );
  }

  Container _spliter(String text) {
    return Container(
      margin: EdgeInsets.fromLTRB(15, 5, 20, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Text(
            text,
            style: TextStyle(fontSize: 20),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Container(
              height: 0.5,
              margin: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;
}
