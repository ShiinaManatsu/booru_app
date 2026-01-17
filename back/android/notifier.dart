import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

class Notifier {
  final FlutterLocalNotificationsPlugin notifier =
      FlutterLocalNotificationsPlugin();

  Notifier() {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('icon_notification');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    notifier.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      OpenFile.open(payload);
    }
  }

  sendNotification(int id, String title, String body) {
    notifier.show(
        id,
        title,
        body,
        NotificationDetails(
            android: AndroidNotificationDetails(
                'Yande channel $id', 'Yande channel', 'Channel for yande app',
                enableVibration: false, channelShowBadge: false),
            iOS: IOSNotificationDetails()));
  }

  sendNotificationWithBitmap(
      int id, String title, String body, String bitmapPath) {
    notifier.show(
        id,
        title,
        body,
        NotificationDetails(
            android: AndroidNotificationDetails(
              'Yande channel',
              'Yande channel',
              'Channel for yande app',
              largeIcon: FilePathAndroidBitmap(bitmapPath),
              styleInformation:
                  BigPictureStyleInformation(FilePathAndroidBitmap(bitmapPath)),
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: IOSNotificationDetails()),
        payload: bitmapPath);
  }
}
