import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DeviceStatusPage extends StatefulWidget {
  const DeviceStatusPage({super.key});

  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

class _DeviceStatusPageState extends State<DeviceStatusPage> with WidgetsBindingObserver {
  // === 聲音控制 ===
  bool _isSoundOn = true;
  static const platform = MethodChannel('com.example.test_nav/volume');

  // === 電池狀態 ===
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  final TextEditingController _batteryLimitController = TextEditingController(text: '20');
  Timer? _batteryCheckTimer;
  bool _hasAlerted = false; // 防止一直重複跳出警告

  // === WiFi 狀態 ===
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fetchCurrentVolume();
    _initBattery();
    _initConnectivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _batteryCheckTimer?.cancel();
    _batteryLimitController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCurrentVolume();
      _checkBatteryLevel();
      _initConnectivity(); // 背景回來時也重新拿一次網路狀態
    }
  }

  // --- 聲音控制邏輯 ---
  Future<void> _fetchCurrentVolume() async {
    try {
      final int volume = await platform.invokeMethod('getVolume');
      if (mounted) {
        setState(() {
          _isSoundOn = volume > 0;
        });
      }
    } on PlatformException catch (e) {
      debugPrint("無法取得音量: '${e.message}'.");
    }
  }

  Future<void> _toggleMute(bool turnOn) async {
    setState(() {
      _isSoundOn = turnOn;
    });
    try {
      await platform.invokeMethod('setVolume', {'isSoundOn': turnOn});
      await _fetchCurrentVolume();
    } on PlatformException catch (e) {
      debugPrint("無法控制音量: '${e.message}'.");
    }
  }

  // --- 電池邏輯 ---
  void _initBattery() {
    _checkBatteryLevel();
    // 設定每 30 秒定期檢查電量
    _batteryCheckTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkBatteryLevel();
    });
  }

  Future<void> _checkBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
        _checkBatteryAlert();
      }
    } catch (e) {
      debugPrint("無法取得電量: $e");
    }
  }

  void _checkBatteryAlert() {
    final limitText = _batteryLimitController.text;
    final limit = int.tryParse(limitText);

    if (limit != null && _batteryLevel < limit) {
      // 低於門檻且尚未警告過，才跳出 SnackBar 提醒
      if (!_hasAlerted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 警告：目前電量 ($_batteryLevel%) 低於設定值 ($limit%)'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        _hasAlerted = true; // 標記已警告
      }
    } else {
      // 電量回升或修改了更低的設定值，重置警告狀態
      _hasAlerted = false;
    }
  }

  // --- WiFi 邏輯 ---
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } on PlatformException catch (e) {
      debugPrint("無法取得網路狀態: $e");
    }

    // 監聽網路變化 (自動偵測 WiFi 開關)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (mounted) {
      setState(() {
        _connectionStatus = result;
      });
    }
  }

  bool get _isWifiConnected => _connectionStatus.contains(ConnectivityResult.wifi);

  // --- 畫面構建 ---
  @override
  Widget build(BuildContext context) {
    // 用 GestureDetector 包覆，讓使用者點擊空白處時自動收起鍵盤
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent, // 確保空白處點擊事件不會干擾底層滑動
      child: Scaffold(
        appBar: AppBar(title: const Text('設備狀態', style: TextStyle(fontSize: 28))),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // 強制開啟滑動效果
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 64.0), // 底部多增加一點留白，避免最下方的內容貼齊邊緣
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // 使用者滑動畫面時自動收起鍵盤
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVolumeCard(),
              const SizedBox(height: 16),
              _buildBatteryCard(),
              const SizedBox(height: 16),
              _buildWifiCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          _isSoundOn ? Icons.volume_up : Icons.volume_off,
          size: 36,
          color: _isSoundOn ? Colors.green : Colors.grey,
        ),
        title: const Text("聲音", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        trailing: Switch(value: _isSoundOn, onChanged: _toggleMute),
      ),
    );
  }

  Widget _buildBatteryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              _batteryLevel > 20 ? Icons.battery_full : Icons.battery_alert,
              size: 36,
              color: _batteryLevel > 20 ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 16),
            Text('$_batteryLevel%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('低於 ', style: TextStyle(fontSize: 16)),
            SizedBox(
              width: 50,
              child: TextField(
                controller: _batteryLimitController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                onChanged: (_) => _checkBatteryAlert(),
              ),
            ),
            const Text(' % 提醒', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          _isWifiConnected ? Icons.wifi : Icons.wifi_off,
          size: 36,
          color: _isWifiConnected ? Colors.green : Colors.grey,
        ),
        title: Text(
          _isWifiConnected ? 'WiFi 已連線' : 'WiFi 未連線',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
