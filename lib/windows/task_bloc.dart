import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:booru_app/main.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/yande/post.dart';
import 'package:booru_app/pages/home_page.dart';
import 'package:booru_app/pages/widgets/task_overlay.dart';
import 'package:booru_app/settings/app_settings.dart';

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

    Rx.timer(() {}, Duration(seconds: 1)).listen((_) {
      if (Platform.isWindows) {
        showOverlay((context, t) {
          return AnimatedOverlay(value: t);
        }, key: ValueKey('hello'), curve: Curves.ease, duration: Duration.zero);
      }
    });

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
  _download(Downloadable task) async {
    // Factory the name and the state add to state list
    var fileName = Uri.decodeFull(task.url).split('/').last;

    if (Platform.isWindows) {
      if (!await Directory(AppSettings.savePath).exists()) {
        await Directory(AppSettings.savePath).create();
      }

      filePath = p.join(AppSettings.savePath, fileName);
    } else if (Platform.isAndroid) {
      var dir =
          (await getExternalStorageDirectories(type: StorageDirectory.pictures))
              .first
              .path;
      filePath = p.join(dir, fileName);
    }

    Dio().download(task.url, filePath,
        onReceiveProgress: (int download, int total) {
      downloadedLength = download;
      totalLength = total;
      taskBloc.progressUpdate.add(null);
    }).then((_) {
      isDownloaded = true;
      _showNotification(post.id, post.id.toString(), filePath);
      taskBloc.removeTask.add(this);
      taskBloc.progressCompleteUpdate.add(null);
    }).catchError((x) => taskBloc.removeTask.add(this));
  }

  /// Show a notification when download finished
  void _showNotification(int id, String text, String photoPath) {
    if (Platform.isAndroid) {
      notifier.sendNotificationWithBitmap(
          id, 'Finished download', 'Post $text downloaded', photoPath);
    }
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
