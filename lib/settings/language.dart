import 'dart:io';

import 'package:devicelocale/devicelocale.dart';

class Language {
  LanguageCodes language = LanguageCodes.en_uk;

  Content get content {
    switch (language) {
      case LanguageCodes.zh_cn:
        return ZhCN();
        break;
      case LanguageCodes.zh_hk:
        return ZhHk();
        break;
      default:
        return EN();
        break;
    }
  }

  getLanguage() {
    if (Platform.isWindows) return;

    Devicelocale.currentLocale.then((locale) {
      if (locale.contains(LanguageMap[LanguageCodes.zh_cn])) {
        language = LanguageCodes.zh_cn;
      } else if (locale.contains(LanguageMap[LanguageCodes.zh_hk])) {
        language = LanguageCodes.zh_hk;
      } else {
        language = LanguageCodes.en_uk;
      }
    });
  }

  Language() {
    getLanguage();
  }
}

/// Language string definitions
abstract class Content {
  /// models/rx/task_bloc
  String get finishedDownload;
  String get post;
  String get downloaded;

  /// pages/widgets/login_box
  String get username;
  String get password;
  String get login;

  /// pages/widgets/sliver_post_waterfall_widget
  String get loading;
  String get nothingToShow;

  /// pages/home_page
  String get popularByWeek;
  String get posts;
  String get search;
  String get popularPosts;
  String get popularPostsByRecent;
  String get popularPostsByDay;
  String get popularPostsByWeek;
  String get popularPostsByMonth;
  String get others;
  String get settings;
  String get about;
  String get last24h;
  String get week;
  String get month;
  String get year;

  /// pages/post_view_page
  String get shareTo;
  String get id;
  String get size;
  String get fileSize;
  String get author;
  String get score;
  String get tags;
  String get rating;
  String get source;
  String get noSource;
  String get comments;
  String get expand;
  String get back;

  /// pages/search_tagged_posts_page
  String get searchTags;

  /// pages/setting_page
  String get download;
  String get location;
  String get newLocationHere;
  String get singlePagePostLoadLimit;
  String get currentLimit;
  String get select;
  String get folder;
  String get preview;
  String get quality;
  String get safe;
  String get mode;
}

class ZhCN implements Content {
  /// models/rx/task_bloc
  @override
  String get finishedDownload => "下载完成";
  @override
  String get post => "图帖";
  @override
  String get downloaded => "已下载";

  /// pages/widgets/login_box
  @override
  String get username => "账户名";
  @override
  String get password => "密码";
  @override
  String get login => "登录";

  /// pages/widgets/sliver_post_waterfall_widget
  @override
  String get loading => "正在加载";
  @override
  String get nothingToShow => "没有什么可显示";

  /// pages/home_page
  @override
  String get popularByWeek => "本周最瑟";
  @override
  String get posts => "图帖";
  @override
  String get search => "搜索";
  @override
  String get popularPosts => "流行图帖";
  @override
  String get popularPostsByRecent => "最新";
  @override
  String get popularPostsByDay => "今天";
  @override
  String get popularPostsByWeek => "本周";
  @override
  String get popularPostsByMonth => "本月";
  @override
  String get others => "其他";
  @override
  String get settings => "设置";
  @override
  String get about => "关于";
  @override
  String get last24h => "最近一天";
  @override
  String get week => "本周";
  @override
  String get month => "本月";
  @override
  String get year => "今年";

  /// pages/post_view_page
  @override
  String get shareTo => "分享到";
  @override
  String get id => "ID";
  @override
  String get size => "尺寸";
  @override
  String get fileSize => "原图大小";
  @override
  String get author => "作者";
  @override
  String get score => "评分";
  @override
  String get tags => "标签";
  @override
  String get rating => "评级";
  @override
  String get source => "来源";
  @override
  String get noSource => "没有来源";
  @override
  String get comments => "评论";
  @override
  String get expand => "展开";
  @override
  String get back => "收起";

  /// pages/search_tagged_posts_page
  @override
  String get searchTags => "搜索标签";

  /// pages/setting_page
  @override
  String get download => "下载";
  @override
  String get location => "位置";
  @override
  String get newLocationHere => "新的位置";
  @override
  String get singlePagePostLoadLimit => "图片单页加载数量";
  @override
  String get currentLimit => "当前数量";
  @override
  String get select => "选择";
  @override
  String get folder => "文件夹";
  @override
  String get preview => "预览";
  @override
  String get quality => "质量";
  @override
  String get safe => "安全";
  @override
  String get mode => "模式";
}

class ZhHk implements Content {
  /// models/rx/task_bloc
  @override
  String get finishedDownload => "";
  @override
  String get post => "";
  @override
  String get downloaded => "";

  /// pages/widgets/login_box
  @override
  String get username => "";
  @override
  String get password => "";
  @override
  String get login => "";

  /// pages/widgets/sliver_post_waterfall_widget
  @override
  String get loading => "";
  @override
  String get nothingToShow => "沒有什麼可顯示";

  /// pages/home_page
  @override
  String get popularByWeek => "";
  @override
  String get posts => "";
  @override
  String get search => "";
  @override
  String get popularPosts => "";
  @override
  String get popularPostsByRecent => "";
  @override
  String get popularPostsByDay => "";
  @override
  String get popularPostsByWeek => "";
  @override
  String get popularPostsByMonth => "";
  @override
  String get others => "";
  @override
  String get settings => "";
  @override
  String get about => "";
  @override
  String get last24h => "";
  @override
  String get week => "";
  @override
  String get month => "";
  @override
  String get year => "";

  /// pages/post_view_page
  @override
  String get shareTo => "";
  @override
  String get id => "ID";
  @override
  String get size => "尺寸";
  @override
  String get fileSize => "";
  @override
  String get author => "";
  @override
  String get score => "";
  @override
  String get tags => "";
  @override
  String get rating => "";
  @override
  String get source => "";
  @override
  String get noSource => "";
  @override
  String get comments => "";
  @override
  String get expand => "";
  @override
  String get back => "";

  /// pages/search_tagged_posts_page
  @override
  String get searchTags => "";

  /// pages/setting_page
  @override
  String get download => "";
  @override
  String get location => "";
  @override
  String get newLocationHere => "";
  @override
  String get singlePagePostLoadLimit => "";
  @override
  String get currentLimit => "";
  @override
  String get select => "選擇";
  @override
  String get folder => "文件夾";
  @override
  String get preview => "預覽";
  @override
  String get quality => "質量";
  @override
  String get safe => "安全";
  @override
  String get mode => "模式";
}

class EN implements Content {
  /// models/rx/task_bloc
  @override
  String get finishedDownload => "Finished download";
  @override
  String get post => "Post";
  @override
  String get downloaded => "downloaded";

  /// pages/widgets/login_box
  @override
  String get username => "Username";
  @override
  String get password => "Password";
  @override
  String get login => "Login";

  /// pages/widgets/sliver_post_waterfall_widget
  @override
  String get loading => "Loading";
  @override
  String get nothingToShow => "Nothing to show..";

  /// pages/home_page
  @override
  String get popularByWeek => "Popular By Week";
  @override
  String get posts => "Posts";
  @override
  String get search => "Search";
  @override
  String get popularPosts => "Popular Posts";
  @override
  String get popularPostsByRecent => "Popular posts by recent";
  @override
  String get popularPostsByDay => "Popular posts by day";
  @override
  String get popularPostsByWeek => "Popular posts by week";
  @override
  String get popularPostsByMonth => "Popular posts by month";
  @override
  String get others => "Others";
  @override
  String get settings => "Settings";
  @override
  String get about => "About";
  @override
  String get last24h => "Last 24h";
  @override
  String get week => "Week";
  @override
  String get month => "Month";
  @override
  String get year => "Year";

  /// pages/post_view_page
  @override
  String get shareTo => "Share to";
  @override
  String get id => "ID";
  @override
  String get size => "Size";
  @override
  String get fileSize => "File Size";
  @override
  String get author => "Author";
  @override
  String get score => "Score";
  @override
  String get tags => "Tags";
  @override
  String get rating => "Rating";
  @override
  String get source => "Source";
  @override
  String get noSource => "No source";
  @override
  String get comments => "Comments";
  @override
  String get expand => "Expand";
  @override
  String get back => "Back";

  /// pages/search_tagged_posts_page
  @override
  String get searchTags => "Search tags";

  /// pages/setting_page
  @override
  String get download => "Download";
  @override
  String get location => "Location";
  @override
  String get newLocationHere => "New location here";
  @override
  String get singlePagePostLoadLimit => "Single page post load limit";
  @override
  String get currentLimit => "Current Limit";
  @override
  String get select => "Select";
  @override
  String get folder => "Folder";
  @override
  String get preview => "Preview";
  @override
  String get quality => "Quality";
  @override
  String get safe => "Safe";
  @override
  String get mode => "Mode";
}

const Map<LanguageCodes, String> LanguageMap = {
  LanguageCodes.zh_cn: "zh_CN",
  LanguageCodes.zh_hk: "zh_HK",
  LanguageCodes.en_uk: "en"
};

enum LanguageCodes { zh_cn, zh_hk, en_uk }
