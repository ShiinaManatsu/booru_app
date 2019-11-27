import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/booru_posts.dart';
import 'package:yande_web/models/yande/post.dart';

class BooruBloc {
  final Sink<FetchType> onTypeChanged;
  final Sink<String> onSearchChanged;
  final Stream<List<Post>> posts;

  //BooruPosts booru=new  BooruPosts();

  factory BooruBloc(BooruPosts booru) {
    final onTypeChanged = PublishSubject<FetchType>();
    final onSearchChanged = PublishSubject<String>();

    Observable<List<Post>> posts;
    var typeChanged = onTypeChanged
        .distinct()
        .debounceTime(const Duration(seconds: 1))
        .switchMap<List<Post>>((FetchType x) => _fetch(x, booru))
        .startWith(_yield(booru.fetchPosts));

    var searchChanged = onSearchChanged
        .distinct()
        .debounceTime(const Duration(milliseconds: 500))
        .switchMap<List<Post>>((x) async* {
      List<Post> list;
      await booru.fetchTagsSearch(tags: x).then((x) => list = x);
      yield list;
    });

    posts = typeChanged.mergeWith([searchChanged]);

    /// [posts] may need set state

    return BooruBloc._(onTypeChanged, onSearchChanged, posts);
  }

  static Stream<List<Post>> _fetch(FetchType type, BooruPosts booru) async* {
    switch (type) {
      case FetchType.Posts:
        yield _yield(booru.fetchPosts);
        break;
      case FetchType.PopularRecent:
        yield _yield(booru.fetchPopularRecent);
        break;
      case FetchType.PopularByWeek:
        yield _yield(booru.fetchPopularByWeek);
        break;
      case FetchType.PopularByMonth:
        yield _yield(booru.fetchPopularByMonth);
        break;
      default:
    }
  }

  void dispose() {
    onTypeChanged.close();
  }

  static List<Post> _yield(Function() booru) {
    List<Post> a;
    booru().then((x) {
      a = x;
    });
    return a;
  }

  BooruBloc._(this.onTypeChanged, this.onSearchChanged, this.posts);
}
