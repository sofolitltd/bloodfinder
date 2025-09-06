// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
//
// import '../main.dart';
//
// //
// Future<void> handleBackgroundMessage(RemoteMessage message) async {
//   log('Background FCM: ${message.notification?.title}');
// }
//
// //
// class FcmApi {
//   final firebaseMessaging = FirebaseMessaging.instance;
//   final localNotifications = FlutterLocalNotificationsPlugin();
//
//   final channel = const AndroidNotificationChannel(
//     'high_importance_channel',
//     'High Importance Notifications',
//     description: 'This channel is used for important notifications',
//     importance: Importance.high,
//   );
//
//   //
//   Future<void> initPushNotifications() async {
//     await firebaseMessaging.requestPermission();
//
//     // Handle when app launched from terminated state
//     final initialMessage = await firebaseMessaging.getInitialMessage();
//     if (initialMessage != null) {
//       handleMessage(initialMessage);
//     }
//
//     //
//     FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
//
//     //
//     FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
//
//     //
//     FirebaseMessaging.onMessage.listen((message) {
//       final notification = message.notification;
//       final data = message.data;
//       final imageUrl = data['image'];
//       final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
//
//       if (notification != null) {
//         if (hasImage) {
//           _downloadAndShowImageNotification(notification, data, imageUrl);
//         } else {
//           _showSimpleNotification(notification, data);
//         }
//       }
//     });
//
//     await _subscribeToTopics();
//     await _updateToken();
//     await initLocalPushNotifications();
//   }
//
//   //
//   Future<void> _subscribeToTopics() async {
//     // await firebaseMessaging.subscribeToTopic('chats');
//     await firebaseMessaging.subscribeToTopic('notifications');
//   }
//
//   //
//   Future<void> _updateToken() async {
//     // await firebaseMessaging.subscribeToTopic('chats');
//     await firebaseMessaging.getToken().then((token) async {
//       // update on token on firebase users collection
//       var uid = FirebaseAuth.instance.currentUser!.uid;
//       await FirebaseFirestore.instance.collection('users').doc(uid).update({
//         'token': token,
//       });
//     });
//   }
//
//   //
//   Future<void> initLocalPushNotifications() async {
//     const settings = InitializationSettings(
//       android: AndroidInitializationSettings('@drawable/logo'),
//     );
//
//     await localNotifications.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (response) {
//         if (response.payload != null) {
//           final data = jsonDecode(response.payload!);
//           log("Clicked notification: $data");
//           _handleNavigation(data);
//         }
//       },
//     );
//
//     final platform = localNotifications
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >();
//     await platform?.createNotificationChannel(channel);
//   }
//
//   void handleMessage(RemoteMessage message) {
//     final data = message.data;
//     log('🔔 [HANDLE] FCM Message: ${jsonEncode(data)}');
//     _handleNavigation(data);
//   }
//
//   //
//   void _handleNavigation(Map<String, dynamic> data) {
//     final type = data['type'];
//     log("🔔 Navigation type: $type");
//
//     //
//     switch (type) {
//       case 'chats':
//         // use go touter to go notification
//         rootNavigatorKey.currentState?.pushNamed('/chat');
//
//         break;
//       default:
//         rootNavigatorKey.currentState?.pushNamed('/notification');
//     }
//   }
//
//   //
//   Future<void> _downloadAndShowImageNotification(
//     RemoteNotification notification,
//     Map<String, dynamic> data,
//     String imageUrl,
//   ) async {
//     try {
//       final response = await http.get(Uri.parse(imageUrl));
//       final directory = await getTemporaryDirectory();
//       final filePath = '${directory.path}/fcm_image.jpg';
//       final file = File(filePath);
//       await file.writeAsBytes(response.bodyBytes);
//
//       final bigPictureStyle = BigPictureStyleInformation(
//         FilePathAndroidBitmap(filePath),
//         contentTitle: notification.title,
//         summaryText: notification.body,
//       );
//
//       final androidDetails = AndroidNotificationDetails(
//         channel.id,
//         channel.name,
//         channelDescription: channel.description,
//         importance: Importance.high,
//         priority: Priority.high,
//         icon: '@drawable/logo',
//         styleInformation: bigPictureStyle,
//       );
//
//       await localNotifications.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(android: androidDetails),
//         payload: jsonEncode(data),
//       );
//     } catch (e) {
//       log('⚠️ Failed to load image: $e');
//       _showSimpleNotification(notification, data);
//     }
//   }
//
//   //
//   void _showSimpleNotification(
//     RemoteNotification notification,
//     Map<String, dynamic> data,
//   ) {
//     final androidDetails = AndroidNotificationDetails(
//       channel.id,
//       channel.name,
//       channelDescription: channel.description,
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@drawable/logo',
//     );
//
//     localNotifications.show(
//       notification.hashCode,
//       notification.title,
//       notification.body,
//       NotificationDetails(android: androidDetails),
//       payload: jsonEncode(data),
//     );
//   }
// }
//
// //https://apoorv-pandey.medium.com/migrate-to-the-latest-firebase-cloud-messaging-api-http-v1-firebase-push-notification-2024-42defdf06762

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../routes/router_config.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  log('Background FCM: ${message.notification?.title}');
}

class FcmApi {
  final firebaseMessaging = FirebaseMessaging.instance;
  final localNotifications = FlutterLocalNotificationsPlugin();

  final channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for chat & community notifications',
    importance: Importance.high,
  );

  Future<void> initPushNotifications() async {
    await firebaseMessaging.requestPermission();

    final initialMessage = await firebaseMessaging.getInitialMessage();
    if (initialMessage != null) handleMessage(initialMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final data = message.data;
      final imageUrl = data['image'];
      final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

      if (notification != null) {
        if (hasImage) {
          _downloadAndShowImageNotification(notification, data, imageUrl);
        } else {
          _showSimpleNotification(notification, data);
        }
      }
    });

    await _updateToken();
    await initLocalPushNotifications();
  }

  Future<void> _updateToken() async {
    final token = await firebaseMessaging.getToken();
    final usersRef = FirebaseFirestore.instance.collection('users');
    if (token != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await usersRef.doc(uid).update({'token': token});
      }
    }
  }

  Future<void> initLocalPushNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/logo'),
    );

    await localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _handleNavigation(data);
        }
      },
    );

    final platform = localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(channel);
  }

  void handleMessage(RemoteMessage message) {
    _handleNavigation(message.data);
  }

  void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'chat':
        final chatId = data['chatId'];
        if (chatId != null) {
          routerConfig.go('/chat/$chatId'); // pass chatId as path param
        }
        break;
      case 'community':
        final communityId = data['communityId'];
        if (communityId != null) {
          routerConfig.go('/community/$communityId');
        }
        break;
      default:
        routerConfig.go('/notification');
    }
  }

  Future<void> _downloadAndShowImageNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
    String imageUrl,
  ) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/fcm_image.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      final bigPictureStyle = BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath),
        contentTitle: notification.title,
        summaryText: notification.body,
      );

      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/logo',
        styleInformation: bigPictureStyle,
      );

      await localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(android: androidDetails),
        payload: jsonEncode(data),
      );
    } catch (e) {
      _showSimpleNotification(notification, data);
    }
  }

  void _showSimpleNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) {
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/logo',
    );

    localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(data),
    );
  }
}
