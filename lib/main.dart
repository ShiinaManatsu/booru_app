import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_tagged_posts_page.dart';
import 'themes/theme_light.dart';

void main() => runApp(MyApp());

// Routes
const String _HomePage = '/';
const String _SearchTaggedPostsPage = '/searchTaggedPostsPage';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        onGenerateRoute: _routes(), title: 'Home', theme: lightTheme);
  }

  RouteFactory _routes() {
    return (settings) {
      //final Map<String, dynamic> arg = settings.arguments;
      Widget screen;
      switch (settings.name) {
        case _HomePage:
          screen = HomePage();
          break;
        case _SearchTaggedPostsPage:
          screen = SearchTaggedPostsPage();
          break;
        default:
          return null;
      }
      return MaterialPageRoute(builder: (BuildContext contex) => screen);
    };
  }
}
