import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TestGroundPage extends StatefulWidget {
  @override
  _TestGroundPageState createState() => _TestGroundPageState();
}

enum DropdownItems { ByDefault, ByFavorite }

class _TestGroundPageState extends State<TestGroundPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: WebView(
            initialUrl: "https://onlionli.com/",
            javascriptMode: JavascriptMode.unrestricted,
            userAgent: "--enable-blink-features=ExperimentalProductivityFeatures",
          ),
    ));
  }
}
