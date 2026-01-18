import 'dart:async';

import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/post_state.dart';
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:rxdart/rxdart.dart';

class BooruBloc {
  BooruBloc();

  final BehaviorSubject<PostState> _state = BehaviorSubject<PostState>.seeded(PostLoading());

  final List<Post> _cache = <Post>[];
  final Set<int> _seenPostIds = <int>{};

  FetchType _fetchType = FetchType.Posts;
  FetchArg? _lastArg;
  int _page = 1;
  bool _isFetching = false;
  bool _hasMore = true;

  Stream<PostState> get stream => _state.stream;
  PostState get currentState => _state.value;

  Future<void> bootstrap({
    FetchType fetchType = FetchType.Posts,
    FetchArg? arg,
  }) async {
    _fetchType = fetchType;
    _lastArg = arg;
    _page = 1;
    _hasMore = true;
    _cache.clear();
    _seenPostIds.clear();
    _state.add(PostLoading());
    await _fetch(append: false);
  }

  Future<void> setFetchType(FetchType type, {FetchArg? arg}) async {
    _fetchType = type;
    _lastArg = arg;
    await bootstrap(fetchType: type, arg: arg);
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    _cache.clear();
    _seenPostIds.clear();

    switch (_fetchType) {
      case FetchType.PopularByDay:
        _lastArg = PopularByDayArgs(time: DateTime.now());
        break;
      case FetchType.PopularByWeek:
        _lastArg = PopularByWeekArgs(time: DateTime.now());
        break;
      case FetchType.PopularByMonth:
        _lastArg = PopularByMonthArgs(time: DateTime.now());
        break;
      default:
        break;
    }

    _state.add(PostLoading());
    await _fetch(append: false);
  }

  Future<void> loadMore() async {
    if (_state.value is PostLoading) return;
    if (_isFetching) return;
    if (!_hasMore) return;

    // Paged endpoints:
    // - Posts/Search: page++
    // - Pool: page++
    // - PopularByDay/Week/Month: move the time window backward
    if (_fetchType == FetchType.Posts || _fetchType == FetchType.Search || _fetchType == FetchType.Pool) {
      _page += 1;
      await _fetch(append: true);
      return;
    }

    if (_fetchType == FetchType.PopularByDay || _fetchType == FetchType.PopularByWeek || _fetchType == FetchType.PopularByMonth) {
      // Some days/weeks/months can legitimately return empty. Try a few steps back
      // so scrolling doesn't get stuck immediately.
      const int maxAttempts = 8;

      DateTime current = switch (_fetchType) {
        FetchType.PopularByDay => (_lastArg as PopularByDayArgs?)?.time ?? DateTime.now(),
        FetchType.PopularByWeek => (_lastArg as PopularByWeekArgs?)?.time ?? DateTime.now(),
        FetchType.PopularByMonth => (_lastArg as PopularByMonthArgs?)?.time ?? DateTime.now(),
        _ => DateTime.now(),
      };

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        current = _shiftPopularTimeBack(_fetchType, current);
        _lastArg = switch (_fetchType) {
          FetchType.PopularByDay => PopularByDayArgs(time: current),
          FetchType.PopularByWeek => PopularByWeekArgs(time: current),
          FetchType.PopularByMonth => PopularByMonthArgs(time: current),
          _ => _lastArg,
        };

        // Call API directly so we can decide whether to retry on empty.
        if (_isFetching) return;
        _isFetching = true;
        try {
          final List<Post> result = await _callApi();
          final filtered = AppSettings.safeMode ? result.where((post) => post.rating == Rating.safe).toList() : result;

          if (filtered.isEmpty) {
            // keep trying an earlier window
            continue;
          }

          final added = _mergeDistinct(filtered);
          if (added == 0) {
            // All duplicates; try an earlier window.
            continue;
          }
          _state.add(PostSuccess(List<Post>.unmodifiable(_cache)));
          return;
        } catch (error) {
          _state.add(PostError(error: error));
          return;
        } finally {
          _isFetching = false;
        }
      }

      // Tried several earlier windows and still got nothing.
      _hasMore = false;
      if (_state.value is PostSuccess) {
        _state.add(PostSuccess(List<Post>.unmodifiable(_cache)));
      }
      return;
    }
  }

  DateTime _shiftPopularTimeBack(FetchType type, DateTime time) {
    switch (type) {
      case FetchType.PopularByDay:
        return time.subtract(const Duration(days: 1));
      case FetchType.PopularByWeek:
        return time.subtract(const Duration(days: 7));
      case FetchType.PopularByMonth:
        var year = time.year;
        var month = time.month - 1;
        if (month <= 0) {
          month += 12;
          year -= 1;
        }
        // Month endpoint only uses month/year, day isn't relevant.
        return DateTime(year, month, 1);
      default:
        return time;
    }
  }

  Future<void> _fetch({required bool append}) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final List<Post> result = await _callApi();

      // If the API returns no results for a paged endpoint, stop requesting more pages.
      if (append && result.isEmpty && (_fetchType == FetchType.Posts || _fetchType == FetchType.Search || _fetchType == FetchType.Pool)) {
        _hasMore = false;
        _page = (_page - 1).clamp(1, 1 << 30);
        _state.add(PostSuccess(List<Post>.unmodifiable(_cache)));
        return;
      }

      final filtered = AppSettings.safeMode ? result.where((post) => post.rating == Rating.safe).toList() : result;

      if (!append) {
        _cache.clear();
        _seenPostIds.clear();
      }

      final added = _mergeDistinct(filtered);

      // If we requested a new page but got no new items, stop paging to avoid
      // infinite requests and also prevent duplicate Hero tags.
      if (append && added == 0 && (_fetchType == FetchType.Posts || _fetchType == FetchType.Search || _fetchType == FetchType.Pool)) {
        _hasMore = false;
      }

      _state.add(PostSuccess(List<Post>.unmodifiable(_cache)));
    } catch (error) {
      _state.add(PostError(error: error));
    } finally {
      _isFetching = false;
    }
  }

  int _mergeDistinct(List<Post> incoming) {
    var added = 0;
    for (final post in incoming) {
      final id = post.id;
      if (_seenPostIds.add(id)) {
        _cache.add(post);
        added += 1;
      }
    }
    return added;
  }

  Future<List<Post>> _callApi() async {
    switch (_fetchType) {
      case FetchType.Posts:
        return BooruAPI.fetchPosts(args: PostsArgs(page: _page));
      case FetchType.PopularRecent:
        return BooruAPI.fetchPopularRecent(args: (_lastArg as PopularRecentArgs?) ?? PopularRecentArgs(period: Period.None));
      case FetchType.PopularByDay:
        return BooruAPI.fetchPopularByDay(args: (_lastArg as PopularByDayArgs?) ?? PopularByDayArgs(time: DateTime.now()));
      case FetchType.PopularByWeek:
        return BooruAPI.fetchPopularByWeek(args: (_lastArg as PopularByWeekArgs?) ?? PopularByWeekArgs(time: DateTime.now()));
      case FetchType.PopularByMonth:
        return BooruAPI.fetchPopularByMonth(args: (_lastArg as PopularByMonthArgs?) ?? PopularByMonthArgs(time: DateTime.now()));
      case FetchType.Search:
        final args = (_lastArg as TaggedArgs?) ?? TaggedArgs(tags: "", page: _page);
        return BooruAPI.fetchTagged(args: TaggedArgs(tags: args.tags, page: _page));
      case FetchType.Pool:
        final args = (_lastArg as PoolShowArgs?) ?? PoolShowArgs(id: 0, page: _page);
        if (args.id <= 0) return <Post>[];
        return BooruAPI.fetchPoolPosts(id: args.id, page: _page);
    }
  }

  void dispose() {
    _state.close();
  }
}

enum PageNavigationType { Previous, Next }
