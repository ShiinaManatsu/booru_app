import 'package:floating_search_bar/floating_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/yande/post.dart';

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
  double top=0;
  double topTarget=0;

  _PostViewPageState(){    
    Observable.timer((){},Duration(milliseconds: 10))
    .listen((x){
      setState(() {
        top=topTarget;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.post.id);
    return Scaffold(
      extendBody: true,
      body: Stack(children: <Widget>[
        PhotoViewGallery(
          backgroundDecoration: BoxDecoration(color: Colors.white),
          pageOptions: [
            PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.post.sampleUrl),
                heroAttributes: PhotoViewHeroAttributes(tag: widget.post))
          ],
        ),
        _buildBar(context),
      ]),
    );
  }

  AnimatedPositioned _buildBar(BuildContext context) {
    topTarget=20 + MediaQuery.of(context).padding.vertical;
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
        height: barHeight,
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
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
              child: Icon(Icons.search),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: FlatButton(
              onPressed: () {},
              child: Icon(Icons.search),
            ),
          ),
        ]),
      ),
    );
  }
}
