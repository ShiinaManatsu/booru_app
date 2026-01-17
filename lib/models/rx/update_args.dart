import 'package:booru_app/models/rx/booru_api.dart';

/// Argument for update method
class UpdateArg {
  final FetchType fetchType;
  final FetchArg? arg;
  const UpdateArg({required this.fetchType, this.arg});
}

/// Argument base
abstract class FetchArg {
  const FetchArg();
}

/// Argument for post with tags
class TaggedArgs extends FetchArg {
  const TaggedArgs({required this.tags, required this.page});

  final String tags;
  final int page;
}

/// Argument for general post
class PostsArgs extends FetchArg {
  const PostsArgs({required this.page});

  final int page;
}

/// Argument for recent post
class PopularRecentArgs extends FetchArg {
  final Period period;
  const PopularRecentArgs({this.period = Period.None});
}

/// Argument for popular post by day
class PopularByDayArgs extends FetchArg {
  const PopularByDayArgs({required this.time});

  final DateTime time;
}

/// Argument for popular post by week
class PopularByWeekArgs extends FetchArg {
  const PopularByWeekArgs({required this.time});

  final DateTime time;
}

/// Argument for popular post by month
class PopularByMonthArgs extends FetchArg {
  const PopularByMonthArgs({required this.time});

  final DateTime time;
}
