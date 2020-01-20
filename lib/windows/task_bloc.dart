import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/pages/home_page.dart';
import 'package:yande_web/pages/widgets/task_overlay.dart';

class TaskBloc {
  /// Add new download task
  final PublishSubject<Post> addDownload;

  final PublishSubject progressUpdate;

  /// First time this start
  //final PublishSubject startUp;

  /// Access the all task list
  final Stream<List<DownloadTask>> tasks;

  static List<DownloadTask> tasksList = List<DownloadTask>();

  factory TaskBloc() {
    final addDownload = PublishSubject<Post>();
    final progressUpdate = PublishSubject();
    // final startUp=Observable.empty();  // Currently this has nothing to do, TODO: need implements

    var downloadTask = addDownload.distinctUnique().map<DownloadTask>((x) {
      var task = DownloadTask.fromDownload(x);
      tasksList.add(task);
      return task;
    }).switchMap<List<DownloadTask>>((x) async* {
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var update = progressUpdate.switchMap<List<DownloadTask>>((x) async* {
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var tasks = downloadTask.mergeWith([update]).asBroadcastStream();

    Observable.timer(() {}, Duration(seconds: 1)).listen((_) => showOverlay(
            (context, t) {
          return AnimatedOverlay(value: t);
        },
            key: ValueKey('hello'),
            curve: Curves.ease,
            duration: Duration.zero));

    return TaskBloc._(addDownload, progressUpdate, tasks);
  }

  void dispose() {
    progressUpdate.close();
    addDownload.close();
    //startUp.close();
  }

  TaskBloc._(this.addDownload, this.progressUpdate, this.tasks);
}

class DownloadTask {
  /// [post] is the file url.
  final Post post;

  /// [totalLength] is the request body length.
  /// [totalLength] will be -1 if the size of the response body is not known.
  int totalLength = 1;

  /// [downloadedLength] is the length of the bytes have been sent/received.
  int downloadedLength = 0;

  /// [filePath] path where this file locate
  String filePath;

  double get progress {
    if (isDownloaded) {
      return 1;
    } else if (totalLength == -1) {
      return null;
    } else {
      return downloadedLength / totalLength;
    }
  }

  /// Is file already downloaded
  bool isDownloaded = false;

  /// Download this file.
  _download(Downloadable task) async {
    // Factory the name and the state add to state list
    var fileName = Uri.decodeFull(task.url).split('/').last;
    filePath = 'D:/$fileName'; //'${path.path}/$fileName';

    await Dio().download(task.url, filePath,
        onReceiveProgress: (int download, int total) {
      downloadedLength = download;
      totalLength = total;
      taskBloc.progressUpdate.add(null);
    }).then((_) {
      isDownloaded = true;
    });
  }

  factory DownloadTask.fromID(String id) {
    var post;
    BooruAPI.fetchSpecficPost(id: id).then((x) => post = x);
    return DownloadTask._fromID(post);
  }

  DownloadTask.fromDownload(this.post) {
    _download(post);
  }

  DownloadTask._fromID(this.post) : isDownloaded = true;
}

/// Downloadable object
class Downloadable {
  final String url;
  Downloadable(this.url);
}
