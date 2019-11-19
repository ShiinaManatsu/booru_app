import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';

extension ListExtension on List<Post> {
  void addAllPost(List<Post> postList,double panelWidth,) 
  {
    var posts = List.from(postList);
    var panelRatio = panelWidth / AppSettings.fixedPostHeight;
    double ratioFactor = 0.5;
    var row = new List<Post>();
    var fixedPosts = new List<Post>();
    //print(panelWidth);
    while (posts.length != 0) {
      double rowSumRatio = 0;
      row.forEach((item) {
        rowSumRatio += item.ratio;
      });
      //print("${posts.first.ratio + rowSumRatio} + ${panelRatio + ratioFactor}");

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
          //print("$widthFactor pWidth: ${item.widthInPanel}  width:${item.preferredWidth}");
        });
        //print("${row.length}");
        fixedPosts.addAll(row);
        row.clear();
        row.add(posts.first);
        posts.removeAt(0);
      }
    }

    if (row.length != 0) {
      fixedPosts.addAll(row);
      row.clear();
    }
    this.clear();
    this.addAll(fixedPosts);
  }
}
