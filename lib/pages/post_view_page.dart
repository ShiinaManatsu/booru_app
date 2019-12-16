import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/yande/comment.dart';
import 'package:yande_web/models/yande/post.dart';

class PostViewPage extends StatefulWidget {
  @required
  final Post post;

  PostViewPage({this.post});

  @override
  _PostViewPageState createState() => _PostViewPageState();
}

class _PostViewPageState extends State<PostViewPage> {
  PublishSubject _onPanelExit = PublishSubject();
  PublishSubject<int> _postID = PublishSubject<int>();
  Stream<List<Comment>> _comments;
  int buttonCount = 3;
  double barHeight = 64;

  //List<Comment> _comments = new List<Comment>();

  @override
  void initState() {
    super.initState();
    _comments = _postID.distinct().switchMap<List<Comment>>((x) async* {
      yield await BooruAPI.fetchPostsComments(postID: widget.post.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    PanelController controller = PanelController();
    return Scaffold(
        drawerEdgeDragWidth: 100,
        drawer: Drawer(
          child: MouseRegion(
              onExit: (x) => _onPanelExit.add(null),
              child: _buildSlidingPanelContent()),
        ),
        extendBody: true,
        body: Builder(builder: (context) {
          _onPanelExit
              .throttleTime(Duration(milliseconds: 500))
              .takeWhile((x) => Scaffold.of(context).isDrawerOpen)
              .listen((x) => Navigator.pop(context));
          return Stack(children: <Widget>[
            buildHoverDrawer(Scaffold.of(context)),
            SlidingUpPanel(
                controller: controller,
                backdropColor: Colors.black,
                backdropOpacity: 0.5,
                minHeight: 60,
                maxHeight: 800,
                parallaxEnabled: true,
                backdropEnabled: true,
                // When coollapsed
                collapsed: Center(
                    child: Text(
                  widget.post.id.toString(),
                  style: TextStyle(fontSize: 25),
                )),
                panel: _buildSlidingPanelContent(),
                body: _buildmobileGallery()),
          ]);
        }));
  }

  Widget buildHoverDrawer(ScaffoldState scaffold) {
    return Container(
        alignment: Alignment.centerLeft,
        width: 50,
        child: Flex(
          direction: Axis.vertical,
          children: <Widget>[
            Expanded(
              child: MouseRegion(
                onEnter: (x) => scaffold.openDrawer(),
              ),
            ),
          ],
        ));
  }

  Widget _buildSlidingPanelContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Container(
        margin: EdgeInsets.fromLTRB(30, 50, 30, 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(
              builder: (context, constraints) => Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                width: buttonCount * barHeight,
                alignment: Alignment.center,
                height: barHeight,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border(
                        bottom: BorderSide(color: Colors.black26, width: 1),
                        left: BorderSide(color: Colors.black26, width: 1),
                        right: BorderSide(color: Colors.black26, width: 1),
                        top: BorderSide(color: Colors.black26, width: 1))),
                child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1,
                    child: FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1,
                    child: FlatButton(
                      onPressed: () => _launchURL(widget.post.fileUrl == ""
                          ? widget.post.jpegUrl
                          : widget.post.fileUrl),
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
            ),
            //------------------
            _buildTitleSpliter(Text(
              "Size",
              style: TextStyle(fontSize: 20),
            )),
            Text("${widget.post.width}x${widget.post.height}"),
            _buildTitleSpliter(Text(
              "Author",
              style: TextStyle(fontSize: 20),
            )),
            Text("${widget.post.author}"),
            _buildTitleSpliter(Text(
              "Score",
              style: TextStyle(fontSize: 20),
            )),
            Text("${widget.post.score}"),
            _buildTitleSpliter(Text(
              "Tags",
              style: TextStyle(fontSize: 20),
            )),
            Text(
              "${widget.post.tags}",
            ),
            _buildTitleSpliter(Text(
              "Rating",
              style: TextStyle(fontSize: 20),
            )),
            Text("${widget.post.rating.toString()}"),
            // Source link
            _buildTitleSpliter(Text(
              "Source",
              style: TextStyle(fontSize: 20),
            )),
            RichText(
              text: new TextSpan(
                text: widget.post.sourceUrl == ""
                    ? "No source"
                    : widget.post.sourceUrl,
                style: new TextStyle(color: Colors.blue),
                recognizer: new TapGestureRecognizer()
                  ..onTap = () {
                    _launchURL(widget.post.sourceUrl);
                  },
              ),
            ),

            _buildTitleSpliter(Text(
              "Comments",
              style: TextStyle(fontSize: 20),
            )),
            StreamBuilder<List<Comment>>(
              stream: _comments,
              initialData: List<Comment>()..add(Comment(isEmpty: true)),
              builder: (context, snapshot) {
                return Column(
                  children: List.generate(snapshot.data.length, (index) {
                    if (snapshot.data[index].isEmpty) {
                      return Container();
                    } else {
                      return Row(
                        children: <Widget>[
                          Text(
                            "${snapshot.data[index].creator}: ",
                          ),
                          Text(
                            snapshot.data[index].body,
                          ),
                        ],
                      );
                    }
                  }),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSpliter(Widget title) {
    return Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
        alignment: Alignment.centerLeft,
        child: title);
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
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
              maxScale: 1.0,
              imageProvider: NetworkImage(widget.post.sampleUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: widget.post))
        ],
      ),
    );
  }
}
