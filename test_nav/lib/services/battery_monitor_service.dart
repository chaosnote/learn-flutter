import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../models/params.dart';

class BatteryMonitorService {
  // 單例模式 (Singleton)：確保整個 App 只有一個監控實體
  static final BatteryMonitorService _instance = BatteryMonitorService._internal();
  factory BatteryMonitorService() => _instance;
  BatteryMonitorService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Battery _battery = Battery();
  Timer? _timer;
  bool _hasAlerted = false;
  int? _lastAlertedLevel; // 記錄上一次發出警告時的電量

  Future<void> init() async {
    if (kIsWeb) return; // 網頁版不支援本機通知

    debugPrint("[BatteryMonitorService] 進入 init()...");

    // 1. 初始化通知設定
    // ⚠️ 已改為使用專屬的 png 圖示，避免 Android Adaptive Icon 造成的嚴重閃退
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      'ic_notification',
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      debugPrint("[BatteryMonitorService] 準備初始化通知套件...");
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      debugPrint("[BatteryMonitorService] 通知套件初始化成功！");
    } catch (e) {
      debugPrint("[BatteryMonitorService] 🚨 通知套件初始化失敗: $e");
    }

    // 2. 啟動全域背景檢查
    debugPrint("[BatteryMonitorService] 準備啟動 _startMonitoring()...");
    _startMonitoring();

    // 3. 延遲請求通知權限，確保主畫面已經渲染完成，避免啟動時找不到 Activity 而卡死
    if (defaultTargetPlatform == TargetPlatform.android) {
      Future.delayed(const Duration(seconds: 2), () async {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      });
    }
  }

  void _startMonitoring() {
    _checkBattery(); // 啟動時先檢查一次
    _timer?.cancel();
    // 全域計時器：只要 App 還在記憶體中，就會跨頁面持續執行
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkBattery();
    });
  }

  Future<void> _checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final limit = AppParams.batteryAlertLimit;

      debugPrint("[全域電量監控] 檢查中... 目前 $level% / 設定 $limit% (已警告過: $_hasAlerted)");

      if (level < limit) {
        // 如果「還沒警告過」，或者是「電量比上次警告時還要低 (又掉電了)」，就發出通知
        if (!_hasAlerted || (_lastAlertedLevel != null && level < _lastAlertedLevel!)) {
          _showBatteryNotification(level, limit);
          _hasAlerted = true; // 標記已警告
          _lastAlertedLevel = level; // 記下這次警告的電量
        }
      } else {
        _lastAlertedLevel = null; // 電量回升，清除記錄
        _hasAlerted = false; // 電量回升，重置警告狀態
      }
    } catch (e) {
      debugPrint("背景取得電量失敗: $e");
    }
  }

  // 提供給 UI 呼叫：當使用者在設備狀態頁面修改 % 數時，重置警告狀態
  void resetAlert() {
    _hasAlerted = false;
    _lastAlertedLevel = null;
    _checkBattery();
  }

  Future<void> _showBatteryNotification(int level, int limit) async {
    // 將震動陣列獨立提取，並修改毫秒數，避免與公開範例重疊
    final Int64List customVibration = Int64List.fromList(<int>[0, 600, 300, 600]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'battery_alert_channel_v3', // 順便更新 ID 確保新設定生效
      '系統電量警告',
      channelDescription: '當設備電量低於您的設定值時，發出推播通知',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: customVibration,
    );
    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    try {
      await _flutterLocalNotificationsPlugin.show(0, '⚠️ 電量警告', '目前電量 ($level%) 低於設定值 ($limit%)', platformDetails);
    } catch (e) {
      debugPrint("發送通知失敗: $e");
    }
  }
}
