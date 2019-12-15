import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/post_state.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/extensions/list_extension.dart';

class BooruBloc {
  // Subjects
  /// Call to update posts
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
  final Stream<int> pageState;

  /// Stream of the date picker
  final Stream<DateTime> postDate;

  // Static members
  static DateTime postDateTime = DateTime.now();
  static int page = 1;

  factory BooruBloc(BooruAPI booru, double panelWidth) {
    final onUpdate = PublishSubject<UpdateArg>();
    final onRefresh = PublishSubject();
    final onReset = PublishSubject();
    final onPage = PublishSubject<PageNavigationType>();
    final onPanelWidth = PublishSubject<double>();
    final PublishSubject<DateTime Function(DateTime)> onDateTime =
        PublishSubject<DateTime Function(DateTime)>();

    UpdateArg last =
        UpdateArg(fetchType: FetchType.Posts, arg: PostsArgs(page: 1));

    // Call on refresh
    var refresh =
        onRefresh.switchMap<PostState>((x) => _fetchState(last, booru));

    // Call on update
    var onUpdateChange =
        onUpdate.distinct().throttleTime(const Duration(seconds: 1));

    //pageChange=onPage.throttleTime(Duration(milliseconds: 500)).;

    // Laoding stete
    var loadingState = onUpdateChange
        .switchMap<PostState>((x) => Stream<PostState>.value(PostLoading()));

    // Cache last update
    onUpdate.distinct().listen((x) {
      last = x;
      print("update state updated");
    });

    // Fetch posts
    var fetchingState = onUpdateChange
        .switchMap<PostState>((UpdateArg x) => _fetchState(x, booru))
        .startWith(PostLoading());

    // Merge events
    var state = loadingState.mergeWith([fetchingState, refresh]);

    var pagePrevious = onPage
        .where((x) => BooruBloc.page >= 1)
        .where((x) => x == PageNavigationType.Previous)
        .map<int>((x) => -1);

    var pageNext = onPage
        .where((x) => BooruBloc.page >= 1)
        .where((x) => x == PageNavigationType.Next)
        .map<int>((x) => 1);

    // Hold the page value
    var pageStateChanged = pagePrevious.mergeWith([pageNext]);

    var pageChanged = pageStateChanged.switchMap<int>((x) async* {
      page += x;
      if (last.fetchType == FetchType.Posts) {
        onUpdate.add(
            UpdateArg(fetchType: last.fetchType, arg: PostsArgs(page: page)));
      } else if (last.fetchType == FetchType.Search) {
        onUpdate.add(UpdateArg(
            fetchType: last.fetchType,
            arg: TaggedArgs(tags: (last.arg as TaggedArgs).tags, page: page)));
      }
      yield page;
    }).startWith(1);

    var pageReset = onReset.switchMap<int>((x) async* {
      page = 1;
      yield page;
    });

    var pageIndicator = pageChanged.mergeWith([pageReset]);

    var panelWidthChanged = onPanelWidth.distinct();

    panelWidthChanged.listen((x) {
      panelWidth = x;
      print("panelChanged");
      onRefresh.add(null);
    });

    // Date time changed
    var postDateChanged = onDateTime.switchMap<DateTime>((x) async* {
      var date = x(postDateTime);
      postDateTime = date;
      
      print(postDateTime.toUtc());
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
        onDateTime, state, pageIndicator, postDate);
  }

  static Stream<PostState> _fetchState(UpdateArg arg, BooruAPI booru) async* {
    print("Fetching...${arg.fetchType.toString()}");
    switch (arg.fetchType) {
      case FetchType.Posts:
        yield await _emptyCheck(booru.fetchPosts(args: arg.arg));
        break;
      case FetchType.PopularRecent:
        yield await _emptyCheck((booru.fetchPopularRecent(args: arg.arg)));
        break;
      case FetchType.PopularByDay:
        yield await _emptyCheck((booru.fetchPopularByDay(args: arg.arg)));
        break;
      case FetchType.PopularByWeek:
        yield await _emptyCheck((booru.fetchPopularByWeek(args: arg.arg)));
        break;
      case FetchType.PopularByMonth:
        yield await _emptyCheck((booru.fetchPopularByMonth(args: arg.arg)));
        break;
      case FetchType.Search:
        yield await _emptyCheck((booru.fetchTagged(args: arg.arg)));
        break;
      default:
    }
  }

  static Future<PostState> _emptyCheck(Future<List<Post>> future) async {
    try {
      var res = await future;
      if (res.isEmpty) {
        return PostEmpty();
      } else {
        return PostSuccess(res.arrange());
      }
    } catch (e) {
      return PostError(error: e);
    }
  }

  void dispose() {
    onUpdate.close();
    onRefresh.close();
    onReset.close();
    onPage.close();
    onPanelWidth.close();
  }

  BooruBloc._(
      this.onUpdate,
      this.onRefresh,
      this.onReset,
      this.onPage,
      this.onPanelWidth,
      this.onDateTime,
      this.state,
      this.pageState,
      this.postDate);
}

enum PageNavigationType { Previous, Next }
