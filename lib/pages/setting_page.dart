import 'package:booru_app/main.dart';
import 'package:flutter/material.dart';
import 'package:booru_app/pages/widgets/sliver_floating_bar.dart';
import 'package:booru_app/settings/app_settings.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  var locationIsExpand = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFloatingBar(
            backgroundColor: Colors.white,
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
                      locationIsExpand = !flag;
                    });
                  },
                  children: <ExpansionPanel>[
                    ExpansionPanel(
                      canTapOnHeader: true,
                      isExpanded: locationIsExpand,
                      headerBuilder: (context, d) {
                        return ListTile(
                          title: Text("${language.content.download} ${language.content.location}"),
                        );
                      },
                      body: ListTile(
                        title: Text("${language.content.location}"),
                        subtitle: TextField(
                          decoration: InputDecoration(
                              prefixText: "${language.content.newLocationHere}: ",
                              helperText: AppSettings.savePath),
                          onChanged: (x) => AppSettings.savePath = x,
                        ),
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      isExpanded: locationIsExpand,
                      headerBuilder: (context, d) {
                        return ListTile(
                          title: Text("${language.content.singlePagePostLoadLimit}"),
                        );
                      },
                      body: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text("${language.content.currentLimit}: ${AppSettings.postLimit.toInt()}"),
                            Slider(
                              value: AppSettings.postLimit,
                              onChanged: (value) {
                                setState(() {
                                  AppSettings.postLimit = value;
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
