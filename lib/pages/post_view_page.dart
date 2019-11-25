import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yande_web/models/booru_posts.dart';
import 'package:yande_web/models/yande/comment.dart';
import 'package:yande_web/models/yande/post.dart';
//import 'dart:html' as html;

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

  List<Comment> _comments=new List<Comment>();

  @override
  void initState() {
    super.initState();
    BooruPosts.fetchPostsComments(postID: widget.post.id).then((x) {
      setState(() {
        _comments = x;
      });
    });
  }

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
        SlidingUpPanel(
            backdropColor: Colors.black,
            backdropOpacity: 0.5,
            minHeight: 60,
            backdropEnabled: true,
            // When coollapsed
            collapsed: Center(
                child: Text(
              widget.post.id.toString(),
              style: TextStyle(fontSize: 25),
            )),
            panel: _buildSlidingPanelContent(),
            body: _buildmobileGallery()),
        _buildBar(context),
      ]),
    );
  }

  Widget _buildSlidingPanelContent() {
    if (_comments.length == 0) {
      return Center(
        child: Text("Loading"),
      );
    } else {
      return Container(
        margin: EdgeInsets.fromLTRB(30,50,30,30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildTitleSpliter(Text("Size",style: TextStyle(fontSize: 20),)),
            Text("${widget.post.width}x${widget.post.height}"),
            _buildTitleSpliter(Text("Author",style: TextStyle(fontSize: 20),)),            
            Text("${widget.post.author}"),
            _buildTitleSpliter(Text("Score",style: TextStyle(fontSize: 20),)),
            Text("${widget.post.score}"),
            _buildTitleSpliter(Text("Rating",style: TextStyle(fontSize: 20),)),
            Text("${widget.post.rating.toString()}"),
            _buildTitleSpliter(Text("Source",style: TextStyle(fontSize: 20),)),
            RawMaterialButton(
              onPressed: () => _launchURL(widget.post.sourceUrl),
              //onPressed: ()=>l(widget.post.sourceUrl),
              child: Text(widget.post.sourceUrl),
            ),
            _buildTitleSpliter(Text("Comments",style: TextStyle(fontSize: 20),)),
            Text(_comments.first.isEmpty ? "No comments" : _comments.first.body),
          ],
        ),
      );
    }
  }

  Widget _buildTitleSpliter(Widget title){
    return Container(
      margin: EdgeInsets.only(top: 10),
      alignment: Alignment.centerLeft,
      child: title
    );
  }

  // Use for web
  // l(String url) {
  //   html.window.open(url, "link");

  // }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url,
          forceWebView: true, enableJavaScript: true, enableDomStorage: true);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildmobileGallery() {
    return Container(
      margin: EdgeInsets.only(bottom: 60),
      child: PhotoViewGallery(
        backgroundDecoration: BoxDecoration(color: Colors.white),
        pageOptions: [
          PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.post.sampleUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: widget.post))
        ],
      ),
    );
  }

  // Top floating bar
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
