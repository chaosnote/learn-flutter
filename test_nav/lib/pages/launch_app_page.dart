import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'package:android_intent_plus/android_intent.dart';

class LaunchAppPage extends StatefulWidget {
  const LaunchAppPage({super.key});

  @override
  State<LaunchAppPage> createState() => _LaunchAppPageState();
}

class _LaunchAppPageState extends State<LaunchAppPage> {
  // 用來記錄每個 App 的安裝狀態 (key: package name, value: 是否已安裝)
  // null 代表還在檢查中
  final Map<String, bool?> _installedStatus = {};

  @override
  void initState() {
    super.initState();
    _checkAllAppsStatus();
  }

  // 畫面載入時，批次檢查所有軟體的安裝狀態
  Future<void> _checkAllAppsStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final packages = [
      'jp.naver.line.android',
      'com.facebook.katana',
      'com.google.android.youtube',
    ];

    for (final pkg in packages) {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_main',
        category: 'android.intent.category.LAUNCHER',
        package: pkg,
      );
      final bool isInstalled = await intent.canResolveActivity() ?? false;
      if (mounted) {
        setState(() => _installedStatus[pkg] = isInstalled);
      }
    }
  }

  // 共用的啟動/檢查邏輯
  Future<void> _launchOrInstallApp(String packageName) async {
    // 平台防呆機制
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此功能僅支援 Android 設備')));
      return;
    }

    // 設定用來「啟動 App」的 Intent
    final AndroidIntent launchIntent = AndroidIntent(
      action: 'action_main',
      category: 'android.intent.category.LAUNCHER',
      package: packageName,
    );

    // 檢查這個啟動 Intent 是否有效 (代表已安裝)
    final bool isInstalled = await launchIntent.canResolveActivity() ?? false;

    if (isInstalled) {
      // 已安裝：直接啟動該 App
      await launchIntent.launch();
    } else {
      // 未安裝：導引至 Google Play 商店
      final AndroidIntent storeIntent = AndroidIntent(
        action: 'action_view',
        data: 'market://details?id=$packageName',
      );
      await storeIntent.launch();
    }
  }

  // 建立清單項目的共用小工具
  Widget _buildAppTile({
    required String title,
    required String packageName,
    required IconData icon,
    required Color iconColor,
  }) {
    // 根據檢查結果決定要顯示的副標題文字
    String subtitleText;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      subtitleText = '僅支援 Android 設備';
    } else {
      final isInstalled = _installedStatus[packageName];
      if (isInstalled == null) {
        subtitleText = '檢查狀態中...';
      } else {
        subtitleText = isInstalled ? '啟動' : '前往 Play 商店安裝';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: iconColor),
        title: Text(title, style: const TextStyle(fontSize: 20)),
        subtitle: Text(
          subtitleText,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _launchOrInstallApp(packageName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('啟動軟體')),
      body: ListView(
        children: [
          _buildAppTile(
            title: 'Line',
            packageName: 'jp.naver.line.android',
            icon: Icons.chat,
            iconColor: Colors.green,
          ),
          _buildAppTile(
            title: 'Facebook',
            packageName: 'com.facebook.katana',
            icon: Icons.facebook,
            iconColor: Colors.blue,
          ),
          _buildAppTile(
            title: 'YouTube',
            packageName: 'com.google.android.youtube',
            icon: Icons.video_library,
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
