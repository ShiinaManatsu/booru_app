import 'package:floating_search_bar/ui/sliver_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yande_web/main.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/booru_bloc.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/pages/widgets/sliver_post_waterfall_widget.dart';
import 'package:yande_web/settings/app_settings.dart';

BooruBloc booruBloc;
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
  Key _drawer = Key("drawer");
  Period _period = Period.None;
  Widget _searchNabor = Text(searchTerm);

  @override
  void initState() {
    super.initState();
    booruBloc = BooruBloc(BooruAPI(), panelWidth);
    Observable.timer(() {}, Duration(milliseconds: 50)).listen((x) {
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
          _searchNabor = _buildPeroidChip();
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
        drawer: _appDrawer(),
        body: Builder(
          builder: (context) => SmartRefresher(
            header: WaterDropMaterialHeader(
              backgroundColor: Colors.accents[1],
            ),
            onRefresh: () => booruBloc.onRefresh.add(null),
            enablePullDown: true,
            controller: refreshController,
            child: CustomScrollView(
              primary: false,
              controller: _controller,
              physics: BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: EdgeInsets.only(top: 10),
                ),
                SliverFloatingBar(
                  automaticallyImplyLeading: false,
                  //snap: false,
                  //pinned: true,
                  backgroundColor: Color.fromARGB(240, 255, 255, 255),
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
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                onPressed: () => {
                                  Navigator.pushNamed(
                                      context, searchTaggedPostsPage,
                                      arguments: {"key": _searchPage})
                                },
                                icon: Icon(Icons.search),
                              ),
                              AnimatedSize(
                                duration: Duration(milliseconds: 500),
                                vsync: this,
                                curve: Curves.ease,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: AnimatedSize(
                                      duration: Duration(milliseconds: 500),
                                      vsync: this,
                                      curve: Curves.ease,
                                      child: _searchNabor),
                                ),
                              ),
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

  /// The app drawer
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
                    booruBloc.onReset.add(null);
                    booruBloc.onUpdate.add(UpdateArg(
                        fetchType: FetchType.Posts, arg: PostsArgs(page: 1)));
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
                ],
              ),
            ],
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

  /// Peroid picker
  Widget _buildPeroidChip() {
    return Row(
      children: <Widget>[
        ChoiceChip(
          label: Text("Last 24h"),
          selected: _period == Period.None,
          onSelected: (x) {
            setState(() {
              _period = Period.None;
            });
            booruBloc.onUpdate.add(UpdateArg(
                fetchType: FetchType.PopularRecent,
                arg: PopularRecentArgs(period: _period)));
          },
        ),
        ChoiceChip(
          label: Text("Week"),
          selected: _period == Period.Week,
          onSelected: (x) {
            setState(() {
              _period = Period.Week;
            });
            booruBloc.onUpdate.add(UpdateArg(
                fetchType: FetchType.PopularRecent,
                arg: PopularRecentArgs(period: _period)));
          },
        ),
        ChoiceChip(
          label: Text("Month"),
          selected: _period == Period.Month,
          onSelected: (x) {
            setState(() {
              _period = Period.Month;
            });
            booruBloc.onUpdate.add(UpdateArg(
                fetchType: FetchType.PopularRecent,
                arg: PopularRecentArgs(period: _period)));
          },
        ),
        ChoiceChip(
          label: Text("Year"),
          selected: _period == Period.Year,
          onSelected: (x) {
            setState(() {
              _period = Period.Year;
            });
            booruBloc.onUpdate.add(UpdateArg(
                fetchType: FetchType.PopularRecent,
                arg: PopularRecentArgs(period: _period)));
          },
        ),
      ],
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
