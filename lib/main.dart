import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'themes/theme_light.dart';


void main() => runApp(MyApp());


// Routes
const String _HomePage = '/';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: _routes(),
      title: 'Home',
      theme: lightTheme
    );
  }

  RouteFactory _routes() {
    return (settings) {
      //final Map<String, dynamic> arg = settings.arguments;
      Widget screen;
      switch (settings.name) {
        case _HomePage:
          screen = HomePage();
          break;
        default:
          return null;
      }
      return MaterialPageRoute(builder: (BuildContext contex) => screen);
    };
  }
}
