import 'package:flutter/material.dart';
import 'package:floating_search_bar/ui/sliver_search_bar.dart';
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
                padding: const EdgeInsets.all(12),
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
                          //onChanged: (x) => AppSettings.savePath = x,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ]),
          ),
        ],
      ),
    );
  }
}
