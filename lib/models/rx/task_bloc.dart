import 'package:booru_app/models/yande/post.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:booru_app/settings/app_settings.dart';
import '../../utils/platform.dart';
import 'download_fs_stub.dart' if (dart.library.io) 'download_fs_io.dart';

/// Lightweight download manager for posts.
class TaskBloc {
  TaskBloc();

  final PublishSubject<Post> addDownload = PublishSubject<Post>();
  final PublishSubject progressUpdate = PublishSubject();
  final PublishSubject progressCompleteUpdate = PublishSubject();
  final PublishSubject<DownloadTask> removeTask = PublishSubject();
  final PublishSubject<DownloadTask> cancelTask = PublishSubject();

  final List<DownloadTask> tasksList = <DownloadTask>[];
  final Map<int, CancelToken> cancelTokens = <int, CancelToken>{};

  Stream<List<DownloadTask>> get tasks => _tasksStream;

  late final Stream<List<DownloadTask>> _tasksStream = _buildStreams();

  Stream<List<DownloadTask>> _buildStreams() {
    final downloadTask = addDownload.distinct().map<DownloadTask>((post) {
      final task = DownloadTask.fromDownload(post, owner: this);
      tasksList.add(task);
      cancelTokens[post.id] = CancelToken();
      return task;
    }).switchMap<List<DownloadTask>>((_) async* {
      yield tasksList;
    }).startWith(<DownloadTask>[]);

    final updateThrottled = progressUpdate.throttleTime(const Duration(milliseconds: 500));
    final update = updateThrottled.mergeWith([progressCompleteUpdate]).switchMap<List<DownloadTask>>((_) async* {
      yield tasksList;
    }).startWith(<DownloadTask>[]);

    final remove = removeTask.distinct().asBroadcastStream().interval(const Duration(seconds: 3)).switchMap<List<DownloadTask>>((task) async* {
      tasksList.remove(task);
      cancelTokens.remove(task.post.id);
      yield tasksList;
    }).startWith(<DownloadTask>[]);

    final cancel = cancelTask.asBroadcastStream().switchMap<List<DownloadTask>>((task) async* {
      cancelTokens[task.post.id]?.cancel();
      cancelTokens.remove(task.post.id);
      task.cancel();
      removeTask.add(task);
      progressCompleteUpdate.add(null);
      yield tasksList;
    }).startWith(<DownloadTask>[]);

    return downloadTask.mergeWith([update, remove, cancel]).asBroadcastStream();
  }

  void dispose() {
    addDownload.close();
    progressUpdate.close();
    progressCompleteUpdate.close();
    removeTask.close();
    cancelTask.close();
  }

  /// Starts a download and resolves with the saved file path.
  ///
  /// Returns `null` if cancelled or failed.
  Future<String?> downloadNow(Post post) async {
    if (cancelTokens.containsKey(post.id)) {
      // Already downloading (or queued). Don't duplicate.
      return null;
    }

    final task = DownloadTask.fromDownload(post, owner: this);
    tasksList.add(task);
    cancelTokens[post.id] = CancelToken();
    progressCompleteUpdate.add(null);
    progressUpdate.add(null);

    final result = await task.done;
    return result;
  }
}

class DownloadTask {
  DownloadTask.fromDownload(this.post, {required this.owner}) {
    client = AppSettings.currentClient;
    _download(post);
  }

  final TaskBloc owner;
  final Post post;

  late final ClientType client;

  int totalLength = 1;
  int downloadedLength = 0;
  String? filePath;

  final Completer<String?> _completer = Completer<String?>();
  Future<String?> get done => _completer.future;

  double? get progress => isDownloaded
      ? 1
      : totalLength == -1
          ? null
          : downloadedLength / totalLength;

  bool isDownloaded = false;
  bool canceled = false;

  void cancel() {
    canceled = true;
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }

  Future<void> _download(Downloadable task) async {
    if (task.url.trim().isEmpty) {
      owner.removeTask.add(this);
      owner.progressCompleteUpdate.add(null);
      if (!_completer.isCompleted) _completer.complete(null);
      return;
    }

    String fileName;
    try {
      final uri = Uri.parse(task.url);
      fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'post_${post.id}';
    } catch (_) {
      fileName = Uri.decodeFull(task.url).split('/').last;
    }
    final targetPath = await prepareTargetPath(post, fileName, skipIfExists: true);
    if (targetPath == null) {
      // Web: skip download; not supported here.
      owner.removeTask.add(this);
      owner.progressCompleteUpdate.add(null);
      if (!_completer.isCompleted) _completer.complete(null);
      return;
    }

    filePath = targetPath;

    // If the file already exists in the target folder, treat this as done.
    if (await fileExists(targetPath)) {
      isDownloaded = true;
      owner.removeTask.add(this);
      owner.progressCompleteUpdate.add(null);
      if (!_completer.isCompleted) _completer.complete(targetPath);
      return;
    }

    FileInfo? cached = await loadCached(task.url);

    if (cached != null) {
      totalLength = -1;
      owner.progressUpdate.add(null);
      final bytes = await cached.file.readAsBytes();
      await saveBytes(targetPath, bytes);
      isDownloaded = true;
      owner.removeTask.add(this);
      owner.progressCompleteUpdate.add(null);
      await _maybeSaveToGallery(sourcePath: targetPath, originalFileName: fileName);
      _maybeNotify();
      if (!_completer.isCompleted) _completer.complete(targetPath);
      return;
    }

    try {
      await Dio().download(task.url, targetPath, cancelToken: owner.cancelTokens[post.id], onReceiveProgress: (download, total) {
        downloadedLength = download;
        totalLength = total;
        owner.progressUpdate.add(null);
      });
      isDownloaded = true;
      owner.removeTask.add(this);
      owner.progressCompleteUpdate.add(null);
      await _maybeSaveToGallery(sourcePath: targetPath, originalFileName: fileName);
      _maybeNotify();
      if (!_completer.isCompleted) _completer.complete(targetPath);
    } catch (_) {
      owner.removeTask.add(this);
      owner.progressCompleteUpdate.add(null);
      if (!_completer.isCompleted) _completer.complete(null);
    }
  }

  Future<void> _maybeSaveToGallery({required String sourcePath, required String originalFileName}) async {
    if (!isAndroid) return;
    if (canceled) return;

    final ext = p.extension(originalFileName).replaceFirst('.', '').trim();
    final safeName = originalFileName.trim().isEmpty ? 'post_${post.id}' : originalFileName.trim();
    final folder = client == ClientType.Konachan ? 'Konachan' : 'Yande';

    try {
      final result = await SaverGallery.saveFile(
        filePath: sourcePath,
        fileName: safeName,
        androidRelativePath: 'Pictures/$folder',
        skipIfExists: true,
      );

      // If it was successfully copied into MediaStore, we can optionally
      // delete the temp file. Keep it for now so the "Open" button still works.
      // ignore: unused_local_variable
      final _ = result.isSuccess;
      // ignore: unused_local_variable
      final __ = ext;
    } catch (_) {
      // Best-effort: if it fails, we still keep the downloaded file.
    }
  }

  void _maybeNotify() {
    if (!isAndroid || filePath == null) return;
    // Notification bridge was Android-only in the legacy app; omitted here to avoid platform channel complexity.
  }
}

class Downloadable {
  Downloadable(this.url);
  final String url;
}
