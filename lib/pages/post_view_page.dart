import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/models/yande/tags.dart';

class PostViewPage extends StatefulWidget {
  @required
  final Post post;

  PostViewPage({this.post});

  @override
  _PostViewPageState createState() => _PostViewPageState();
}

class _PostViewPageState extends State<PostViewPage> {
  int buttonCount = 3;
  double barHeight = 64;
  double top = 0;
  double topTarget = 0;

  _PostViewPageState() {
    Observable.timer(() {}, Duration(milliseconds: 10)).listen((x) {
      setState(() {
        top = topTarget;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(children: <Widget>[
        _buildMobelGallery(),
        _buildBar(context),
      ]),
    );
  }

  PhotoViewGallery _buildMobelGallery() {
    return PhotoViewGallery(
      backgroundDecoration: BoxDecoration(color: Colors.white),
      pageOptions: [
        PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(widget.post.sampleUrl),
            heroAttributes: PhotoViewHeroAttributes(tag: widget.post))
      ],
    );
  }

  AnimatedPositioned _buildBar(BuildContext context) {
    topTarget = 20 + MediaQuery.of(context).padding.vertical;
    return AnimatedPositioned(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeIn,
      top: top,
      left:
          (MediaQuery.of(context).size.width / 2 - barHeight * buttonCount / 2)
              .toDouble(),
      child: Container(
        margin: EdgeInsets.all(10),
        alignment: Alignment.center,
        height: barHeight,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 13,
                color: Colors.black45,
                spreadRadius: 3,
              )
            ]),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: FlatButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: FlatButton(
              onPressed: () {},
              child: Icon(Icons.file_download),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: FlatButton(
              onPressed: () {},
              child: Icon(Icons.favorite_border),
            ),
          ),
        ]),
      ),
    );
  }
}
