import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class UpdateDialog extends StatefulWidget {
  final key;
  final version;
  final Function onClickWhenNotDownload;
  final CancelToken cancleToken;

  UpdateDialog(
      {this.key, this.version, this.onClickWhenNotDownload, this.cancleToken});

  @override
  State<StatefulWidget> createState() => UpdateDialogState();
}

class UpdateDialogState extends State<UpdateDialog> {
  double _downloadProgress = 0.0;

  bool updateButtonEnable = true;

  @override
  Widget build(BuildContext context) {
    var _textStyle =
        TextStyle(color: Theme.of(context).textTheme.bodyText2.color);

    return AlertDialog(
      title: Text(
        " Updates", //#TN
        style: _textStyle,
      ),
      content: _downloadProgress == 0.0
          ? Text(
              "Version ${widget.version}", //#TN
              style: _textStyle,
            )
          : LinearProgressIndicator(
              value: _downloadProgress,
            ),
      actions: <Widget>[
        FlatButton(
          child: Text(
            'Update', //#TN
            style: _textStyle,
          ),
          onLongPress: null,
          onPressed: updateButtonEnable
              ? () {
                  setState(() {
                    updateButtonEnable = false;
                    _downloadProgress = null;
                  });
                  widget.onClickWhenNotDownload();
                }
              : null,
        ),
        FlatButton(
          child: Text('Cancel'), //#TN
          onPressed: () {
            Navigator.of(context).pop();
            if (widget.cancleToken != null) widget.cancleToken.cancel("Cancelled");
          },
        ),
      ],
    );
  }

  set progress(_progress) {
    setState(() {
      _downloadProgress = _progress;
      if (_downloadProgress == 1) {
        Navigator.of(context).pop();
        _downloadProgress = 0.0;
      }
    });
  }
}
