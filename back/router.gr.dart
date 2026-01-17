// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/yande/post.dart';
import 'pages/about_page.dart';
import 'pages/home_page.dart';
import 'pages/post_view_page.dart';
import 'pages/post_view_page_by_post_id.dart';
import 'pages/search_tagged_posts_page.dart';
import 'pages/setting_page.dart';
import 'pages/testGroundPage.dart';

class Routes {
  static const String homePage = '/';
  static const String searchTaggedPostsPage = '/search-tagged-posts-page';
  static const String postViewPage = '/post-view-page';
  static const String settingPage = '/setting-page';
  static const String testGroundPage = '/test-ground-page';
  static const String postViewPageByPostID = '/post-view-page-by-post-iD';
  static const String aboutPage = '/about-page';
  static const all = <String>{
    homePage,
    searchTaggedPostsPage,
    postViewPage,
    settingPage,
    testGroundPage,
    postViewPageByPostID,
    aboutPage,
  };
}

class Router extends RouterBase {
  @override
  List<RouteDef> get routes => _routes;
  final _routes = <RouteDef>[
    RouteDef(Routes.homePage, page: HomePage),
    RouteDef(Routes.searchTaggedPostsPage, page: SearchTaggedPostsPage),
    RouteDef(Routes.postViewPage, page: PostViewPage),
    RouteDef(Routes.settingPage, page: SettingPage),
    RouteDef(Routes.testGroundPage, page: TestGroundPage),
    RouteDef(Routes.postViewPageByPostID, page: PostViewPageByPostID),
    RouteDef(Routes.aboutPage, page: AboutPage),
  ];
  @override
  Map<Type, AutoRouteFactory> get pagesMap => _pagesMap;
  final _pagesMap = <Type, AutoRouteFactory>{
    HomePage: (data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => HomePage(),
        settings: data,
      );
    },
    SearchTaggedPostsPage: (data) {
      final args = data.getArgs<SearchTaggedPostsPageArguments>(
        orElse: () => SearchTaggedPostsPageArguments(),
      );
      return MaterialPageRoute<dynamic>(
        builder: (context) => SearchTaggedPostsPage(key: args.key),
        settings: data,
      );
    },
    PostViewPage: (data) {
      final args = data.getArgs<PostViewPageArguments>(nullOk: false);
      return MaterialPageRoute<dynamic>(
        builder: (context) => PostViewPage(post: args.post),
        settings: data,
      );
    },
    SettingPage: (data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => SettingPage(),
        settings: data,
      );
    },
    TestGroundPage: (data) {
      return MaterialPageRoute<dynamic>(
        builder: (context) => TestGroundPage(),
        settings: data,
      );
    },
    PostViewPageByPostID: (data) {
      final args = data.getArgs<PostViewPageByPostIDArguments>(nullOk: false);
      return MaterialPageRoute<dynamic>(
        builder: (context) => PostViewPageByPostID(postID: args.postID),
        settings: data,
      );
    },
    AboutPage: (data) {
      final args = data.getArgs<AboutPageArguments>(
        orElse: () => AboutPageArguments(),
      );
      return MaterialPageRoute<dynamic>(
        builder: (context) => AboutPage(key: args.key),
        settings: data,
      );
    },
  };
}

/// ************************************************************************
/// Arguments holder classes
/// *************************************************************************

/// SearchTaggedPostsPage arguments holder class
class SearchTaggedPostsPageArguments {
  final Key key;
  SearchTaggedPostsPageArguments({this.key});
}

/// PostViewPage arguments holder class
class PostViewPageArguments {
  final Post post;
  PostViewPageArguments({@required this.post});
}

/// PostViewPageByPostID arguments holder class
class PostViewPageByPostIDArguments {
  final String postID;
  PostViewPageByPostIDArguments({@required this.postID});
}

/// AboutPage arguments holder class
class AboutPageArguments {
  final Key key;
  AboutPageArguments({this.key});
}
