import 'dart:core';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/pages/home_page.dart';
import 'package:rxdart/rxdart.dart';
// We are moving all the fetched post to the optimized list

/*
  TODO: Extend 1px if posts in each row does not fill completely
*/

extension ListExtension on List<Post> {
  Future<List<Post>> arrange() async {
    if (this.length == 0) {
      return List<Post>();
    }

    List<Post> posts = List<Post>.from(this);
    List<List<Post>> fixedPosts = List<List<Post>>();
    List<Post> row;

    var panelRatio = panelWidth / AppSettings.fixedPostHeight;
    const double maxRatioFactor = 0.5; // Allow width overflow with extra ratio

    if (fixedPosts.length == 0) {
      fixedPosts.add(new List<Post>());
    }

    while (posts.length != 0) {
      row = fixedPosts.last;
      double rowSumRatio = 0;
      row.forEach((item) {
        rowSumRatio += item.ratio;
      });

      // If row can contain more
      if ((posts.first.ratio + rowSumRatio) < (panelRatio + maxRatioFactor)) {
        row.add(posts.first);
        posts.removeAt(0);
      }

      // If row overflow, add row to the new posts list and make new one
      else {
        var flex = <double>[]; // New rule
        var fixedPanelWidth =
            panelWidth - 4 * (row.length - 1); // New rule, 4 is the run space
        double sumWidth = 0;
        row.forEach((item) {
          sumWidth += item.width;
        });
        row.forEach((item) {
          flex.add(item.width / sumWidth);
        });

        row.forEach((item) {
          item.widthInPanel = (fixedPanelWidth * flex[row.indexOf(item)]);
          // widthChecker += item.widthInPanel;
        });

        row.last.widthInPanel = row.last.widthInPanel.floorToDouble();

        fixedPosts.add(new List<Post>());
        row = fixedPosts.last;
        row.add(posts.first);
        posts.removeAt(0);
      }
    }
    //print("Arrange width:$panelWidth");
    row.clear();
    var list = new List<Post>();
    fixedPosts.forEach((x) {
      x.forEach((f) {
        list.add(f);
      });
    });
    return await Future.value(list);
  }
}
