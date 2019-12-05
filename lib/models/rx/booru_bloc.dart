import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/post.dart';

class BooruBloc {
  final PublishSubject<UpdateArg> onUpdate;
  final PublishSubject onRefresh;
  final Stream<List<Post>> posts;

  //BooruPosts booru=new  BooruPosts();

  factory BooruBloc(BooruAPI booru) {
    final onUpdate = PublishSubject<UpdateArg>();
    final onRefresh = PublishSubject();
    Observable<List<Post>> posts;

    // Call on update
    var update = onUpdate
        .distinct()
        .debounceTime(const Duration(seconds: 1))
        .switchMap<List<Post>>((UpdateArg x) => _fetch(x, booru))
        .startWith(_yield(booru.fetchPosts, new PostsArgs(page: 1)));

    UpdateArg last;
    onUpdate
      .distinct()
      .listen((x)=>last=x);

    // Call on refresh
    var refresh=onRefresh
        .switchMap<List<Post>>((x) => _fetch(last, booru));

    // Update the posts when event coming
    posts=update.mergeWith([refresh]);

    return BooruBloc._(onUpdate,onRefresh, posts);
  }

  static Stream<List<Post>> _fetch(UpdateArg arg, BooruAPI booru) async* {
    switch (arg.fetchType) {
      case FetchType.Posts:
        yield _yield(booru.fetchPosts, arg.arg);
        break;
      case FetchType.PopularRecent:
        yield _yield(booru.fetchPopularRecent, arg.arg);
        break;
      case FetchType.PopularByWeek:
        yield _yield(booru.fetchPopularByWeek, arg.arg);
        break;
      case FetchType.PopularByMonth:
        yield _yield(booru.fetchPopularByMonth, arg.arg);
        break;
      default:
    }
  }

  void dispose() {
    onUpdate.close();
    onRefresh.close();
  }

  static List<Post> _yield(Function() booru, FetchArg arg) {
    List<Post> a;
    booru().then((x) {
      a = x;
    });
    return a;
  }

  BooruBloc._(this.onUpdate, this.onRefresh,this.posts);
}
