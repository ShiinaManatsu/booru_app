import 'dart:core';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:yande_web/pages/home_page.dart';
// We are moving all the fetched post to the optimized list

extension ListExtension on List<Post> {
  List<Post> arrange() 
  {
    List<Post> posts=List<Post>.from(this);
    this.clear();
    List<List<Post>> fixedPosts = List<List<Post>>();
    var panelRatio = panelWidth / AppSettings.fixedPostHeight;
    double ratioFactor = 0.7;
    if(fixedPosts.length==0){
      fixedPosts.add(new List<Post>());
    }
    List<Post> row;
    while (posts.length != 0) {
      row = fixedPosts.last;
      double rowSumRatio = 0;
      row.forEach((item) {
        rowSumRatio += item.ratio;
      });
      // Row can contain more
      if (posts.first.ratio + rowSumRatio < panelRatio + ratioFactor) {
        row.add(posts.first);
        posts.removeAt(0);
      }
      // Row overflow, add row to the new posts list and make new one
      else {
        double rowWidth = 0;
        row.forEach((item) {
          rowWidth += item.preferredWidth;
        });
        var remainWidth = panelWidth - rowWidth;
        var widthFactor = remainWidth / row.length; // Add to each one
        row.forEach((item) {
          item.widthInPanel = item.preferredWidth + widthFactor;
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
    return list;
  }
}
