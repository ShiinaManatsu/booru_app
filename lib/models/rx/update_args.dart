import 'package:flutter/foundation.dart';
import 'package:booru_app/models/rx/booru_api.dart';

/// Argument for update method
class UpdateArg {
  final FetchType fetchType;
  final FetchArg arg;
  UpdateArg({@required this.fetchType, this.arg});
}

/// Arg will contain a page property
class ArgWithPage {
  int page;
}

/// Argument base
class FetchArg {}

/// Argument for post with tags
class TaggedArgs extends FetchArg with ArgWithPage {
  final String tags;
  final int page;
  TaggedArgs({@required this.tags, @required this.page});
}

/// Argument for general post
class PostsArgs extends FetchArg with ArgWithPage {
  final int page;
  PostsArgs({@required this.page});
}

/// Argument for recent post
class PopularRecentArgs extends FetchArg {
  final Period period;
  PopularRecentArgs({this.period = Period.None});
}

class ArgWithTime {
  DateTime time;
}

/// Argument for popular post by day
class PopularByDayArgs extends FetchArg with ArgWithTime {
  final DateTime time;
  PopularByDayArgs({@required this.time});
}

/// Argument for popular post by week
class PopularByWeekArgs extends FetchArg with ArgWithTime {
  final DateTime time;
  PopularByWeekArgs({@required this.time});
}

/// Argument for popular post by month
class PopularByMonthArgs extends FetchArg with ArgWithTime {
  final DateTime time;
  PopularByMonthArgs({@required this.time});
}
