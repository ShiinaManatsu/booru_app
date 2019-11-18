import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yande_web/themes/theme_light.dart';

// Search box in the app bar
class SearchBox extends StatefulWidget {
  String searchTerm = "";

  SearchBox({this.searchTerm, Key key}) : super(key: key);

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 40,
      //padding: EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        color: Color.fromARGB(255, 241, 243, 244),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
                Icons.search,
                size: 30,
                color: baseBlackColor,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left:10.0),
                child: TextField(
                  maxLines: 1,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search Sometings"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
