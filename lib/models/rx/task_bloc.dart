import 'dart:io';
import 'package:booru_app/models/yande/post.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:booru_app/main.dart';
import 'package:booru_app/models/rx/booru_api.dart';
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

  final PublishSubject<DownloadTask> cancelTask;

  /// First time this start
  //final PublishSubject startUp;

  /// Access the all task list
  final Stream<List<DownloadTask>> tasks;

  static List<DownloadTask> tasksList = List<DownloadTask>();

  static Map<int, CancelToken> cancelTokens = Map<int, CancelToken>();

  factory TaskBloc() {
    final addDownload = PublishSubject<Post>();
    final progressUpdate = PublishSubject();
    final progressCompleteUpdate = PublishSubject();
    final removeTask = PublishSubject<DownloadTask>();
    final cancelTask = PublishSubject<DownloadTask>();
    // final startUp=Observable.empty();  // Currently this has nothing to do, TODO: need implements

    var downloadTask = addDownload.distinct().map<DownloadTask>((x) {
      var task = DownloadTask.fromDownload(x);
      tasksList.add(task);
      cancelTokens[x.id] = CancelToken();
      return task;
    }).switchMap<List<DownloadTask>>((x) async* {
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var updateThrottled =
        progressUpdate.throttleTime(Duration(milliseconds: 500));
    var update = updateThrottled.mergeWith(
        [progressCompleteUpdate]).switchMap<List<DownloadTask>>((x) async* {
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var remove = removeTask
        .distinct()
        .asBroadcastStream()
        .interval(Duration(seconds: 3))
        .switchMap<List<DownloadTask>>((x) async* {
      tasksList.remove(x);
      cancelTokens.remove(x.post);
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var cancel = cancelTask
        .asBroadcastStream()
        .switchMap<List<DownloadTask>>((x) async* {
      print("Canceled");
      cancelTokens[x.post.id].cancel();
      cancelTokens.remove(x.post.id);
      x.cancel();
      taskBloc.removeTask.add(x);
      taskBloc.progressCompleteUpdate.add(null);
      yield tasksList;
    }).startWith(List<DownloadTask>());

    var tasks =
        downloadTask.mergeWith([update, remove, cancel]).asBroadcastStream();

    Rx.timer(null, Duration(seconds: 1)).listen((_) {
      if (Platform.isWindows) {
        showOverlay((context, t) {
          return AnimatedOverlay(value: t);
        }, key: ValueKey('hello'), curve: Curves.ease, duration: Duration.zero);
      }
    });

    return TaskBloc._(
        addDownload: addDownload,
        cancelTask: cancelTask,
        progressCompleteUpdate: progressCompleteUpdate,
        progressUpdate: progressUpdate,
        removeTask: removeTask,
        tasks: tasks);
  }

  void dispose() {
    addDownload.close();
    progressUpdate.close();
    progressCompleteUpdate.close();
    removeTask.close();
    cancelTask.close();
    //startUp.close();
  }

  TaskBloc._({
    this.addDownload,
    this.progressUpdate,
    this.progressCompleteUpdate,
    this.removeTask,
    this.cancelTask,
    this.tasks,
  });
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

  bool canceled = false;

  cancel() {
    canceled = true;
  }

  // static const String _locationSuffix = "downloads/";

  /// Download this file.
  _download(Downloadable task) async {
    // Factory the name and the state add to state list
    var fileName = Uri.decodeFull(task.url).split('/').last;

    if (Platform.isWindows) {
      // if (!await Directory(p.join(await AppSettings.savePath, _locationSuffix))
      if (!await Directory(p.join(await AppSettings.savePath)).exists()) {
        // await Directory(p.join(await AppSettings.savePath, _locationSuffix))
        await Directory(p.join(await AppSettings.savePath)).create();
      }
      filePath = p.join(await AppSettings.savePath, fileName);
    } else if (Platform.isAndroid) {
      var dir =
          (await getExternalStorageDirectories(type: StorageDirectory.pictures))
              .first
              .path;
      dir = await AppSettings.savePath;
      filePath = p.join("$dir/", fileName);
    }

    FileInfo file;
    if (!Platform.isWindows)
      file = await DefaultCacheManager().getFileFromCache(task.url);

    //  TODO:Check if file downloaded

    if (file != null) {
      if (!await Directory(await AppSettings.savePath).exists()) {
        await Directory(await AppSettings.savePath).create();
      }
      totalLength = -1;
      taskBloc.progressUpdate.add(null);
      DefaultCacheManager().getSingleFile(task.url).then((value) async {
        File(filePath).writeAsBytes(await file.file.readAsBytes()).then((_) {
          isDownloaded = true;
          _showNotification(post.id, post.id.toString(), filePath);
          taskBloc.removeTask.add(this);
          taskBloc.progressCompleteUpdate.add(null);
        });
      });
    } else {
      Dio().download(task.url, filePath,
          cancelToken: TaskBloc.cancelTokens[post.id],
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
  }

  /// Show a notification when download finished
  void _showNotification(int id, String text, String photoPath) {
    if (Platform.isAndroid) {
      notifier.sendNotificationWithBitmap(
          id,
          '${language.content.finishedDownload}',
          'Post $text ${language.content.downloaded}',
          photoPath);
    }
  }

  factory DownloadTask.fromID(String id) {
    var post;
    BooruAPI.fetchSpecficPost(id: id).then((x) => post = x);
    return DownloadTask._fromID(post);
  }

  DownloadTask.fromDownload(
    this.post,
  ) {
    _download(post);
  }

  DownloadTask._fromID(
    this.post,
  ) : isDownloaded = true;
}

/// Downloadable object
class Downloadable {
  final String url;
  Downloadable(this.url);
}
