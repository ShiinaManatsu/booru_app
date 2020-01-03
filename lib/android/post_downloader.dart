import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yande_web/main.dart';

class PostDownloader {
  PostDownloader() {
    if (Platform.isAndroid) {
      getExternalStorageDirectory().then((x) => path = x);
    }
  }
  Directory path;

  List<DownloadStatus> states = List<DownloadStatus>();

  // If we already have a download in the state list, we notify it and return
  download(String url, int id, DownloadStatus downloadState) async {
    if (states.where((item) => item.url == url).length != 0) {
      states.where((item) => item.url == url).forEach((f) => {
            //_showNotification(f)  //TODO
          });
      return;
    }

    // Factory the name and the state add to state list
    var fileName = Uri.decodeFull(url).split('/').last;
    var savePath = 'D:/$fileName'; //'${path.path}/$fileName';
    var state = downloadState;
    state.url = url;
    state.id = id;
    state.filePath = savePath;
    states.add(state);

    // Check if exist
    if (!File(savePath).existsSync()) {
      await Dio().download(url, savePath,
          onReceiveProgress: (int download, int total) {
        // Refresh the state
        state.progressOpacity = 1;
        state.current = download;
        state.total = total;
        state.isDownload = true;
        if (state.callback != null) {
          state.callback(state);
        }
      }).then((_) {
        state.progressOpacity = 0;
        if (state.callback != null) {
          state.callback(state);
        }
        _showNotification(state); //TODO
      });
    } else {
      _showNotification(state); //TODO
    }
  }

  /// Show a notification when download finished
  void _showNotification(DownloadStatus status) {
    if (Platform.isAndroid) {
      notifier.sendNotificationWithBitmap(status.id, 'Finished download',
          'Post ${status.id} downloaded', status.filePath);
    }
  }
}

class DownloadStatus {
  DownloadStatus(this.url, this.id, {this.filePath, this.callback});
  bool isDownload = false;
  String filePath;
  int id;
  String url;
  int current = 1;
  int total = 10;
  double progressOpacity = 0;
  bool get isFinished => current == total;
  Function(DownloadStatus) callback;
}
