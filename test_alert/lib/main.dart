import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 建立全域的通知外掛實例
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  // 確保 Flutter 綁定初始化，因為我們在 runApp 之前有非同步操作
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Android 的通知設定 (使用預設的 app icon)
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // 針對 Android 13 (API 33) 以上，請求發送通知的權限
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Future<void> _showAlertDialog() async {
    // 加上 <bool> 宣告我們預期這個 Dialog 會回傳 bool，並使用 await 等待使用者操作
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('系統提示'),
          content: const Text('這是一個 AlertDialog，適合用來要求使用者確認操作。\n\n你確定要執行此操作嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // 點擊取消，回傳 false
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // 點擊確定，回傳 true
              child: const Text('確定'),
            ),
          ],
        );
      },
    );

    // 根據回傳結果做後續處理
    if (result == true) {
      Fluttertoast.showToast(msg: "你點擊了確定 (true)");
    } else if (result == false) {
      Fluttertoast.showToast(msg: "你點擊了取消 (false)");
    } else {
      Fluttertoast.showToast(msg: "你點擊了對話框外部關閉 (null)");
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('這是一個 ModalBottomSheet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('通常從底部滑出，適合提供更多操作選項或表單。'),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('關閉')),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMaterialBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.all(16),
        content: const Text('這是一個 MaterialBanner，適合顯示需要使用者注意的持續性訊息。'),
        leading: const Icon(Icons.warning, color: Colors.orange),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  void _showToast() {
    Fluttertoast.showToast(
      msg: "這是一個原生的 Android Toast",
      toastLength: Toast.LENGTH_SHORT, // 控制顯示時間長短
      gravity: ToastGravity.BOTTOM, // 控制出現的位置
      timeInSecForIosWeb: 1, // 針對 iOS/Web 的顯示秒數
      backgroundColor: Colors.black54, // 背景顏色 (iOS/Web 用，Android 預設由系統決定)
      textColor: Colors.white, // 文字顏色
      fontSize: 16.0, // 文字大小
    );
  }

  Future<void> _showSystemNotification() async {
    // 設定 Android 通知頻道的細節
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'high_importance_channel', // 頻道 ID
      '重要通知', // 頻道名稱
      channelDescription: '這個頻道用於顯示懸浮的高優先級通知',
      importance: Importance.max, // ★ 關鍵 1：重要性設為最高，才會出現懸浮通知 (Heads-up)
      priority: Priority.high, // ★ 關鍵 2：優先級設為高
      ticker: '您有一條新訊息',
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // 通知的 ID
      '收到一則新訊息',
      '這就是 Android 原生的懸浮系統通知！你可以在待機時滑掉它。',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: _showAlertDialog, child: const Text('顯示 AlertDialog')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showBottomSheet, child: const Text('顯示 BottomSheet')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showMaterialBanner, child: const Text('顯示 MaterialBanner')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showToast, child: const Text('顯示 Toast')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showSystemNotification, child: const Text('顯示系統通知 (Heads-up)')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
