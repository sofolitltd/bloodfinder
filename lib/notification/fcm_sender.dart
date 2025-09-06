import 'dart:convert';

import 'package:bloodfinder/data/services/fcm_credentials.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class FCMSender {
  static Future<bool> sendToToken({
    required String token,
    required String title,
    required String body,
    required String chatId,
  }) async {
    return _send(
      target: {'token': token},
      title: title,
      body: body,
      data: {'type': 'chat', 'chatId': chatId},
    );
  }

  static Future<bool> _send({
    required Map<String, String> target,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final jsonCredentials = await rootBundle.loadString(
        FCMCredentials.filePath,
      );
      final credentials = auth.ServiceAccountCredentials.fromJson(
        jsonCredentials,
      );

      final client = await auth.clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/cloud-platform',
      ]);

      final message = {
        ...target,
        'notification': {'title': title, 'body': body},
        'data': data,
      };

      final response = await client.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/${FCMCredentials.projectId}/messages:send',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
