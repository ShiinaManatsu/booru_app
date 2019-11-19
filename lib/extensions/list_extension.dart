import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/settings/app_settings.dart';
// We are moving all the fetched post to the optimized list

extension ListExtension on List<List<Post>> {
  void addAllPost(List<Post> posts,double panelWidth,) 
  {
    var panelRatio = panelWidth / AppSettings.fixedPostHeight;
    double ratioFactor = 0.7;
    if(this.length==0){
      this.add(new List<Post>());
    }
    List<Post> row;
    while (posts.length != 0) {
      row = this.last;
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
        this.add(new List<Post>());
        row = this.last;
        row.add(posts.first);
        posts.removeAt(0);
      }
    }
  }
}
