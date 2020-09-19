import 'package:auto_route/auto_route_annotations.dart';
import 'package:booru_app/pages/about_page.dart';
import 'package:booru_app/pages/post_view_page.dart';
import 'package:booru_app/pages/post_view_page_by_post_id.dart';
import 'package:booru_app/pages/search_tagged_posts_page.dart';
import 'package:booru_app/pages/setting_page.dart';
import 'package:booru_app/pages/testGroundPage.dart';
import 'pages/home_page.dart';

@MaterialAutoRouter(
  routes: <AutoRoute>[
    // initial route is named "/"
    MaterialRoute(page: HomePage, initial: true),
    MaterialRoute(page: SearchTaggedPostsPage),
    MaterialRoute(page: PostViewPage),
    MaterialRoute(page: SettingPage),
    MaterialRoute(page: TestGroundPage),
    MaterialRoute(page: PostViewPageByPostID),
    MaterialRoute(page: AboutPage)
  ],
)
class $Router {}