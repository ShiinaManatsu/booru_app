import 'package:flutter/material.dart';
import 'package:booru_app/models/rx/post_state.dart';
import 'package:booru_app/pages/home_page.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        StreamBuilder<PostState>(
          stream: booruBloc.state,
          initialData: PostEmpty(),
          builder: (context, snapshot) {
            if (snapshot.data is PostSuccess) {
              var state = snapshot.data as PostSuccess;
              return Container(
                child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: <Widget>[]
                          ..addAll(state.result.map((x) => PostPreview(
                                post: x,
                              ))),
                      )),
                ),
              );
            } else if (snapshot.data is PostError) {
              var date = snapshot.data as PostError;
              print(date.error);
              return _buildText(date.error.toString());
            } else {
              return _buildText("Loading..");
            }
          },
        )
      ]),
    );
  }

  Widget _buildText(String text) {
    return Container(
      height: 200,
      alignment: Alignment.bottomCenter,
      child: Text(text),
    );
  }

  _scrollListener() {
    // Reach the bottom
    // if (_controller.offset >= _controller.position.maxScrollExtent - 800 &&
    //     !_controller.position.outOfRange) {
    //   print('Reach the bottom');

    //   if (isFinishedFetch && currentFetchType == FetchType.Posts) {
    //   }
    // }
    // //  Reach the top
    // if (_controller.offset <= _controller.position.minScrollExtent &&
    //     !_controller.position.outOfRange) {
    // }
  }
}
