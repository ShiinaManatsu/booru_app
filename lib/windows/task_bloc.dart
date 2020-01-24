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

  /// Fire when download progress changed
  final PublishSubject progressUpdate;

  /// Fire when download completed
  final PublishSubject progressCompleteUpdate;

  /// Raise a event that going to remove a task
  final PublishSubject<DownloadTask> removeTask;

  /// First time this start
  //final PublishSubject startUp;

  /// Access the all task list
  final Stream<List<DownloadTask>> tasks;

  static List<DownloadTask> tasksList = List<DownloadTask>();

  factory TaskBloc() {
    final addDownload = PublishSubject<Post>();
    final progressUpdate = PublishSubject();
    final progressCompleteUpdate = PublishSubject();
    final removeTask = PublishSubject<DownloadTask>();
    // final startUp=Observable.empty();  // Currently this has nothing to do, TODO: need implements

    var downloadTask = addDownload.distinctUnique().map<DownloadTask>((x) {
      var task = DownloadTask.fromDownload(x);
      tasksList.add(task);
      return task;
    }).switchMap<List<DownloadTask>>((x) async* {
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var updateThrottled =
        progressUpdate.throttleTime(Duration(milliseconds: 500));
    var update = updateThrottled.mergeWith(
        [progressCompleteUpdate]).switchMap<List<DownloadTask>>((x) async* {
      print("Progress Updated");
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var remove = removeTask
        .asBroadcastStream()
        .interval(Duration(seconds: 3))
        .switchMap<List<DownloadTask>>((x) async* {
      print(tasksList);
      tasksList.remove(x);
      print(tasksList.contains(x));
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var tasks = downloadTask.mergeWith([update, remove]).asBroadcastStream();

    Observable.timer(() {}, Duration(seconds: 1)).listen((_) => showOverlay(
            (context, t) {
          return AnimatedOverlay(value: t);
        },
            key: ValueKey('hello'),
            curve: Curves.ease,
            duration: Duration.zero));

    return TaskBloc._(
        addDownload, progressUpdate, progressCompleteUpdate, removeTask, tasks);
  }

  void dispose() {
    progressUpdate.close();
    addDownload.close();
    removeTask.close();
    //startUp.close();
  }

  TaskBloc._(this.addDownload, this.progressUpdate, this.progressCompleteUpdate,
      this.removeTask, this.tasks);
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
  _download(Downloadable task) {
    // Factory the name and the state add to state list
    var fileName = Uri.decodeFull(task.url).split('/').last;
    filePath = 'D:/$fileName'; //'${path.path}/$fileName';

    Dio().download(task.url, filePath,
        onReceiveProgress: (int download, int total) {
      downloadedLength = download;
      totalLength = total;
      taskBloc.progressUpdate.add(null);
    }).then((_) {
      isDownloaded = true;
      taskBloc.removeTask.add(this);
      taskBloc.progressCompleteUpdate.add(null);
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
