import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:my_app/models/location.dart';
import 'package:my_app/providers/location_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'providers/providers.dart';
import 'screens/screens.dart';

import 'package:http/http.dart' as http;

void main() {
  runApp(const AppState());

  /// Register BackgroundGeolocation headless-task.
  bg.BackgroundGeolocation.registerHeadlessTask(
      backgroundGeolocationHeadlessTask);

  /// Register BackgroundFetch headless-task.
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  // const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) =>
                LocationService()), //si se [one el lazy en false, se diparara la pet en el login OJO]
        ChangeNotifierProvider(
            create: (_) => AuthService()) //provider loguin reggister
      ],
      child: const MyApp(),
    );
  }
}

Future<void> sendBack(Uri url, Location location) async {
  //debo mandar un json al backend con el metodo credo de la clase producto
  final resp = await http.post(url, body: location.toJson());
  final decodeData = json.decode(resp.body);
  print("send firabae");
  print(decodeData);
  //print(decodeData);
  if (resp.statusCode != 200 && resp.statusCode != 201) {
    print('algo salio mal en el init');
  }
  return decodeData;
}

@pragma('vm:entry-point')
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
  print('📬 --> $headlessEvent');

  switch (headlessEvent.name) {
    case bg.Event.BOOT:
      bg.State state = await bg.BackgroundGeolocation.state;
      print("📬 didDeviceReboot: ${state.didDeviceReboot}");
      break;
    case bg.Event.TERMINATE:
      bg.State state = await bg.BackgroundGeolocation.state;
      if (state.stopOnTerminate!) {
        // Don't request getCurrentPosition when stopOnTerminate: true
        return;
      }
      try {
        bg.Location location =
            await bg.BackgroundGeolocation.getCurrentPosition(
                samples: 1,
                extras: {
                  "event": "terminate",
                  "headless": true
                }
            );
        print("[getCurrentPosition] Headless: $location");
      } catch (error) {
        print("[getCurrentPosition] Headless ERROR: $error");
      }

      break;
    case bg.Event.HEARTBEAT:
      try {
        bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(
          samples: 2,
          timeout: 10,
          extras: {
            "event": "heartbeat",
            "headless": true
          }
        );

        print('[getCurrentPosition] Headless: $location');
      } catch (error) {
        print('[getCurrentPosition] Headless ERROR: $error');
      }
      break;
    case bg.Event.LOCATION:
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.MOTIONCHANGE:
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.GEOFENCE:
      bg.GeofenceEvent geofenceEvent = headlessEvent.event;
      print(geofenceEvent);
      break;
    case bg.Event.GEOFENCESCHANGE:
      bg.GeofencesChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.SCHEDULE:
      bg.State state = headlessEvent.event;
      print(state);
      break;
    case bg.Event.ACTIVITYCHANGE:
      bg.ActivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.HTTP:
      bg.HttpEvent response = headlessEvent.event;
      print(response);
      break;
    case bg.Event.POWERSAVECHANGE:
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.CONNECTIVITYCHANGE:
      bg.ConnectivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.ENABLEDCHANGE:
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.AUTHORIZATION:
      bg.AuthorizationEvent event = headlessEvent.event;
      print(event);
      bg.BackgroundGeolocation.setConfig(
          bg.Config(url:
                "https://us-central1-flutter-varios-2d50d.cloudfunctions.net/app/api/locations",
            headers: {"Content-Type": "application/json"},
            method: 'POST',));
      break;
  }
}

/// Receive events from BackgroundFetch in Headless state.
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;

  // Is this a background_fetch timeout event?  If so, simply #finish and bail-out.
  if (task.timeout) {
    print("[BackgroundFetch] HeadlessTask TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  print("[BackgroundFetch] HeadlessTask: $taskId");

  try {
    var location = await bg.BackgroundGeolocation.getCurrentPosition(
	    samples: 2,
      extras: {
        "event": "background-fetch",
        "headless": true
      }
    );
    print("[location] $location");
  } catch(error) {
    print("[location] ERROR: $error");
  }


  BackgroundFetch.finish(taskId);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location app',
      initialRoute: 'checking/',
      routes: {
        'checking/': ((context) => const CheckAuthScreen()),
        'login/': ((context) => const LoginScreen()),
        'home/': ((context) => const HomeScreen()),
        'register/': ((context) => const RegisterScreen()),
      },
      scaffoldMessengerKey: NotificationProivder
          .messegerKey, //tener acceso a ese servicio en todo lado con la key statica
      theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: Colors.grey[300],
          appBarTheme: const AppBarTheme(elevation: 0, color: Colors.indigo),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.indigo.shade900)),
    );
  }
}
