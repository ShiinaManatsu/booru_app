import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class LoginBox extends StatefulWidget {
  final Function loginCallback;

  LoginBox(this.loginCallback);

  @override
  _LoginBoxState createState() => _LoginBoxState();
}

class _LoginBoxState extends State<LoginBox> {
  String _username;
  String _password;
  bool _isChecking = false;

  PublishSubject<String> _addUser = PublishSubject<String>();

  @override
  void initState() {
    super.initState();
    _addUser
        .where((x) => !AppSettings.localUsers.contains((LocalUser x) =>
            x.username == _username &&
            x.clientType == AppSettings.currentClient))
        .listen((x) {
      AppSettings.localUsers
          .add(LocalUser(AppSettings.currentClient, _username, _password));
      widget.loginCallback();
    });
  }

  void dispose() {
    super.dispose();
    _addUser.close();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      children: <Widget>[
        Container(
          height: 200,
          width: 400,
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Username:",
                          style: TextStyle(fontSize: 24),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 12),
                          width: 200,
                          child: TextField(
                            style: TextStyle(fontSize: 24),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            onChanged: (value) => _username = value,
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Password:",
                          style: TextStyle(fontSize: 24),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 12),
                          width: 200,
                          child: TextField(
                            obscureText: true,
                            style: TextStyle(fontSize: 24),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                            onChanged: (value) => _password = value,
                          ),
                        )
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        _buildloginButton(() {
                          setState(() {
                            _isChecking = true;
                          });
                          votePost(postID: 606750, type: VoteType.None)
                              .then((onValue) {
                            setState(() {
                              _isChecking = false;
                              if (onValue) {
                                _addUser.add(_username);
                                Navigator.pop(context);
                              } else {
                                print("Not success");
                              }
                            });
                          });
                        }, "Login")
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  /// Fetch post comment
  Future<bool> votePost({@required int postID, @required VoteType type}) async {
    var token =
        "login=$_username&password_hash=${BooruAPI.getSha1Password(_password)}";
    var url =
        "${AppSettings.currentBaseUrl}/post/vote.json?$token&id=$postID&score=${type.index - 1}";
    http.Response response = await http.post(url);
    Map decodedJson = json.decode(response.body);
    return decodedJson["success"];
  }

  /// The button used in drawer
  Widget _buildloginButton(Function() onPressed, String text) {
    return Container(
      height: 48,
      child: FlatButton(
        onPressed: onPressed,
        highlightColor: Colors.pinkAccent,
        hoverColor: Colors.pink[50],
        child: _isChecking
            ? CircularProgressIndicator(
                value: null,
              )
            : Container(
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: TextStyle(fontSize: 24, color: Colors.black87),
                )),
      ),
    );
  }
}
