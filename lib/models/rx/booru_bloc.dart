import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/post_state.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/extensions/list_extension.dart';

class BooruBloc {
  final PublishSubject<UpdateArg> onUpdate;
  final PublishSubject onRefresh;
  final Stream<List<Post>> posts;
  final Stream<PostState> state;

  //BooruPosts booru=new  BooruPosts();

  factory BooruBloc(BooruAPI booru, double panelWidth) {
    final onUpdate = PublishSubject<UpdateArg>();
    final onRefresh = PublishSubject();
    Observable<List<Post>> posts;

    UpdateArg last;

    onRefresh.listen((x) => print("on refresh"));
    // Call on refresh
    var refresh = onRefresh.switchMap<List<Post>>((x) => _fetch(last, booru));

    // Call on update
    var update = onUpdate
        .distinct()
        .debounceTime(const Duration(seconds: 1))
        .switchMap<List<Post>>((UpdateArg x) => _fetch(x, booru))
        .startWith(List<Post>());

    var onUpdateChange =onUpdate
        .distinct()
        .debounceTime(const Duration(seconds: 1));

    var loadingState = onUpdateChange
        .switchMap<PostState>((x) => Stream<PostState>.value(PostLoading()));

    onUpdate.distinct().listen((x) {
      last = x;
      print("update state updated");
    });

    Observable<PostState> state;
    var fetchingState = onUpdateChange
        .switchMap<PostState>((UpdateArg x) => _fetchState(x, booru))
        .startWith(PostLoading());

    state=loadingState.mergeWith([fetchingState]);

    /// Update the posts when event coming
    /// Try doonlisten to arrang the post after listen
    posts = update.mergeWith([refresh]);
    // fixingPosts.listen((x) {
    //   x.arrange(panelWidth);
    //   print("posts length: ${x.length}");
    // });

    // posts
    //   .distinct()
    //   .listen((x)=>print("posts length: ${x.length}"));

    return BooruBloc._(onUpdate, onRefresh, posts, state);
  }

  static Stream<List<Post>> _fetch(UpdateArg arg, BooruAPI booru) async* {
    print("Fetching...");
    switch (arg.fetchType) {
      case FetchType.Posts:
        yield (await booru.fetchPosts(args: arg.arg)).arrange();
        break;
      case FetchType.PopularRecent:
        yield (await booru.fetchPopularRecent(args: arg.arg)).arrange();
        break;
      case FetchType.PopularByWeek:
        yield (await booru.fetchPopularByWeek(args: arg.arg)).arrange();
        break;
      case FetchType.PopularByMonth:
        yield (await booru.fetchPopularByMonth(args: arg.arg)).arrange();
        break;
      default:
    }
  }

  static Stream<PostState> _fetchState(UpdateArg arg, BooruAPI booru) async* {
    print("Fetching...");
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

  BooruBloc._(this.onUpdate, this.onRefresh, this.posts, this.state);
}
