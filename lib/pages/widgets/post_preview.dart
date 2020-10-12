import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:booru_app/pages/setting_page.dart';
import 'package:booru_app/router.gr.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';

double postPreviewBorder = 2;

class PostPreview extends StatefulWidget {
  final Post post;
  PostPreview({this.post});

  @override
  _PostPreviewState createState() => _PostPreviewState();
}

class _PostPreviewState extends State<PostPreview>
    with AutomaticKeepAliveClientMixin {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    String url;
    switch (AppSettings.previewQuality) {
      case PreviewQuality.Low:
        url = widget.post.previewUrl;
        break;
      case PreviewQuality.Medium:
        url = widget.post.sampleUrl;
        break;
      case PreviewQuality.High:
        url = widget.post.jpegUrl;
        break;
      case PreviewQuality.Original:
        url = widget.post.fileUrl;
        break;
      default:
    }

    super.build(context);
    return MouseRegion(
      onEnter: (event) => setState(() => _isHover = true),
      onExit: (event) => setState(() => _isHover = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        curve: Curves.ease,
        decoration: BoxDecoration(
          border: Border.all(
              color: !_isHover ? Colors.black12 : Colors.pink,
              width: !AppSettings.masonryGrid ? postPreviewBorder : 0),
        ),
        child: GestureDetector(
          onTap: () => ExtendedNavigator.root.push(Routes.postViewPage,
              arguments: PostViewPageArguments(post: widget.post)),
          child: Hero(
            tag: widget.post,
            // child: Image.network(
            //   url ?? widget.post.sampleUrl,
            //   height: AppSettings.fixedPostHeight - postPreviewBorder * 2,
            //   width: widget.post.widthInPanel - postPreviewBorder * 2,
            //   fit: BoxFit.cover,
            //   loadingBuilder: (context, child, progress) =>
            //       progress == null ? child : CircularProgressIndicator(),
            // ),
            child: !AppSettings.masonryGrid
                ? Image(
                    image: !Platform.isWindows
                        ? CachedNetworkImageProvider(url)
                        : Image.network(url).image,
                    height: AppSettings.fixedPostHeight - postPreviewBorder * 2,
                    width: widget.post.widthInPanel - postPreviewBorder * 2,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Center(child: CircularProgressIndicator()),
                  )
                : Image(
                    image: !Platform.isWindows
                        ? CachedNetworkImageProvider(url)
                        : Image.network(url).image,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Center(child: CircularProgressIndicator()),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
