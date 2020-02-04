import 'dart:ui';
import 'package:booru_app/pages/widgets/login_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart';
import 'package:booru_app/main.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/booru_bloc.dart';
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/pages/widgets/sliver_floating_bar.dart';
import 'package:booru_app/pages/widgets/sliver_post_waterfall_widget.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/models/rx/task_bloc.dart';

BooruBloc booruBloc;
TaskBloc taskBloc;
String searchTerm = "";
double panelWidth = 1000;
PublishSubject<FetchType> homePageFetchTypeChanged =
    PublishSubject<FetchType>();
RefreshController refreshController = RefreshController(initialRefresh: false);

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  /// Private properties
  FetchType _type = FetchType.Posts; // Current browser type
  static const Key _searchPage = Key("searchPage");
  var _onPageChange = PublishSubject<PageNavigationType>();
  double _drawerButtonHeight = 48; // Drawer button height
  Period _period = Period.None;
  Widget _searchNabor = Text(searchTerm);

  @override
  void initState() {
    super.initState();
    booruBloc = BooruBloc(BooruAPI(), panelWidth);
    taskBloc = TaskBloc();

    Rx.timer(() {}, Duration(milliseconds: 50)).listen((x) {
      booruBloc.onUpdate
          .add(UpdateArg(fetchType: FetchType.Posts, arg: PostsArgs(page: 1)));
    });
    _onPageChange.listen((x) {
      booruBloc.onPage.add(x);
    });
    homePageFetchTypeChanged.listen((x) {
      setState(() {
        if (_type != x) {
          _type = x;
        }
        if (_type == FetchType.PopularRecent) {
          _searchNabor = Text("Recent Popular");
        } else if (_type == FetchType.Search) {
          _searchNabor = Text(searchTerm);
        } else if (_type == FetchType.PopularByWeek) {
          _searchNabor = Text("PopularByWeek");
        } else {
          _searchNabor = Container();
        }
        if (x != FetchType.Search) {
          searchTerm = "";
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    panelWidth = MediaQuery.of(context).size.width - 20;
    booruBloc.onPanelWidth.add(panelWidth);
    print("panelWidth build");
    var _controller = new ScrollController();
    return Scaffold(
        bottomNavigationBar:
            _type == FetchType.PopularRecent ? _buildPeroidChip() : null,
        drawer: _appDrawer(),
        drawerEdgeDragWidth: 100,
        body: Builder(
          builder: (context) => SmartRefresher(
            header: WaterDropMaterialHeader(
              backgroundColor: Colors.accents[1],
            ),
            onRefresh: () => booruBloc.onRefresh.add(null),
            //onLoading: () => _onPageChange.add(PageNavigationType.Next),
            enablePullDown: true,
            //enablePullUp: true,
            controller: refreshController,
            child: CustomScrollView(
              primary: false,
              controller: _controller,
              physics: BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverFloatingBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.white.withOpacity(0.95),
                  floating: true,
                  title: Container(
                    margin: EdgeInsets.only(bottom: 5), // Fix the displacement
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            IconButton(
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              icon: Icon(Icons.menu),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
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
                                    iconSize: 0,
                                    onChanged: onDropdownChanged,
                                    value: AppSettings.currentClient,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        AnimatedSize(
                          duration: Duration(milliseconds: 500),
                          vsync: this,
                          curve: Curves.ease,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              IconButton(
                                onPressed: () => {
                                  Navigator.pushNamed(
                                      context, searchTaggedPostsPage,
                                      arguments: {"key": _searchPage})
                                },
                                icon: Icon(Icons.search),
                              ),
                              // AnimatedSize(
                              //   duration: Duration(milliseconds: 500),
                              //   vsync: this,
                              //   curve: Curves.ease,
                              //   child: AnimatedSwitcher(
                              //     duration: const Duration(milliseconds: 500),
                              //     child: AnimatedSize(
                              //         duration: Duration(milliseconds: 500),
                              //         vsync: this,
                              //         curve: Curves.ease,
                              //         child: _searchNabor),
                              //   ),
                              // ),
                              _searchNabor
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SliverPostWaterfall(
                  controller: _controller,
                  panelWidth: panelWidth,
                ),
                _buildPageNavigator(),
                _buildDatePicker()
              ],
            ),
          ),
        ));
  }

  void onDropdownChanged(item) {
    var opt = item as ClientType;
    switch (opt) {
      case ClientType.Yande:
        booruBloc.onRefresh.add(null);
        setState(() {
          AppSettings.currentClient = ClientType.Yande;
        });
        break;
      case ClientType.Konachan:
        booruBloc.onRefresh.add(null);
        setState(() {
          AppSettings.currentClient = ClientType.Konachan;
        });
        break;
      default:
        break;
    }
  }

  void _buttonLogin() {
    showDialog(
      context: context,
      builder: (context) => LoginBox(() {
        if (mounted) {
          setState(() {});
        }
      }),
    );
  }

  Widget _user() {
    if (AppSettings.localUsers.length > 0) {
      switch (AppSettings.currentClient) {
        case ClientType.Yande:
          var u = AppSettings.localUsers
              .firstWhere((x) => x.clientType == ClientType.Yande);
          return Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 0, 15),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: NetworkImage(u.avatarUrl),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child:
                      Text(u.username, style: TextStyle(color: Colors.black87)),
                )
              ],
            ),
          );
          break;
        case ClientType.Konachan:
          var u = AppSettings.localUsers
              .firstWhere((x) => x.clientType == ClientType.Konachan);
          return Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 0, 15),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: NetworkImage(u.avatarUrl),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child:
                      Text(u.username, style: TextStyle(color: Colors.black87)),
                )
              ],
            ),
          );
          break;
        default:
          return Container();
          break;
      }
    } else {
      // Login
      return _buildDrawerEmptyButton(_buttonLogin, "Login");
    }
  }

  /// The app drawer
  Widget _appDrawer() {
    return SafeArea(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: Colors.white.withOpacity(0.8),
          width: 300,
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.max,
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
                _user(),
                // Spliter
                _spliter("Posts"),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _buildDrawerButton(() {
                      Navigator.pop(context);
                      booruBloc.onReset.add(null);
                      booruBloc.onUpdate.add(UpdateArg(
                          fetchType: FetchType.Posts, arg: PostsArgs(page: 1)));
                    }, "Posts", FetchType.Posts),

                    _buildDrawerButton(
                        () => Navigator.pushNamed(
                            context, searchTaggedPostsPage,
                            arguments: {"key": _searchPage}),
                        "Search",
                        FetchType.Search),

                    // Spliter popular
                    _spliter("Popular Posts"),

                    _buildDrawerButton(() {
                      Navigator.pop(context);
                      booruBloc.onUpdate.add(UpdateArg(
                          fetchType: FetchType.PopularRecent,
                          arg: PopularRecentArgs(period: _period)));
                    }, "Popular posts by recent", FetchType.PopularRecent),

                    _buildDrawerButton(() {
                      Navigator.pop(context);
                      booruBloc.onUpdate.add(UpdateArg(
                          fetchType: FetchType.PopularByDay,
                          arg: PopularByDayArgs(time: DateTime.now())));
                    }, "Popular posts by day", FetchType.PopularByDay),

                    _buildDrawerButton(() {
                      Navigator.pop(context);
                      booruBloc.onUpdate.add(UpdateArg(
                          fetchType: FetchType.PopularByWeek,
                          arg: PopularByWeekArgs(time: DateTime.now())));
                    }, "Popular posts by week", FetchType.PopularByWeek),

                    _buildDrawerButton(() {
                      Navigator.pop(context);
                      booruBloc.onUpdate.add(UpdateArg(
                          fetchType: FetchType.PopularByMonth,
                          arg: PopularByMonthArgs(time: DateTime.now())));
                    }, "Popular posts by month", FetchType.PopularByMonth),

                    _spliter("Others"),
                    _buildDrawerEmptyButton(
                        () => Navigator.pushNamed(context, settingsPage),
                        "Settings"),
                    _buildDrawerEmptyButton(
                        () => Navigator.pushNamed(context, settingsPage),
                        "About"),
                    _buildDrawerEmptyButton(
                        () => Navigator.pushNamed(context, testGroundPage),
                        "Test Ground"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The button used in drawer
  Widget _buildDrawerButton(
      Function() onPressed, String text, FetchType fetchType) {
    var func = () {
      onPressed();
      homePageFetchTypeChanged.add(fetchType);
    };
    return Container(
      //margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
      height: _drawerButtonHeight,
      child: FlatButton(
        onPressed: func,
        color: fetchType == _type ? Colors.pink[300] : Colors.transparent,
        highlightColor: Colors.amber,
        hoverColor: Colors.pink[50],
        colorBrightness:
            fetchType != _type ? Brightness.light : Brightness.dark,
        child: Container(alignment: Alignment.centerLeft, child: Text(text)),
      ),
    );
  }

  /// The button used in drawer
  Widget _buildDrawerEmptyButton(Function() onPressed, String text) {
    return Container(
      //margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
      height: _drawerButtonHeight,
      child: FlatButton(
        onPressed: onPressed,
        highlightColor: Colors.amber,
        hoverColor: Colors.pink[50],
        child: Container(alignment: Alignment.centerLeft, child: Text(text)),
      ),
    );
  }

  int _currentIndex = 0;
  TextStyle _unSelected = TextStyle(color: Colors.black54);
  TextStyle _selectedTextStyle = TextStyle(color: Colors.white);

  /// Peroid picker
  Widget _buildPeroidChip() {
    return SnakeNavigationBar(
      snakeShape: SnakeShape.rectangle,
      selectedIconColor: Colors.white,
      snakeColor: Colors.black,
      backgroundColor: Colors.transparent,
      items: [
        BottomNavigationBarItem(
          icon: Text(
            "Last 24h",
            style: _currentIndex == 0 ? _selectedTextStyle : _unSelected,
          ),
        ),
        BottomNavigationBarItem(
          icon: Text(
            "Week",
            style: _currentIndex == 1 ? _selectedTextStyle : _unSelected,
          ),
        ),
        BottomNavigationBarItem(
          icon: Text(
            "Month",
            style: _currentIndex == 2 ? _selectedTextStyle : _unSelected,
          ),
        ),
        BottomNavigationBarItem(
          icon: Text(
            "Year",
            style: _currentIndex == 3 ? _selectedTextStyle : _unSelected,
          ),
        ),
      ],
      currentIndex: _currentIndex,
      onPositionChanged: (value) {
        setState(() {
          _currentIndex = value;
          _period = Period.values[value];
        });
        booruBloc.onUpdate.add(UpdateArg(
            fetchType: FetchType.PopularRecent,
            arg: PopularRecentArgs(period: _period)));
      },
    );
  }

  /// Page navigator in the bottom
  Widget _buildPageNavigator() {
    return StreamBuilder<int>(
        stream: booruBloc.pageState,
        initialData: 1,
        builder: (context, snapshot) {
          if (_type == FetchType.Posts || _type == FetchType.Search) {
            return _bottomNavigator(
                data: snapshot.data.toString(),
                leftButtonFunction: () =>
                    _onPageChange.add(PageNavigationType.Previous),
                rightButtonFunction: () =>
                    _onPageChange.add(PageNavigationType.Next),
                middleTextFunction: (x) => print(x.buttons));
          } else {
            return SliverList(delegate: SliverChildListDelegate([]));
          }
        });
  }

  /// Date pikcer in the bottom
  Widget _buildDatePicker() {
    return StreamBuilder<DateTime>(
      stream: booruBloc.postDate,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        DateTime time = snapshot.data;
        if (_type == FetchType.PopularByDay) {
          return _bottomNavigator(
              data: "${time.year}-${time.month}-${time.day}",
              leftButtonFunction: () {
                booruBloc.onDateTime.add((x) => x.subtract(Duration(days: 1)));
              },
              rightButtonFunction: () {
                booruBloc.onDateTime.add((x) => x.add(Duration(days: 1)));
              },
              middleTextFunction: (X) {
                // open date picker
              });
        } else if (_type == FetchType.PopularByWeek) {
          return _bottomNavigator(
              data: "${time.year}-${time.month}-${time.day}",
              leftButtonFunction: () {
                booruBloc.onDateTime.add((x) => x.subtract(Duration(days: 7)));
              },
              rightButtonFunction: () {
                booruBloc.onDateTime.add((x) => x.add(Duration(days: 7)));
              },
              middleTextFunction: (X) {
                // open date picker
              });
        } else if (_type == FetchType.PopularByMonth) {
          return _bottomNavigator(
              data: "${time.year}-${time.month}",
              leftButtonFunction: () {
                booruBloc.onDateTime.add((x) => x.subtract(Duration(days: 31)));
              },
              rightButtonFunction: () {
                booruBloc.onDateTime.add((x) => x.add(Duration(days: 31)));
              },
              middleTextFunction: (X) {
                // open date picker
              });
        } else {
          return SliverList(delegate: SliverChildListDelegate([]));
        }
      },
    );
  }

  // Page navigation in the bottom
  Widget _bottomNavigator(
      {String data,
      Function leftButtonFunction,
      Function rightButtonFunction,
      Function(PointerUpEvent) middleTextFunction}) {
    return SliverList(
        delegate: SliverChildListDelegate([
      Container(
        height: 50,
        margin: EdgeInsets.only(top: 10),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _quadButton(
                function: leftButtonFunction, child: Icon(Icons.chevron_left)),
            Listener(
              onPointerUp: middleTextFunction,
              child: Container(
                  margin: EdgeInsets.fromLTRB(15, 0, 10, 0), child: Text(data)),
            ),
            _quadButton(
                function: rightButtonFunction,
                child: Icon(Icons.chevron_right)),
          ],
        ),
      )
    ]));
  }

  /// Build the square button
  AspectRatio _quadButton(
      {@required Function() function, @required Widget child}) {
    return AspectRatio(
      aspectRatio: 1,
      child: FlatButton(
        onPressed: function,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: child,
      ),
    );
  }

  /// Spliter with text
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
  bool get wantKeepAlive => false;

  @override
  void dispose() {
    super.dispose();
  }
}
