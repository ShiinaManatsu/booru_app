import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
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
                padding: const EdgeInsets.symmetric(vertical: 12),
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FlatButton(
                  child: Text("Test FOO"),
                  onPressed: () {
                    showOverlayNotification((context) => MessageNotification(
                          onReplay: () {
                            OverlaySupportEntry.of(context)
                                .dismiss(); //use OverlaySupportEntry to dismiss overlay
                            toast('you checked this message');
                          },
                        ));
                  },
                ),
              )
            ]),
          ),
        ],
      ),
    );
  }
}

class MessageNotification extends StatelessWidget {
  final VoidCallback onReplay;

  const MessageNotification({Key key, this.onReplay}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: SafeArea(
        child: ListTile(
          leading: SizedBox.fromSize(
              size: const Size(40, 40),
              child: CircleAvatar(
                backgroundColor: Colors.amber,
              )),
          title: Text('Lily MacDonald'),
          subtitle: Text('Do you want to see a movie?'),
          trailing: IconButton(
              icon: Icon(Icons.reply),
              onPressed: () {
                ///TODO i'm not sure it should be use this widget' BuildContext to create a Dialog
                ///maybe i will give the answer in the future
                if (onReplay != null) onReplay();
              }),
        ),
      ),
    );
  }
}
