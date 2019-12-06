import 'package:flutter/material.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/pages/home_page.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'post_preview.dart';

class SliverPostWaterfall extends StatefulWidget {
  // The width this widght will take
  @required
  final double panelWidth;
  final ScrollController controller;

  SliverPostWaterfall({this.panelWidth, this.controller, Key key})
      : super(key: key);

  @override
  _SliverPostWaterfallState createState() => _SliverPostWaterfallState();
}

class _SliverPostWaterfallState extends State<SliverPostWaterfall> {
  ScrollController _controller;
  bool isFinishedFetch = true;
  List<Post> posts = List<Post>();
  List<List<Post>> fixedPosts = List<List<Post>>();
  FetchType currentFetchType = FetchType.Posts;
  DateTime _dateTime = DateTime.now();
  int page = 1;

  _SliverPostWaterfallState() {
    //updadePost = _updateCall;
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_scrollListener);
  }

  _setDateTime(DateTime dateTime) {
    _dateTime = dateTime;
    // TODO: Update by time
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        StreamBuilder<List<Post>>(
          stream: booruBloc.posts,
          initialData: new List<Post>(),
          builder: (context, snapshot) {
            if (snapshot.data.length == 0) {
              return Center(child: Text("Loading"));
            } else {
              return Container(
                child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 40, 0, 0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[]
                          ..addAll(snapshot.data.map((x) => PostPreview(
                                post: x,
                              ))),
                      )),
                ),
              );
            }
          },
        )
      ]),
    );
  }

  Widget _datePicker() {
    if (currentFetchType == FetchType.PopularByWeek ||
        currentFetchType == FetchType.PopularByMonth) {
      return Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            FlatButton(
              child: Icon(Icons.arrow_back),
              onPressed: () {},
            ),
            FlatButton(
              child:
                  Text("${_dateTime.month} ${_dateTime.day} ${_dateTime.year}"),
              onPressed: () {
                showDatePicker(
                        firstDate: AppSettings.currentClient == ClientType.Yande
                            ? AppSettings.yandeFirstday
                            : AppSettings.konachanFirstday,
                        lastDate: DateTime(DateTime.now().year,
                            DateTime.now().month, DateTime.now().day + 1),
                        context: context,
                        initialDate: DateTime.now())
                    .then((x) {
                  if (x != null) _setDateTime(x);
                });
              },
            ),
            FlatButton(
              child: Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  _scrollListener() {
    // Reach the bottom
    if (_controller.offset >= _controller.position.maxScrollExtent - 800 &&
        !_controller.position.outOfRange) {
      print('Reach the bottom');

      if (isFinishedFetch && currentFetchType == FetchType.Posts) {
        // TODO: Fetch when scrool
      }
    }
    // //  Reach the top
    // if (_controller.offset <= _controller.position.minScrollExtent &&
    //     !_controller.position.outOfRange) {
    // }
  }

  _buildPostPreview(List<Post> posts) {
    var list = new List<PostPreview>();
    posts.forEach((f) {
      list.add(PostPreview(
        post: f,
      ));
    });
    return list;
  }
}
