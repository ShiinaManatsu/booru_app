import 'package:booru_app/main.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:booru_app/models/rx/post_state.dart';
import 'package:booru_app/pages/home_page.dart';
import 'package:masonry_grid/masonry_grid.dart';
import 'post_preview.dart';
import 'package:darq/darq.dart';

double masonryGridBorderRadius = 12;
double spacing = 4;

class SliverPostWaterfall extends StatefulWidget {
  final ScrollController controller;

  SliverPostWaterfall({this.controller, Key key}) : super(key: key);

  @override
  _SliverPostWaterfallState createState() => _SliverPostWaterfallState();
}

class _SliverPostWaterfallState extends State<SliverPostWaterfall> {
  ScrollController _controller;

  double get _spacing => 4;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: spacing),
        StreamBuilder<PostState>(
            stream: booruBloc.state.distinct((x, y) => x == y),
            initialData: PostEmpty(),
            builder: (context, snapshot) {
              if (snapshot.data is PostSuccess) {
                var state = snapshot.data as PostSuccess;
                return !AppSettings.masonryGrid
                    ? SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: <Widget>[]..addAll(state.result
                                  .distinct((x) => x.id)
                                  .map((x) => RepaintBoundary(
                                      child: PostPreview(post: x)))),
                            )),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: spacing + 4, vertical: spacing),
                        child: MasonryGrid(
                            staggered: false,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            column: size.width ~/
                                (size.aspectRatio > 1 ? 400 : 200),
                            children: state.result
                                .map((x) => RepaintBoundary(
                                    child: AspectRatio(
                                        aspectRatio: x.ratio,
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                              //  Remvoe this after we ensure we wont change this in setting page
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      masonryGridBorderRadius)),
                                          child: PostPreview(post: x),
                                        ))))
                                .toList()),
                      );
              } else if (snapshot.data is PostError) {
                var date = snapshot.data as PostError;
                print(date.error);
                return _buildText(date.error.toString());
              } else if (snapshot.data is PostLoading) {
                return _buildText("${language.content.loading}..");
              } else {
                return _buildText("${language.content.nothingToShow}..");
              }
            })
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
