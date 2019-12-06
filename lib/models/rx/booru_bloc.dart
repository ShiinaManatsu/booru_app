import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/post_state.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/extensions/list_extension.dart';

class BooruBloc {
  final PublishSubject<UpdateArg> onUpdate;
  final PublishSubject onRefresh;
  final PublishSubject<bool> onPage;
  final PublishSubject onReset;
  final Stream<PostState> state;
  static int page = 1;

  //BooruPosts booru=new  BooruPosts();

  factory BooruBloc(BooruAPI booru, double panelWidth) {
    final onUpdate = PublishSubject<UpdateArg>();
    final onRefresh = PublishSubject();
    final onPage = PublishSubject<bool>();
    final onReset = PublishSubject();

    Observable<PostState> state;
    UpdateArg last;

    // Call on refresh
    var refresh =
        onRefresh.switchMap<PostState>((x) => _fetchState(last, booru));

    // Call on update
    var onUpdateChange =
        onUpdate.distinct().throttleTime(const Duration(seconds: 1));

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
    state = loadingState.mergeWith([fetchingState, refresh]);

    // Next page or preview
    var onPageChange = onPage.throttleTime(Duration(milliseconds: 500));

    onPageChange.listen((x) {
      x ? page++ : page--;
    });

    // Reset page
    var reset = onReset.throttleTime(Duration(seconds: 1));

    // May should register to the refresh call
    reset.listen((x) => page = 1);

    return BooruBloc._(onUpdate, onRefresh, onPage, onReset, state);
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
  }

  BooruBloc._(
      this.onUpdate, this.onRefresh, this.onPage, this.onReset, this.state);
}
