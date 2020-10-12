import 'dart:io';

import 'package:booru_app/extensions/shared_preferences_extension.dart';
import 'package:booru_app/main.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:booru_app/pages/widgets/sliver_floating_bar.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  var locationIsExpand = true;
  double postLimit = 50;
  var setLimit = PublishSubject<double>();
  String savePath = "";

  PreviewQuality quality = AppSettings.previewQuality;
  bool _safeMode = AppSettings.safeMode;
  bool _masonryGrid = AppSettings.masonryGrid;

  @override
  void initState() {
    super.initState();
    AppSettings.postLimit.then((value) {
      setState(() {
        postLimit = value;
      });
    });

    AppSettings.savePath.then((value) {
      setState(() {
        savePath = value;
      });
    });

    setLimit
        .throttleTime(Duration(milliseconds: 200))
        .switchMap((value) async* {
      yield value;
    }).listen((x) {
      AppSettings.setPostLimit(x);
    });
  }

  @override
  void dispose() {
    super.dispose();
    setLimit.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFloatingBar(
            backgroundColor: Theme.of(context).backgroundColor,
            automaticallyImplyLeading: true,
            title: Text("${language.content.settings}",
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
          //  Download location
          _buildCard(
              child: ListTile(
            title: Text(
                "${language.content.download} ${language.content.location}"),
            subtitle:
                Text("$savePath", style: Theme.of(context).textTheme.button),
            isThreeLine: true,
            trailing: Icon(Icons.folder),
            onTap: () async {
              var status = await Permission.storage.status;
              if (status == PermissionStatus.granted) {
                String path = await FilesystemPicker.open(
                  title: 'Save to folder',
                  context: context,
                  rootDirectory:
                      Directory.fromUri(Uri.directory("storage/emulated/0/")),
                  fsType: FilesystemType.folder,
                  pickText: 'Save file to this folder',
                  folderIconColor: Colors.pink,
                );
                AppSettings.setSavePath(path);
                AppSettings.savePath.then((value) {
                  setState(() {
                    savePath = value;
                  });
                });
              } else {
                Permission.storage.request();
              }
            },
          )),
          //  Load limit
          _buildCard(
              child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text("${language.content.singlePagePostLoadLimit}"),
            subtitle: Row(
              children: <Widget>[
                Text("${language.content.currentLimit}: ${postLimit.toInt()}"),
                Expanded(
                  child: Slider(
                    value: postLimit,
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor:
                        Theme.of(context).primaryColor.withAlpha(0x80),
                    onChanged: (value) {
                      setState(() {
                        postLimit = value;
                        setLimit.add(value);
                      });
                    },
                    min: 40,
                    max: 100,
                    divisions: 60,
                  ),
                )
              ],
            ),
          )),
          //  Preview quality
          _buildCard(
              child: ListTile(
            title:
                Text("${language.content.preview} ${language.content.quality}"),
            trailing: DropdownButton<PreviewQuality>(
              items: PreviewQuality.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(EnumToString.convertToString(e)),
                      ))
                  .toList(),
              value: quality,
              onChanged: (value) {
                setState(() {
                  quality = value;
                  AppSettings.previewQuality = value;
                  SharedPreferencesExtension.setTyped(
                      "PreviewQuality", EnumToString.convertToString(value));
                });
              },
            ),
          )),
          //  Safe mode
          _buildCard(
              child: ListTile(
            title: Text("${language.content.safe} ${language.content.mode}"),
            trailing: Switch(
              value: _safeMode,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                SharedPreferencesExtension.setTyped<bool>("safemode", value);
                AppSettings.safeMode = value;
                setState(() {
                  _safeMode = value;
                });
              },
            ),
            onTap: () {
              SharedPreferencesExtension.setTyped<bool>(
                  "safemode", !AppSettings.safeMode);
              AppSettings.safeMode = !AppSettings.safeMode;
              setState(() {
                _safeMode = !AppSettings.safeMode;
              });
            },
          )),
          //  Masonry Grid
          _buildCard(
              child: ListTile(
            title: Text("Masonry Grid"),
            trailing: Switch(
              value: _masonryGrid,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                SharedPreferencesExtension.setTyped<bool>("masonryGrid", value);
                AppSettings.masonryGrid = value;
                setState(() {
                  _masonryGrid = value;
                });
              },
            ),
            onTap: () {
              SharedPreferencesExtension.setTyped<bool>(
                  "masonryGrid", !AppSettings.masonryGrid);
              AppSettings.masonryGrid = !AppSettings.masonryGrid;
              setState(() {
                _masonryGrid = AppSettings.masonryGrid;
              });
            },
          )),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildCard({Widget child}) {
    return SliverToBoxAdapter(
        child: Card(
      elevation: 4,
      margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: child,
    ));
  }
}

enum PreviewQuality { Low, Medium, High, Original }
