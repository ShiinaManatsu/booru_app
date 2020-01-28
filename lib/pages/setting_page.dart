import 'package:flutter/material.dart';
import 'package:yande_web/pages/widgets/sliver_floating_bar.dart';
import 'package:yande_web/settings/app_settings.dart';

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
            title: Text("Settings"),
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
                          title: Text("Download Location"),
                        );
                      },
                      body: ListTile(
                        title: Text("Location"),
                        subtitle: TextField(
                          decoration: InputDecoration(
                              prefixText: "New location here: ",
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
                          title: Text("Single page post load limit"),
                        );
                      },
                      body: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text("Current Limit: ${AppSettings.postLimit.toInt()}"),
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
