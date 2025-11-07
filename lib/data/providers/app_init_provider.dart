import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../notification/fcm_api.dart';

final appInitProvider = FutureProvider<void>((ref) async {
  // FCM setup
  await FcmApi().initPushNotifications();

  // In-app update
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateAvailable) {
      await InAppUpdate.performImmediateUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    }
  } catch (e) {
    log('Update check failed: $e');
  }
});
