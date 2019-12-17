import 'dart:io';
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
  double panelHandlerWidth = 100;
  double commentsPanelWidth = 300;
  PhotoViewController _galleryController = PhotoViewController();

  // Top-Right panel usage
  /// Open panel when is `ture`, otherwise, close it
  PublishSubject<PanelArg> _onTopRightPanel = PublishSubject<PanelArg>();

  double _panelStartOffset;
  double _panelOffset;
  double _panelContentOffset;
  double _offset;
  bool _isPanelOpen = false;
  bool _isContentPanelOpen = false;

  // Top-Right panel usage

  @override
  void initState() {
    super.initState();
    _panelStartOffset = -(barHeight * 3 + commentsPanelWidth);
    _panelOffset = _panelStartOffset + barHeight * 3;
    _panelContentOffset = _panelOffset + commentsPanelWidth;
    _offset = _panelStartOffset;
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
          if (Platform.isAndroid || Platform.isIOS) {
            return Stack(
              children: <Widget>[
                SlidingUpPanel(
                    controller: controller,
                    backdropColor: Colors.black,
                    backdropOpacity: 0.5,
                    minHeight: 60,
                    maxHeight: 800,
                    parallaxEnabled: true,
                    backdropEnabled: true,
                    // When coollapsed
                    collapsed: Column(
                      children: <Widget>[
                        Center(
                            child: Text(
                          widget.post.id.toString(),
                          style: TextStyle(fontSize: 25),
                        )),
                      ],
                    ),
                    panel: _buildSlidingPanelContent(),
                    body: _buildGallery()),
              ],
            );
          } else {
            return Stack(children: <Widget>[
              _buildGallery(),
              //_buildHoverDrawer(Scaffold.of(context)), // Left hover
              _buildTopRightPanel(MediaQuery.of(context).size.height),
            ]);
          }
        }));
  }

  Widget _buildTopRightPanel(double height) {
    bool isLeaving = false;
    return AnimatedPositioned(
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
      right: _offset - 1,
      child: Container(
        alignment: Alignment.centerLeft,
        height: height,
        child: Row(
          children: <Widget>[
            // Left
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  child: MouseRegion(
                    onEnter: (x) {
                      if (!_isPanelOpen && !_isContentPanelOpen) {
                        setState(() {
                          _offset = _panelOffset;
                        });
                        _isPanelOpen = true;
                        isLeaving = false;
                      }
                    },
                    onExit: (x) {
                      if (_isPanelOpen && !_isContentPanelOpen) {
                        setState(() {
                          _offset = _panelStartOffset;
                        });
                        _isPanelOpen = false;
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        // Handle hover
                        Container(
                          height: barHeight,
                          width: panelHandlerWidth,
                        ),
                        //Basic function button group
                        Container(
                          clipBehavior: Clip.antiAlias,
                          width: buttonCount * barHeight,
                          alignment: Alignment.center,
                          height: barHeight,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(32.0)),
                              color: Colors.white70),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(32.0))),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _buildQuadIconButton(
                                      () => Navigator.pop(context),
                                      Icon(Icons.arrow_back)),
                                  _buildQuadIconButton(
                                      () => _launchURL(widget.post.fileUrl == ""
                                          ? widget.post.jpegUrl
                                          : widget.post.fileUrl),
                                      Icon(Icons.file_download)),
                                  _buildQuadIconButton(
                                      () {}, Icon(Icons.favorite_border)),
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content handler
                Container(
                  height: MediaQuery.of(context).size.height - barHeight - 10,
                  child: MouseRegion(
                    onEnter: (x) {
                      if (!_isContentPanelOpen && !isLeaving) {
                        setState(() {
                          _offset = _panelContentOffset;
                        });
                        _isContentPanelOpen = true;
                      }
                    },
                    child: Container(
                      width: 100,
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(color: Colors.white70),
              child: MouseRegion(
                onExit: (x) {
                  if (_isContentPanelOpen) {
                    setState(() {
                      _offset = _panelStartOffset;
                    });
                    isLeaving = true;
                    _isContentPanelOpen = false;
                  }
                },
                child: Container(
                  width: commentsPanelWidth,
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    child: _buildSlidingPanelContent(),
                    physics: BouncingScrollPhysics(),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
    ;
  }

  AspectRatio _buildQuadIconButton(Function onPressed, Widget child) {
    return AspectRatio(
      aspectRatio: 1,
      child: FlatButton(onPressed: onPressed, child: child),
    );
  }

  Widget _buildHoverDrawer(ScaffoldState scaffold) {
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

  Widget _buildGallery() {
    return Container(
      margin: EdgeInsets.only(bottom: 60),
      child: PhotoViewGallery(
        enableRotation: true,
        backgroundDecoration: BoxDecoration(color: Colors.white),
        pageOptions: [
          PhotoViewGalleryPageOptions(
              controller: _galleryController,
              maxScale: 1.0,
              imageProvider: NetworkImage(widget.post.sampleUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: widget.post))
        ],
      ),
    );
  }
}

class PanelArg {
  PanelState panelState;
}

class OpenPanelArg extends PanelArg {
  final panelState;
  OpenPanelArg({@required this.panelState});
}

class OpenCommentPanelArg extends PanelArg {
  final panelState;
  OpenCommentPanelArg({@required this.panelState});
}

enum PanelState { Open, Close }
