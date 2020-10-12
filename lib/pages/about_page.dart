import 'dart:io';

import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/pages/widgets/sliver_floating_bar.dart';
import 'package:booru_app/pages/widgets/update_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';

class AboutPage extends StatefulWidget {
  AboutPage({Key key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  VersionInfo remoteVersionInfo;
  PackageInfo localVersionInfo;
  GlobalKey<UpdateDialogState> dialogKey = new GlobalKey();

  bool haveUpdate = false;

  CancelToken cancelToken;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
    cancelToken = CancelToken();
  }

  _checkUpdate() async {
    localVersionInfo = await PackageInfo.fromPlatform();
    remoteVersionInfo = await BooruAPI.getLastestVersion();

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
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFloatingBar(
            backgroundColor: Theme.of(context).backgroundColor,
            automaticallyImplyLeading: true,
            title: Text("About",
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(fontSize: 28)),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).textTheme.headline6.color,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          _buildCard(
              child: ListTile(
            title: Text("Current Version"), //#TN
            subtitle: Text(
                "${localVersionInfo?.version ?? ""}${haveUpdate ? " - new version can be download" : ""}"),
            trailing: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: haveUpdate ? 1 : 0),
              duration: Duration(milliseconds: 300),
              curve: Curves.ease,
              builder: (context, value, child) =>
                  Icon(Icons.update, size: value * 24),
            ),
            onTap: () {
              if (haveUpdate)
                showUpdateDialog(
                    remoteVersionInfo.tagName, remoteVersionInfo.url);
            },
          ))
        ],
      ),
    );
  }

  //  Uodates methods

  void showUpdateDialog(String version, String url) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => _buildDialog(version, url),
    );
  }

  Widget _buildDialog(String version, String url) {
    return UpdateDialog(
      key: dialogKey,
      version: version,
      cancleToken: cancelToken,
      onClickWhenNotDownload: () {
        //下载apk，完成后打开apk文件，建议使用dio+open_file插件
        downloadApk(
            onRecieve: (int c, int t) {
              setState(() {
                dialogKey?.currentState?.progress = c / t;
              });
            },
            onError: (e) {
              toast("$e");
              print(e);
            },
            url: url);
      },
    );
  }

  void downloadApk({Function onRecieve, Function onError, String url}) async {
    Directory tempDir = await getExternalStorageDirectory();
    String tempPath = tempDir.path;
    String savePath = '$tempPath/update.apk';
    //  await dio.download('${ConstantValue.HTTP_DOWNLOAD_URL}', savePath,
    //  onReceiveProgress: f);
    try {
      var res = await Dio().download(url, savePath,
          onReceiveProgress: onRecieve,
          cancelToken: cancelToken,
          options: Options(receiveTimeout: 5 * 60 * 1000));
      if ((res?.statusCode ?? 0) == 200) {
        _installApk(savePath);
      }
    } catch (e) {
      onError(e);
    }
  }

  void _installApk(String path) async {
    OpenFile.open(path);
  }

  SliverToBoxAdapter _buildCard({Widget child}) {
    return SliverToBoxAdapter(
        child: Card(
      elevation: 4,
      margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: child,
    ));
  }

  @override
  void dispose() {
    super.dispose();
    cancelToken.cancel();
  }
}
