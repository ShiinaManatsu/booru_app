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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(AppSettings.currentClient.toString()),
              ],
            ),
            // Spliter
            Container(
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 5),
              padding: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.black45,
              ),
            ),
            // TODO: Add buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  height: 60,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    highlightColor: Colors.lightBlue[300],
                    color: Colors.lightBlue[50],
                    hoverColor: Colors.lightBlue[100],
                    splashColor: Colors.lightBlue[200],
                    onPressed: () {
                      Navigator.pop(context);
                      updadePost(FetchType.Posts);
                    },
                    child: Container(
                        alignment: Alignment.centerLeft, child: Text("Posts")),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  height: 60,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    highlightColor: Colors.lightBlue[300],
                    color: Colors.lightBlue[50],
                    hoverColor: Colors.lightBlue[100],
                    splashColor: Colors.lightBlue[200],
                    onPressed: () {
                      Navigator.pop(context);
                      updadePost(FetchType.PopularRecent);
                    },
                    child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text("Popular posts by recent")),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  height: 60,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    highlightColor: Colors.lightBlue[300],
                    color: Colors.lightBlue[50],
                    hoverColor: Colors.lightBlue[100],
                    splashColor: Colors.lightBlue[200],
                    onPressed: () {
                      Navigator.pop(context);
                      updadePost(FetchType.PopularByWeek);
                    },
                    child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text("Popular posts by week")),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  height: 60,
                  child: FlatButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    highlightColor: Colors.lightBlue[300],
                    color: Colors.lightBlue[50],
                    hoverColor: Colors.lightBlue[100],
                    splashColor: Colors.lightBlue[200],
                    onPressed: () {
                      Navigator.pop(context);
                      updadePost(FetchType.PopularByMonth);
                    },
                    child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text("Popular posts by month")),
                  ),
                ),
              ],
            ),
          ],
        ),
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
