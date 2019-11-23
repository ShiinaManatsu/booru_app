import 'package:flutter/material.dart';
import 'package:yande_web/controllors/search_box.dart';
import 'package:yande_web/pages/widgets/post_waterfall_widget.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:yande_web/themes/theme_light.dart';
import 'package:yande_web/models/booru_posts.dart';
import '../main.dart';

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

  bool fetchCommonPosts = true;

  var type = ClientType.Yande;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    panelWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        drawer: _appDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: AppBar(
            title: SearchBox(
              key: _homePageBar,
            ),
            iconTheme: IconThemeData(color: baseBlackColor),
            centerTitle: true,
            actions: <Widget>[
              Container(
                width: 64,
                child: FlatButton(
                  onPressed: () {
                    Navigator.pushNamed(context, searchTaggedPostsPage);
                  },
                  child: Icon(Icons.person),
                  //padding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(32.0)),
                ),
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
              ),
            ],
          ),
        ),
        body: _buildRow(context));
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
  }

  Widget _buildRow(BuildContext context) {
    var _postWaterfall = PostWaterfall(
      panelWidth: panelWidth,
      key: _homeWaterfall,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _postWaterfall,
        )
      ],
    );
  }

  FetchType _type = FetchType.Posts;
  double _drawerButtonHeight = 60;
  Key _drawer = Key("drawer");

  Drawer _appDrawer() {
    return Drawer(
      key: _drawer,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // Title
            Container(
                margin: EdgeInsets.fromLTRB(15, 20, 0, 20),
                alignment: Alignment.centerLeft,
                child: Text(AppSettings.currentClient.toString())),
            // Spliter
            _spliter("Posts"),
            // TODO: Add buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _buildDrawerButton(() {
                  Navigator.pop(context);
                  updadePost(FetchType.Posts);
                }, "Posts", FetchType.Posts),
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
      margin: EdgeInsets.fromLTRB(0, 10, 20, 10),
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
          Text(text),
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
