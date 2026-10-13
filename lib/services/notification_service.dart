import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  String? _company;
  void Function(String)? _onOpen;
  int _notificationId = 0;
  int _session = 0;
  Future<void>? _localReady;
  Future<void> _pending = Future.value();
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'incidents_channel',
      'Factory Check',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  // Serialize topic changes so signing out during initialization cannot leave
  // the old session subscribed after its cleanup has completed.
  Future<void> _enqueue(Future<void> Function() action) {
    final next = _pending.then((_) => action());
    _pending = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<void> _ensureLocal() async {
    try {
      await (_localReady ??= _initializeLocal());
    } catch (_) {
      _localReady = null;
      rethrow;
    }
  }

  Future<void> _initializeLocal() async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        try {
          _open(jsonDecode(payload) as Map<String, dynamic>);
        } catch (_) {
          /* Ignore outdated payloads. */
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'incidents_channel',
            'Factory Check',
            description: 'Production calls',
            importance: Importance.high,
          ),
        );
  }

  Future<void> init({
    required String companyId,
    required void Function(String) onOpen,
    bool foregroundCallsHandled = false,
  }) {
    final session = ++_session;
    _company = companyId;
    _onOpen = onOpen;
    return _enqueue(() async {
      if (!Platform.isAndroid || session != _session) return;
      await _cancelListeners();
      // Local alerts work even if topic subscription is unavailable.
      await _ensureLocal();
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (session != _session) return;
      _foreground = FirebaseMessaging.onMessage.listen((message) async {
        if (session != _session || message.data['companyId'] != _company) {
          return;
        }
        if (foregroundCallsHandled &&
            message.data['type'] == 'incident_created') {
          return;
        }
        final n = message.notification;
        if (n == null) return;
        try {
          await _local.show(
            ++_notificationId,
            n.title,
            n.body,
            _details,
            payload: jsonEncode(message.data),
          );
        } catch (_) {
          /* The live list remains available. */
        }
      });
      _opened = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (session == _session) _open(message.data);
      });
      final initial = await _fcm.getInitialMessage();
      if (session != _session) return;
      if (initial != null) _open(initial.data);
      final launch = await _local.getNotificationAppLaunchDetails();
      if (session != _session) return;
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true && payload != null) {
        try {
          _open(jsonDecode(payload) as Map<String, dynamic>);
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      if (session != _session) return;
      final oldTopic = prefs.getString('notificationTopic');
      if (oldTopic != null) {
        await _fcm.unsubscribeFromTopic(oldTopic);
        await prefs.remove('notificationTopic');
      }
      if (session != _session) return;
      final topic = 'company_$companyId';
      // Persist first so logout can retry cleanup after a network failure.
      await prefs.setString('notificationTopic', topic);
      if (session != _session) return;
      await _fcm.subscribeToTopic(topic);
    });
  }

  Future<bool> showCall({
    required String companyId,
    required String incidentId,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid || companyId != _company) return false;
    final session = _session;
    await _ensureLocal();
    final enabled = await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
    if (enabled != true || session != _session) return false;
    await _local.show(
      ++_notificationId,
      title,
      body,
      _details,
      payload: jsonEncode({'companyId': companyId, 'incidentId': incidentId}),
    );
    return true;
  }

  Future<bool> testSound({
    required String companyId,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid || companyId != _company) return false;
    final session = _session;
    await _ensureLocal();
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (session != _session) return false;
    return showCall(
      companyId: companyId,
      incidentId: '',
      title: title,
      body: body,
    );
  }

  void _open(Map<String, dynamic> data) {
    if (_company == null || data['companyId'] != _company) return;
    final id = (data['incidentId'] ?? '').toString();
    if (id.isNotEmpty) _onOpen?.call(id);
  }

  Future<void> _cancelListeners() async {
    await _foreground?.cancel();
    await _opened?.cancel();
    _foreground = null;
    _opened = null;
  }

  Future<void> reset() {
    ++_session;
    _company = null;
    _onOpen = null;
    return _enqueue(() async {
      await _cancelListeners();
      if (!Platform.isAndroid) return;
      final prefs = await SharedPreferences.getInstance();
      final topic = prefs.getString('notificationTopic');
      if (topic != null) {
        try {
          await _fcm.unsubscribeFromTopic(topic);
          await prefs.remove('notificationTopic');
        } catch (_) {
          /* Retry persisted cleanup before the next subscription. */
        }
      }
      try {
        await _local.cancelAll();
      } catch (_) {}
    });
  }
}
