import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SoundControlPage extends StatefulWidget {
  const SoundControlPage({super.key});

  @override
  State<SoundControlPage> createState() => _SoundControlPageState();
}

class _SoundControlPageState extends State<SoundControlPage> with WidgetsBindingObserver {
  bool _isSoundOn = true;

  // 建立與 Android 原生溝通的通道 (Channel 名稱可自訂，但兩邊必須一致)
  static const platform = MethodChannel('com.example.test_nav/volume');

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this); // 註冊生命週期觀察者
    _fetchCurrentVolume(); // 畫面載入時先取得一次目前音量
  }

  @override
  void dispose() {
    // 移除生命週期觀察者，避免記憶體流失
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 當 App 從背景回到前景（例如關螢幕後再打開、從其他 App 切換回來），重新取得音量
    if (state == AppLifecycleState.resumed) {
      _fetchCurrentVolume();
    }
  }

  Future<void> _fetchCurrentVolume() async {
    try {
      // 呼叫 Android 的 getVolume 方法，並等待回傳的整數值
      final int volume = await platform.invokeMethod('getVolume');
      setState(() {
        _isSoundOn = volume > 0; // 當音量大於 0 時，將開關狀態設為 true (開啟)
      });
    } on PlatformException catch (e) {
      debugPrint("無法取得音量: '${e.message}'.");
    }
  }

  Future<void> _toggleMute(bool turnOn) async {
    setState(() {
      _isSoundOn = turnOn;
    });

    try {
      // 呼叫 Android 原生方法，並傳遞目前的開關狀態
      await platform.invokeMethod('setVolume', {'isSoundOn': turnOn});

      // 設定完音量後，重新取得最新的音量數值來更新畫面
      await _fetchCurrentVolume();
    } on PlatformException catch (e) {
      debugPrint("無法控制音量: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('聲音控制', style: TextStyle(fontSize: 28))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("目前狀態", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
            Text(
              _isSoundOn ? '聲音已開啟' : '聲音已關閉',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: _isSoundOn ? Colors.green : Colors.red,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 使用 SizedBox 手動幫放大後的 Switch 撐出排版空間
                // 原本的 Switch 大小約為 60x40，放大 3 倍後大約需要 180x120 的佔位空間
                SizedBox(
                  width: 180,
                  height: 120,
                  child: Transform.scale(
                    scale: 3,
                    child: Switch(
                      value: _isSoundOn,
                      onChanged: (value) {
                        _toggleMute(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
