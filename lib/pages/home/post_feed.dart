import 'dart:async';

import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/booru_bloc.dart';
import 'package:booru_app/models/rx/post_state.dart';
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/pages/home/post_tile.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:booru_app/utils/aura_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PostFeed extends StatefulWidget {
  const PostFeed({
    super.key,
    required this.title,
    required this.initialFetchType,
    required this.booruApi,
    this.period,
    this.tags,
    this.gridPadding,
  });

  final String title;
  final FetchType initialFetchType;
  final BooruAPI booruApi;
  final Period? period;
  final String? tags;
  final EdgeInsets? gridPadding;

  @override
  State<PostFeed> createState() => _PostFeedState();
}

class _PostFeedState extends State<PostFeed> {
  late final BooruBloc bloc;
  final ScrollController _controller = ScrollController();

  String? _auraUrlApplied;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    bloc = BooruBloc();
    _bootstrap();
  }

  void _bootstrap() {
    switch (widget.initialFetchType) {
      case FetchType.Posts:
        bloc.bootstrap(fetchType: FetchType.Posts, arg: PostsArgs(page: 1));
        break;
      case FetchType.PopularRecent:
        bloc.bootstrap(
          fetchType: FetchType.PopularRecent,
          arg: PopularRecentArgs(period: widget.period ?? Period.None),
        );
        break;
      case FetchType.PopularByDay:
        bloc.bootstrap(
          fetchType: FetchType.PopularByDay,
          arg: PopularByDayArgs(time: DateTime.now()),
        );
        break;
      case FetchType.PopularByWeek:
        bloc.bootstrap(
          fetchType: FetchType.PopularByWeek,
          arg: PopularByWeekArgs(time: DateTime.now()),
        );
        break;
      case FetchType.PopularByMonth:
        bloc.bootstrap(
          fetchType: FetchType.PopularByMonth,
          arg: PopularByMonthArgs(time: DateTime.now()),
        );
        break;
      case FetchType.Search:
        bloc.bootstrap(
          fetchType: FetchType.Search,
          arg: TaggedArgs(tags: widget.tags ?? '', page: 1),
        );
        break;
    }
  }

  @override
  void didUpdateWidget(covariant PostFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFetchType != oldWidget.initialFetchType) {
      _bootstrap();
      return;
    }
    if (widget.initialFetchType == FetchType.Search && widget.tags != oldWidget.tags) {
      bloc.setFetchType(
        FetchType.Search,
        arg: TaggedArgs(tags: widget.tags ?? '', page: 1),
      );
    }
    if (widget.initialFetchType == FetchType.PopularRecent && widget.period != oldWidget.period) {
      bloc.setFetchType(
        FetchType.PopularRecent,
        arg: PopularRecentArgs(period: widget.period ?? Period.None),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    bloc.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await bloc.refresh();
  }

  bool get _canLoadMore =>
      widget.initialFetchType == FetchType.Posts ||
      widget.initialFetchType == FetchType.Search ||
      widget.initialFetchType == FetchType.PopularByDay ||
      widget.initialFetchType == FetchType.PopularByWeek ||
      widget.initialFetchType == FetchType.PopularByMonth;

  Future<void> _maybeLoadMoreByMetrics(ScrollMetrics metrics) async {
    if (!_canLoadMore) return;
    if (_loadingMore) return;
    // `extentAfter` is more reliable across different sliver layouts.
    if (metrics.extentAfter > 800) return;
    setState(() => _loadingMore = true);
    try {
      await bloc.loadMore();
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      } else {
        _loadingMore = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: StreamBuilder<PostState>(
        stream: bloc.stream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state is PostLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PostError) {
            return Center(child: Text('Error: ${state.error}'));
          }
          final posts = state is PostSuccess ? state.result : <Post>[];

          if (state is PostSuccess && posts.isNotEmpty) {
            final url = AppSettings.previewQuality == PreviewQuality.Medium ? (posts.first.sampleUrl ?? posts.first.previewUrl) : posts.first.previewUrl;
            if (url.isNotEmpty && url != _auraUrlApplied) {
              _auraUrlApplied = url;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                AuraController.instance.setNetworkUrl(url);
              });
            }
          }

          if (posts.isEmpty) {
            return Center(child: Text(language.content.nothingToShow));
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollUpdateNotification || n is OverscrollNotification) {
                unawaited(_maybeLoadMoreByMetrics(n.metrics));
              }
              return false;
            },
            child: CustomScrollView(
              controller: _controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: widget.gridPadding ?? const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: _columnsForWidth(MediaQuery.of(context).size.width),
                    mainAxisSpacing: AppSettings.masonryGridSpacing,
                    crossAxisSpacing: AppSettings.masonryGridSpacing,
                    childCount: posts.length,
                    itemBuilder: (context, index) => PostTile(post: posts[index]),
                  ),
                ),
                if (_canLoadMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 110),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _loadingMore
                              ? const SizedBox(
                                  key: ValueKey('loading_more'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const SizedBox(key: ValueKey('loading_more_idle'), height: 18),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _columnsForWidth(double width) {
    final target = width ~/ 280;
    return target.clamp(2, 6);
  }
}
