import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_tagged_posts_page.dart';
import 'themes/theme_light.dart';

void main() => runApp(MyApp());

// Routes
const String homePage = '/';
const String searchTaggedPostsPage = '/searchTaggedPostsPage';

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
        case homePage:
          screen = HomePage();
          break;
        case searchTaggedPostsPage:
          screen = SearchTaggedPostsPage();
          break;
        default:
          return null;
      }
      return MaterialPageRoute(builder: (BuildContext contex) => screen);
    };
  }
}

Key _drawer=Key("drawer");
Drawer appDrawer() {
  return Drawer(
    key: _drawer,
    child: Text("Drawer"),
  );
}
