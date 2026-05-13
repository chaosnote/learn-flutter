import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'pages/main_scaffold_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint(kIsWeb ? "網頁版" : "非網頁版");

    return MaterialApp(
      title: 'Flutter Nav Test',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange), useMaterial3: true),
      home: const MainScaffoldPage(),
    );
  }
}
