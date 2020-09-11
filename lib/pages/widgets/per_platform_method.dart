import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerPlatform extends StatefulWidget {
  final Widget android;
  final Widget windows;
  final Widget web;

  PerPlatform({this.android, this.windows, this.web});

  @override
  _PerPlatformState createState() => _PerPlatformState();
}

class _PerPlatformState extends State<PerPlatform> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return widget.web == null ? Container() : widget.web;
    } else if (Platform.isAndroid) {
      return widget.android;
    } else {
      return widget.windows;
    }
  }
}
