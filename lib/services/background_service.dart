import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ble_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'drift_foreground', // id
    'Drift Radar', // title
    description: 'This channel is used for the Drift radar.', // description
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'drift_foreground',
      initialNotificationTitle: 'Collect is running',
      initialNotificationContent: 'Drift radar is active',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Re-initialize Supabase inside the isolate
  await Supabase.initialize(
    url: 'https://qthjufceuesqwrypwqgx.supabase.co',
    anonKey: 'sb_publishable_lw7OkHrufOLfqCw1J4Am3A_FB601r5d',
  );

  final supabase = Supabase.instance.client;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    BleService.instance.dispose();
    service.stopSelf();
  });

  // Start BLE if we have a logged in user in this isolate
  final user = supabase.auth.currentUser;
  if (user != null) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Collect / Drift Radar",
        content: "Scanning for nearby people...",
      );
    }
    await BleService.instance.init(user.id);
  } else {
    // If we're not logged in, there's no point running the service
    service.stopSelf();
  }
}
