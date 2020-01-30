import 'dart:core';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/pages/home_page.dart';
// We are moving all the fetched post to the optimized list

extension ListExtension on List<Post> {
  Future<List<Post>> arrange() async {
    List<Post> posts = List<Post>.from(this);
    List<List<Post>> fixedPosts = List<List<Post>>();
    var panelRatio = panelWidth / AppSettings.fixedPostHeight;
    const double maxRatioFactor = 1.2;

    if (fixedPosts.length == 0) {
      fixedPosts.add(new List<Post>());
    }
    List<Post> row;
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
        print("index:${fixedPosts.length}, count:${row.length}");
        var flex = []; // New rule
        double left = 1;
        var fixedPanelWidth = panelWidth - 4 * (row.length - 1);
        row.forEach((item) {
          var f = item.preferredWidth / fixedPanelWidth;
          flex.add(f); // New rule, 4 is the run space
          left -= f;
        });
        left /= row.length;
        row.forEach((item) {
          item.widthInPanel =
              (fixedPanelWidth * (flex[row.indexOf(item)] + left)).floorToDouble();
        });
        fixedPosts.add(new List<Post>());
        row = fixedPosts.last;
        row.add(posts.first);
        posts.removeAt(0);
      }
    }
    print("Arrange width:$panelWidth");
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
