import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/post_state.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/extensions/list_extension.dart';

class BooruBloc {
  final PublishSubject<UpdateArg> onUpdate;
  final PublishSubject onRefresh;
  final PublishSubject onReset;
  final PublishSubject<PageNavigationType> onPage;
  final Stream<PostState> state;
  final Stream<int> pageState;
  static int page = 1;

  factory BooruBloc(BooruAPI booru, double panelWidth) {
    final onUpdate = PublishSubject<UpdateArg>();
    final onRefresh = PublishSubject();
    final onReset = PublishSubject();
    final onPage = PublishSubject<PageNavigationType>();

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
    var state = loadingState.mergeWith([fetchingState, refresh]).doOnListen(() {
      print("Init start");
      onUpdate
          .add(UpdateArg(fetchType: FetchType.Posts, arg: PostsArgs(page: 1)));
    });

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
      print("Page Changed: $page");
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

    var pageReset=onReset
        .switchMap<int>((x) async* {
          page=1; 
          yield page;
          }
        );

    var pageIndicator=pageChanged.mergeWith([pageReset]);

    return BooruBloc._(
        onUpdate, onRefresh, onReset, onPage, state, pageIndicator);
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
  }

  BooruBloc._(this.onUpdate, this.onRefresh, this.onReset, this.onPage,
      this.state, this.pageState);
}

enum PageNavigationType { Previous, Next }
