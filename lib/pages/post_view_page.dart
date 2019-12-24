import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/yande/comment.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/models/yande/tags.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:expandable/expandable.dart';
import 'package:yande_web/main.dart';
import 'package:yande_web/android/post_downloader.dart';

class PostViewPage extends StatefulWidget {
  @required
  final Post post;

  PostViewPage({this.post});

  @override
  _PostViewPageState createState() => _PostViewPageState();
}

class _PostViewPageState extends State<PostViewPage>
    with TickerProviderStateMixin {
  PublishSubject _onPanelExit = PublishSubject();
  List<Comment> _comments = List<Comment>();
  int buttonCount = 3;
  double barHeight = 64;
  double panelHandlerWidth = 100;
  double commentsPanelWidth = 300;
  PhotoViewController _galleryController = PhotoViewController();

  // Top-Right panel usage

  double _panelStartOffset;
  double _panelOffset;
  double _panelContentOffset;
  double _offset;
  bool _isPanelOpen = false;
  bool _isContentPanelOpen = false;

  // Top-Right panel usage

  // Post Tags
  List<Tag> tags = List<Tag>();

  // Download usage
  DownloadStatus state;

  double get _progressValue => state.current / state.total;

  callback(DownloadStatus s) {
    if (mounted) {
      setState(() {
        state = s;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _panelStartOffset = -(barHeight * 3 + commentsPanelWidth);
    _panelOffset = _panelStartOffset + barHeight * 3;
    _panelContentOffset = _panelOffset + commentsPanelWidth;
    _offset = _panelStartOffset;
    widget.post.tags.split(" ").forEach((x) async {
      var res = await TagDataBase.searchTags(x);
      if (mounted) {
        setState(() {
          tags.add(res.firstWhere((f) => f.content == x));
        });
      }
    });
    BooruAPI.fetchPostsComments(postID: widget.post.id).then((x) {
      if (x != null) {
        if (mounted) {
          setState(() {
            _comments = x;
          });
        }
      }
    });

    // Download usage
    try {
      state = postDownloader.states
          .where((x) => x.id == widget.post.id && x.isDownload)
          .first;
      state.callback = callback;
    } catch (e) {
      state = DownloadStatus('', widget.post.id, callback: callback);
    }
  }

  @override
  Widget build(BuildContext context) {
    PanelController controller = PanelController();
    return Scaffold(
        extendBody: true,
        body: Builder(builder: (context) {
          _onPanelExit
              .throttleTime(Duration(milliseconds: 500))
              .takeWhile((x) => Scaffold.of(context).isDrawerOpen)
              .listen((x) => Navigator.pop(context));
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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
                    panel: _buildContentPanel(),
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
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
      right: _offset,
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
                                  _buildQuadIconButton(() {
                                    if (kIsWeb) {
                                      _launchURL(widget.post.fileUrl);
                                      return;
                                    } else {
                                      postDownloader.download(
                                          widget.post.fileUrl,
                                          widget.post.id,
                                          state);
                                    }
                                  }, Icon(Icons.file_download)),
                                  _buildQuadIconButton(() {
                                    _launchURL(
                                        "https://yande.re/post/show/${widget.post.id}");
                                  }, Icon(Icons.favorite_border)),
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
                    child: _buildContentPanel(),
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

  Widget _buildContentPanel() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        LinearProgressIndicator(
          value: state.isDownload ? state.current / state.total : 0,
          valueColor: AlwaysStoppedAnimation<Color>(
              state.isDownload ? Colors.blueAccent : Colors.pinkAccent),
        ),
        // Sub buttons
        Container(
          alignment: Alignment.centerLeft,
          height: barHeight,
          child: Container(
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              _buildQuadIconButton(
                  () => Clipboard.setData(ClipboardData(
                      text: "https://yande.re/post/show/${widget.post.id}")),
                  Icon(Icons.content_copy)),
              _buildQuadIconButton(() {
                postDownloader.download(
                    widget.post.fileUrl, widget.post.id, state);
              }, Icon(Icons.file_download)),
              Text(
                "${widget.post.id}",
                style: TextStyle(fontSize: 20),
              ),
            ]),
          ),
        ),
        SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Container(
            margin: EdgeInsets.all(30),
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
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                          "${AppSettings.currentBaseUrl}/data/avatars/${widget.post.creatorId}.jpg"),
                    ),
                    Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Text("${widget.post.author}")),
                  ],
                ),
                _buildTitleSpliter(Text(
                  "Score",
                  style: TextStyle(fontSize: 20),
                )),
                Text("${widget.post.score}"),
                _buildTitleSpliter(Text(
                  "Tags",
                  style: TextStyle(fontSize: 20),
                )),
                Wrap(
                  spacing: 3,
                  children: List.generate(
                    tags.length,
                    (index) => Chip(
                      label: Text(tags[index].content),
                      backgroundColor: TagToColorMap[tags[index].tagType],
                      deleteIcon: Icon(Icons.close),
                    ),
                  ),
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
                // Comments
                _buildExpandablePanel()
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandablePanel() {
    if (_comments.length == 0) {
      return Container();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
            _comments.length,
            (index) => Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(color: Colors.accents[index]),
                  child: ExpandableNotifier(
                    child: Column(
                      children: [
                        ExpandablePanel(
                          header: Column(
                            children: <Widget>[
                              Text(_comments[index].creator,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              Text(_comments[index].content),
                              ExpandableButton(
                                child: Text("Expand"),
                              ),
                            ],
                          ),
                          expanded: Column(children: [
                            ExpandableButton(
                              child: Text("Back"),
                            ),
                          ]),
                          hasIcon: false,
                          tapBodyToCollapse: true,
                          tapHeaderToExpand: true,
                        ),
                      ],
                    ),
                  ),
                )),
      );
    }
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
      //margin: EdgeInsets.only(bottom: 60),  // Phone use
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
