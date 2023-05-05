import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/src/defines.dart';
import 'package:onesignal_flutter/src/notification.dart';
import 'package:onesignal_flutter/src/permission.dart';

class OneSignalNotificationLifecycleListener {
  void onWillDisplayNotification(OSNotificationWillDisplayEvent event) {}
}

class OneSignalNotificationClickListener {
  void onClickNotification(OSNotificationClickEvent event) {}
}

class OneSignalNotifications {
  // event listeners
  List<OneSignalNotificationClickListener> _clickListeners =
      <OneSignalNotificationClickListener>[];
  List<OneSignalNotificationLifecycleListener> _lifecycleListeners =
      <OneSignalNotificationLifecycleListener>[];

  // private channels used to bridge to ObjC/Java
  MethodChannel _channel = const MethodChannel('OneSignal#notifications');

  List<OneSignalPermissionObserver> _observers =
      <OneSignalPermissionObserver>[];
  // constructor method
  OneSignalNotifications() {
    this._channel.setMethodCallHandler(_handleMethod);
  }

  bool _permission = false;

  /// Whether this app has push notification permission.
  bool get permission {
    return _permission;
  }

  /// iOS only
  /// enum OSNotificationPermission {
  /// notDetermined,
  /// denied,
  /// authorized,
  /// provisional, // only available in iOS 12
  /// ephemeral, // only available in iOS 14
  Future<OSNotificationPermission> permissionNative() async {
    if (Platform.isIOS) {
      return OSNotificationPermission
          .values[await _channel.invokeMethod("OneSignal#permissionNative")];
    } else {
      return _permission
          ? OSNotificationPermission.authorized
          : OSNotificationPermission.denied;
    }
  }

  /// Whether attempting to request notification permission will show a prompt.
  /// Returns true if the device has not been prompted for push notification permission already.
  Future<bool> canRequest() async {
    if (Platform.isIOS) {
      return await _channel.invokeMethod("OneSignal#canRequest");
    } else {
      return false;
    }
  }

  /// Removes a single notification.
  Future<void> removeNotification(int notificationId) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod(
          "OneSignal#removeNotification", {'notificationId': notificationId});
    }
  }

  /// Removes a grouped notification.
  Future<void> removeGroupedNotifications(String notificationGroup) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("OneSignal#removeGroupedNotifications",
          {'notificationGroup': notificationGroup});
    }
  }

  /// Removes all OneSignal notifications.
  Future<void> clearAll() async {
    return await _channel.invokeMethod("OneSignal#clearAll");
  }

  /// Prompt the user for permission to receive push notifications. This will display the native
  /// system prompt to request push notification permission.
  Future<bool> requestPermission(bool fallbackToSettings) async {
    return await _channel.invokeMethod("OneSignal#requestPermission",
        {'fallbackToSettings': fallbackToSettings});
  }

  /// Instead of having to prompt the user for permission to send them push notifications,
  /// your app can request provisional authorization.
  Future<bool> registerForProvisionalAuthorization(
      bool fallbackToSettings) async {
    if (Platform.isIOS) {
      return await _channel
          .invokeMethod("OneSignal#registerForProvisionalAuthorization");
    } else {
      return false;
    }
  }

  /// The OSNotificationPermissionObserver.onNotificationPermissionDidChange method will be fired on the passed-in object
  /// when a notification permission setting changes. This happens when the user enables or disables
  /// notifications for your app from the system settings outside of your app.
  void addPermissionObserver(OneSignalPermissionObserver observer) {
    _observers.add(observer);
  }

  // Remove a push subscription observer that has been previously added.
  void removePermissionObserver(OneSignalPermissionObserver observer) {
    _observers.remove(observer);
  }

  Future<void> lifecycleInit() async {
    _permission = await _channel.invokeMethod("OneSignal#permission");
    return await _channel.invokeMethod("OneSignal#lifecycleInit");
  }

  Future<Null> _handleMethod(MethodCall call) async {
    if (call.method == 'OneSignal#onClickNotification') {
      for (var listener in _clickListeners) {
        listener.onClickNotification(
            OSNotificationClickEvent(call.arguments.cast<String, dynamic>()));
      }
    } else if (call.method == 'OneSignal#onWillDisplayNotification') {
      for (var listener in _lifecycleListeners) {
        listener.onWillDisplayNotification(OSNotificationWillDisplayEvent(
            call.arguments.cast<String, dynamic>()));
      }
    } else if (call.method == 'OneSignal#onNotificationPermissionDidChange') {
      this.onNotificationPermissionDidChange(call.arguments["permission"]);
    }
    return null;
  }

  void onNotificationPermissionDidChange(bool permission) {
    for (var observer in _observers) {
      observer.onNotificationPermissionDidChange(permission);
    }
  }

  void addLifecycleListener(OneSignalNotificationLifecycleListener listener) {
    _lifecycleListeners.add(listener);
  }

  void removeLifecycleListener(
      OneSignalNotificationLifecycleListener listener) {
    _lifecycleListeners.remove(listener);
  }

  /// The notification willDisplay listener is called whenever a notification arrives
  /// and the application is in foreground
  void preventDefault(String notificationId) {
    _channel.invokeMethod(
        "OneSignal#preventDefault", {'notificationId': notificationId});
  }

  void displayNotification(String notificationId) {
    _channel.invokeMethod(
        "OneSignal#displayNotification", {'notificationId': notificationId});
  }

  /// The notification click listener is called whenever the user opens a
  /// OneSignal push notification, or taps an action button on a notification.
  void addClickListener(OneSignalNotificationClickListener listener) {
    _clickListeners.add(listener);
  }

  void removeClickListener(OneSignalNotificationClickListener listener) {
    _clickListeners.remove(listener);
  }
}

class OneSignalPermissionObserver {
  void onNotificationPermissionDidChange(bool permission) {}
}
