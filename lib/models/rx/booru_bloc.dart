import 'package:booru_app/settings/app_settings.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/post_state.dart';
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/extensions/list_extension.dart';
import 'package:booru_app/pages/home_page.dart';

class BooruBloc {
  // Subjects
  /// Call to update posts type
  final PublishSubject<UpdateArg> onUpdate;

  /// Call to refresh current posts
  final PublishSubject onRefresh;

  /// Call to reset page
  final PublishSubject onReset;

  /// Call to update page
  final PublishSubject<PageNavigationType> onPage;

  /// Call when panel width changed
  final PublishSubject<double> onPanelWidth;

  /// Call to change post datetime
  final PublishSubject<DateTime Function(DateTime)> onDateTime;

  // Streams
  /// Stream of posts state
  final Stream<PostState> state;

  /// Stream of the post page state
  // final Stream<int> pageState;

  /// Stream of the date picker
  final Stream<DateTime> postDate;

  // Static members
  static DateTime postDateTime = DateTime.now();
  static int page = 1;
  static List<Post> cache = List<Post>();
  static List<List<Post>> evaluated = List<List<Post>>();

  factory BooruBloc(BooruAPI booru, double panelWidth) {
    final onUpdate = PublishSubject<UpdateArg>();
    final onRefresh = PublishSubject();
    final onReset = PublishSubject();
    final onPage = PublishSubject<PageNavigationType>();
    final onPanelWidth = PublishSubject<double>();
    final onDateTime = PublishSubject<DateTime Function(DateTime)>();

    UpdateArg last =
        UpdateArg(fetchType: FetchType.Posts, arg: PostsArgs(page: 1));

    // Call on refresh
    var refresh = onRefresh.switchMap<PostState>((x) {
      return _fetchState(last, booru);
    });

    //pageChange=onPage.throttleTime(Duration(milliseconds: 500)).;

    onReset.asBroadcastStream().listen((event) {
      refreshController.requestRefresh();
    });

    // Laoding stete
    var updateLoading = onUpdate
        .switchMap<PostState>((x) => Stream<PostState>.value(PostLoading()));

    var pageLoading = onPage
        .switchMap<PostState>((x) => Stream<PostState>.value(PostLoading()));

    var resetLoading = onReset
        .switchMap<PostState>((x) => Stream<PostState>.value(PostLoading()));

    var loadingState = updateLoading.mergeWith([pageLoading, resetLoading]);

    // Cache last update
    onUpdate.asBroadcastStream().listen((x) {
      last = x;
      // refreshController.requestLoading();
      // refreshController.footerMode.value = LoadStatus.loading;
    });

    // Fetch posts
    var fetchingState = onUpdate
        .switchMap<PostState>((UpdateArg x) => _fetchState(x, booru))
        .startWith(PostLoading());

    // Merge events
    var _state =
        loadingState.mergeWith([fetchingState, refresh]).asBroadcastStream();

    _state.listen((x) {
      if (x is PostSuccess) cache.addAll(List.from((x).result));
    });

    var panelWidthChanged =
        onPanelWidth.distinct().switchMap<PostState>((x) async* {
      panelWidth = x;
      yield PostSuccess(cache);
    });

    var state = _state
        .mergeWith([panelWidthChanged])
        .startWith(PostSuccess(List<Post>()))
        .switchMap<PostState>((x) async* {
          if (x is PostSuccess)
            yield PostSuccess(await (x).result.arrange());
          else if (x is PostLoading) {
            if (!(last.fetchType == FetchType.Posts ||
                last.fetchType == FetchType.Search)) yield x;
          } else
            yield x;
        })
        .asBroadcastStream();

    // var pagePrevious = onPage
    //     .where((x) => BooruBloc.page > 1)
    //     .where((x) => x == PageNavigationType.Previous)
    //     .map<int>((x) => -1);

    // var pageNext = onPage
    //     .where((x) => BooruBloc.page >= 1)
    //     .where((x) => x == PageNavigationType.Next)
    //     .map<int>((x) => 1);

    // Hold the page value
    // var pageStateChanged = pagePrevious.mergeWith([pageNext]);

    onPage.listen((x) {
      page += 1;
      if (last.fetchType == FetchType.Posts) {
        onUpdate.add(
            UpdateArg(fetchType: last.fetchType, arg: PostsArgs(page: page)));
      } else if (last.fetchType == FetchType.Search) {
        onUpdate.add(UpdateArg(
            fetchType: last.fetchType,
            arg: TaggedArgs(tags: (last.arg as TaggedArgs).tags, page: page)));
      }
    });

    // Reset page
    onReset.asBroadcastStream().listen((x) {
      page = 1;
      cache.clear();
      evaluated.clear();
    });

    // var pageIndicator = pageChanged.mergeWith([pageReset]);

    // Date time changed
    var postDateChanged = onDateTime.switchMap<DateTime>((x) async* {
      var date = x(postDateTime);
      postDateTime = date;

      if (last.fetchType == FetchType.PopularByDay) {
        onUpdate.add(UpdateArg(
            fetchType: last.fetchType,
            arg: PopularByDayArgs(time: postDateTime)));
      }
      if (last.fetchType == FetchType.PopularByWeek) {
        onUpdate.add(UpdateArg(
            fetchType: last.fetchType,
            arg: PopularByWeekArgs(time: postDateTime)));
      }
      if (last.fetchType == FetchType.PopularByMonth) {
        onUpdate.add(UpdateArg(
            fetchType: last.fetchType,
            arg: PopularByMonthArgs(time: postDateTime)));
      }

      yield date;
    }).startWith(DateTime.now());

    // Date reset
    var postDateReset = onReset.switchMap<DateTime>((x) async* {
      postDateTime = DateTime.now();
      yield postDateTime;
    });

    var postDate = postDateChanged.mergeWith([postDateReset]);

    return BooruBloc._(onUpdate, onRefresh, onReset, onPage, onPanelWidth,
        onDateTime, state, postDate);
  }

  static Stream<PostState> _fetchState(UpdateArg arg, BooruAPI booru) async* {
    switch (arg.fetchType) {
      case FetchType.Posts:
        yield await _emptyCheck(BooruAPI.fetchPosts(args: arg.arg));
        break;
      case FetchType.PopularRecent:
        yield await _emptyCheck((BooruAPI.fetchPopularRecent(args: arg.arg)));
        break;
      case FetchType.PopularByDay:
        yield await _emptyCheck((BooruAPI.fetchPopularByDay(args: arg.arg)));
        break;
      case FetchType.PopularByWeek:
        yield await _emptyCheck((BooruAPI.fetchPopularByWeek(args: arg.arg)));
        break;
      case FetchType.PopularByMonth:
        yield await _emptyCheck((BooruAPI.fetchPopularByMonth(args: arg.arg)));
        break;
      case FetchType.Search:
        yield await _emptyCheck((BooruAPI.fetchTagged(args: arg.arg)));
        break;
      default:
    }
  }

  static Future<PostState> _emptyCheck(Future<List<Post>> future) async {
    try {
      var res = await future;
      if (AppSettings.safeMode)
        res = res.where((element) => element.rating == Rating.safe).toList();
      if (res.isEmpty) {
        refreshController.refreshCompleted();
        refreshController.loadComplete();
        return PostEmpty();
      } else {
        refreshController.refreshCompleted();
        refreshController.loadComplete();
        return PostSuccess(res);
      }
    } catch (e) {
      refreshController.refreshCompleted();
      refreshController.loadComplete();
      return PostError(error: e);
    }
  }

  void dispose() {
    onUpdate.close();
    onRefresh.close();
    onReset.close();
    onPage.close();
    onPanelWidth.close();
    onDateTime.close();
  }

  BooruBloc._(
      this.onUpdate,
      this.onRefresh,
      this.onReset,
      this.onPage,
      this.onPanelWidth,
      this.onDateTime,
      this.state,
      // this.pageState,
      this.postDate);
}

enum PageNavigationType { Previous, Next }
