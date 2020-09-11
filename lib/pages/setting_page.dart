import 'dart:io';

import 'package:booru_app/main.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:booru_app/pages/widgets/sliver_floating_bar.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rxdart/rxdart.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  var locationIsExpand = true;
  double postLimit = 0;
  var setLimit = PublishSubject<double>();
  String savePath = "";

  var expansionStatus = [false, false];

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

    setLimit.throttleTime(Duration(milliseconds: 200)).listen((x) {
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
            title: Text("${language.content.settings}"),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ExpansionPanelList(
                  expansionCallback: (index, flag) {
                    setState(() {
                      expansionStatus[index] = !flag;
                    });
                  },
                  children: <ExpansionPanel>[
                    ExpansionPanel(
                      canTapOnHeader: true,
                      isExpanded: expansionStatus[0],
                      headerBuilder: (context, d) {
                        return ListTile(
                          title: Text(
                              "${language.content.download} ${language.content.location}"),
                        );
                      },
                      body: ListTile(
                        trailing: FlatButton(
                          child: Text(
                              "${language.content.select} ${language.content.folder}"),
                          onPressed: () async {
                            String path = await FilesystemPicker.open(
                              title: 'Save to folder',
                              context: context,
                              rootDirectory: Directory.fromUri(
                                  Uri.directory("storage/emulated/0/")),
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
                          },
                        ),
                        title: Text("$savePath",
                            style: Theme.of(context).textTheme.button),
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      isExpanded: expansionStatus[1],
                      headerBuilder: (context, d) {
                        return ListTile(
                          title: Text(
                              "${language.content.singlePagePostLoadLimit}"),
                        );
                      },
                      body: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text(
                                "${language.content.currentLimit}: ${postLimit.toInt()}"),
                            Slider(
                              value: postLimit,
                              onChanged: (value) {
                                setState(() {
                                  postLimit = value;
                                  setLimit.add(value);
                                });
                              },
                              min: 40,
                              max: 100,
                              divisions: 50,
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
