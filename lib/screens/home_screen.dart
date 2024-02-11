import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './../util/dialog.dart' as util;
import 'package:my_app/providers/auth_service.dart';
import 'package:my_app/util/shared_events.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:background_fetch/background_fetch.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin<HomeScreen>, WidgetsBindingObserver {
  bool? _enabled;
  List<Event> events = [];
  DateTime? _lastRequestedTemporaryFullAccuracy;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _enabled = false;
    initPlatformState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("[home_view didChangeAppLifecycleState] : $state");
    if (state == AppLifecycleState.inactive) {
      // Do nothing.
      Timer(const Duration(seconds: 21), () async {
        var location = await bg.BackgroundGeolocation.getCurrentPosition();
        print("************ [location] $location");
      });
    } else if (state == AppLifecycleState.resumed) {
      if (!_enabled!) return;

      DateTime now = DateTime.now();
      var lastRequestedTemporaryFullAccuracy =
          _lastRequestedTemporaryFullAccuracy;
      if (lastRequestedTemporaryFullAccuracy != null) {
        Duration dt = lastRequestedTemporaryFullAccuracy.difference(now);
        if (dt.inSeconds < 10) return;
      }
      lastRequestedTemporaryFullAccuracy = now;
      bg.BackgroundGeolocation.requestTemporaryFullAccuracy("DemoPurpose");
    }
  }

  void initPlatformState() async {
    _configureBackgroundGeolocation();
    _configureBackgroundFetch();
    final tokenUser = await const FlutterSecureStorage().read(key: 'token');
    print("token user $tokenUser");
    bg.BackgroundGeolocation.ready(bg.Config(
            allowIdenticalLocations: true,
            autoSyncThreshold: 5,
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 2.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            reset: true,
            url:
                "https://us-central1-flutter-varios-2d50d.cloudfunctions.net/app/api/locations",
            headers: {"Content-Type": "application/json"},
            method: 'POST',
            logLevel: bg.Config.LOG_LEVEL_VERBOSE))
        .then((bg.State state) async {
      state;
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start();
      }
    });
  }

  void _configureBackgroundGeolocation() async {
    bg.BackgroundGeolocation.onLocation(_onLocation, _onLocationError);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChange);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onHttp(_onHttp);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    bg.BackgroundGeolocation.onHeartbeat(_onHeartbeat);
    bg.BackgroundGeolocation.onGeofence(_onGeofence);
    bg.BackgroundGeolocation.onSchedule(_onSchedule);
    bg.BackgroundGeolocation.onPowerSaveChange(_onPowerSaveChange);
    bg.BackgroundGeolocation.onEnabledChange(_onEnabledChange);
    bg.BackgroundGeolocation.onNotificationAction(_onNotificationAction);
    bg.BackgroundGeolocation.onAuthorization((bg.AuthorizationEvent event) {
      print('[${bg.Event.AUTHORIZATION}] - $event');
      
      setState(() {
        events.insert(
            0, Event(bg.Event.AUTHORIZATION, event, event.toString()));
      });
    });
  }

  void _configureBackgroundFetch() async {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            startOnBoot: true,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresStorageNotLow: false,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      taskId;
      print("[BackgroundFetch] recive evento $taskId");
      bg.Logger.debug("🔔 [BackgroundFetch emepiza] $taskId");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int count = 0;
      if (prefs.get("fetch-count") != null) {
        count = prefs.getInt("fetch-count")!;
      }
      prefs.setInt("fetch-count", ++count);
      print('[BackgroundFetch] conteo: $count');

      if (taskId == 'flutter_background_fetch') {
        try {
          // Fetch current position
          var location = await bg.BackgroundGeolocation.getCurrentPosition(
              samples: 2,
              maximumAge: 1000 * 10, // 30 seconds ago
              timeout: 30,
              desiredAccuracy: 40,
              extras: {"event": "background-fetch", "headless": false});

          print("[location] $location");
        } catch (error) {
          print("eror fira");
          print("[location] ERROR: $error");
        }

        // Test scheduling a custom-task in fetch event.
        BackgroundFetch.scheduleTask(TaskConfig(
            taskId: "com.transistorsoft.customtask",
            delay: 5000,
            periodic: false,
            forceAlarmManager: false,
            stopOnTerminate: false,
            enableHeadless: true));
      }
      bg.Logger.debug("🔔 [BackgroundFetch finaliza] $taskId");
      BackgroundFetch.finish(taskId);
    });
  }

  void _onLocation(bg.Location location) {
    print('[${bg.Event.LOCATION}] - $location');

    setState(() {
      events.insert(0, Event(bg.Event.LOCATION, location, location.toString()));
    });
  }

  void _onAuthorizacion(bg.Authorization authorization) {
    print('[${bg.Event.AUTHORIZATION}] - $authorization');

    setState(() {
      events.insert(
          0,
          Event(
              bg.Event.AUTHORIZATION, authorization, authorization.toString()));
    });
  }

  void _onLocationError(bg.LocationError error) {
    error;
    print('[${bg.Event.LOCATION}] ERROR - $error');
    setState(() {
      events.insert(
          0, Event("${bg.Event.LOCATION} error", error, error.toString()));
    });
  }

  void _onMotionChange(bg.Location location) {
    print('[${bg.Event.MOTIONCHANGE}] - $location');

    setState(() {
      events.insert(
          0, Event(bg.Event.MOTIONCHANGE, location, location.toString()));
    });
  }

  void _onActivityChange(bg.ActivityChangeEvent event) {
    print('[${bg.Event.ACTIVITYCHANGE}] - $event');
    setState(() {
      events.insert(0, Event(bg.Event.ACTIVITYCHANGE, event, event.toString()));
    });
  }

  void _onProviderChange(bg.ProviderChangeEvent event) async {
    print('[${bg.Event.PROVIDERCHANGE}] - $event');

    if ((event.status == bg.ProviderChangeEvent.AUTHORIZATION_STATUS_ALWAYS) &&
        (event.accuracyAuthorization ==
            bg.ProviderChangeEvent.ACCURACY_AUTHORIZATION_REDUCED)) {
      // Supply "Purpose" key from Info.plist as 1st argument.
      bg.BackgroundGeolocation.requestTemporaryFullAccuracy("DemoPurpose")
          .then((int accuracyAuthorization) {
        if (accuracyAuthorization ==
            bg.ProviderChangeEvent.ACCURACY_AUTHORIZATION_FULL) {
          print(
              "[requestTemporaryFullAccuracy] GRANTED:  $accuracyAuthorization");
        } else {
          print(
              "[requestTemporaryFullAccuracy] DENIED:  $accuracyAuthorization");
        }
      }).catchError((error) {
        print("[requestTemporaryFullAccuracy] FAILED TO SHOW DIALOG: $error");
      });
    }
    setState(() {
      events.insert(0, Event(bg.Event.PROVIDERCHANGE, event, event.toString()));
    });
  }

  void _onHttp(bg.HttpEvent event) async {
    print("evento http");
    event;
    print('[${bg.Event.HTTP}] - $event');
    setState(() {
      events.insert(0, Event(bg.Event.HTTP, event, event.toString()));
    });
  }

  void _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    print('[${bg.Event.CONNECTIVITYCHANGE}] - $event');
    setState(() {
      events.insert(
          0, Event(bg.Event.CONNECTIVITYCHANGE, event, event.toString()));
    });
  }

  void _onHeartbeat(bg.HeartbeatEvent event) async {
    print('[${bg.Event.HEARTBEAT}] - $event');
    // In onHeartbeat, if you intend to any kind of async task, first start a background-task:
    var taskId = await bg.BackgroundGeolocation.startBackgroundTask();

    // Now that we've initiated a background-task, call .getCurrentPosition()
    try {
      bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition(
          samples: 2, timeout: 10, extras: {"event": "heartbeat"});
      print("[heartbeat] getCurrentPosition: $location");
    } catch (e) {
      print("[heartbeat] getCurrentPosition ERROR: $e");
    }
    setState(() {
      events.insert(0, Event(bg.Event.HEARTBEAT, event, event.toString()));
    });

    // Be sure to signal completion of your task.
    bg.BackgroundGeolocation.stopBackgroundTask(taskId);
  }

  void _onGeofence(bg.GeofenceEvent event) async {
    print('[${bg.Event.GEOFENCE}] - $event');
    print("sending info to backend");
    bg.BackgroundGeolocation.startBackgroundTask().then((int taskId) async {
      // Execute an HTTP request to test an async operation completes.
      // String url = "${ENV.TRACKER_HOST}/api/devices";
      bg.State state = await bg.BackgroundGeolocation.state;
      print(state);
    });

    setState(() {
      events.insert(0, Event(bg.Event.GEOFENCE, event, event.toString()));
    });
  }

  void _onSchedule(bg.State state) {
    print('[${bg.Event.SCHEDULE}] - $state');
    setState(() {
      events.insert(
          0, Event(bg.Event.SCHEDULE, state, "enabled: ${state.enabled}"));
    });
  }

  void _onEnabledChange(bool enabled) {
    print('[${bg.Event.ENABLEDCHANGE}] - $enabled');
    setState(() {
      _enabled = enabled;
      events.clear();
      events.insert(
          0,
          Event(bg.Event.ENABLEDCHANGE, enabled,
              '[EnabledChangeEvent enabled: $enabled]'));
    });
  }

  void _onNotificationAction(String action) {
    print('[onNotificationAction] $action');
    switch (action) {
      case 'notificationButtonFoo':
        bg.BackgroundGeolocation.changePace(false);
        break;
      case 'notificationButtonBar':
        break;
    }
  }

  void _onPowerSaveChange(bool enabled) {
    print('[${bg.Event.POWERSAVECHANGE}] - $enabled');
    setState(() {
      events.insert(
          0,
          Event(bg.Event.POWERSAVECHANGE, enabled,
              'Power-saving enabled: $enabled'));
    });
  }

  void _onClickEnable(enabled) async {
    bg.BackgroundGeolocation.playSound(util.Dialog.getSoundId("BUTTON_CLICK"));
    if (enabled) {
      callback(bg.State state) async {
        print('[start] success: $state');
        setState(() {
          _enabled = state.enabled;
        });
      }

      bg.State state = await bg.BackgroundGeolocation.state;
      if (state.trackingMode == 1) {
        bg.BackgroundGeolocation.start().then(callback);
      } else {
        bg.BackgroundGeolocation.startGeofences().then(callback);
      }
    } else {
      callback(bg.State state) {
        print('[stop] success: $state');
        setState(() {
          _enabled = state.enabled;
        });
      }

      bg.BackgroundGeolocation.stop().then(callback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ubicación',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.login_outlined,
                color: Colors.white,
              ),
              //deberia ser un async pero no por que esta accion es rapida OJO CON ESTO
              onPressed: () {
                authService.logOut();
                Navigator.pushReplacementNamed(context, 'login/');
              },
            ),
          ],
        ),
        //es perezoso
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Permitir rastrear tu ubicación",
              style: TextStyle(fontSize: 18),
            ),
            Center(
              child: Switch(value: _enabled!, onChanged: _onClickEnable),
            ),
          ],
        ));
  }
}
