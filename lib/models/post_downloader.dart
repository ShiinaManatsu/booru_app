import 'dart:io';
import 'package:dio/dio.dart';

class PostDownloader {
  PostDownloader() {
    getExternalStorageDirectory().then((x) => path = x);
  }
  Directory path;

  // TODO: Implements the mothod
  Future<Directory> getExternalStorageDirectory()async{
    return Directory("path");
  }

  List<DownloadStatus> states = List<DownloadStatus>();

  // If we already have a download in the state list, we notify it and return
  download(String url, int id,DownloadStatus downloadState) async {
    if (states.where((item) => item.url == url).length != 0) {
      states
          .where((item) => item.url == url)
          .forEach((f) => {
            //_showNotification(f)  //TODO
          });
      return;
    }

    // Factory the name and the state add to state list
    var fileName = Uri.decodeFull(url).split('/').last;
    var savePath = '${path.path}/$fileName';
    var state=downloadState;
    state.url=url;
    state.id=id;
    state.filePath=savePath;
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
        // _showNotification(state);  //TODO
      });
    } else {
      // _showNotification(state);  //TODO
    }
  }

  // TODO: Implements the show notifications method later
  // void _showNotification(DownloadStatus status) {
  //   notifier.sendNotificationWithBitmap(status.id, 'Finished download',
  //       'Post ${status.id} downloaded', status.filePath);
  // }
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
  Function(DownloadStatus) callback;
}
