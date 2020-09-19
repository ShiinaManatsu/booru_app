import 'package:booru_app/models/rx/booru_api.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

class AboutPage extends StatefulWidget {
  AboutPage({Key key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  VersionInfo remoteVersionInfo;
  PackageInfo localVersionInfo;

  bool haveUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  _checkUpdate() async {
    remoteVersionInfo = await BooruAPI.getLastestVersion();
    localVersionInfo = await PackageInfo.fromPlatform();

    var localVersionCode =
        int.parse(localVersionInfo.version.replaceAll(".", ""));

    if (mounted) {
      setState(() {
        haveUpdate = remoteVersionInfo.versionCode > localVersionCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("About"),
      ),
      body: Container(
        child: Center(
          child: Text("$haveUpdate"),
        ),
      ),
    );
  }
}
