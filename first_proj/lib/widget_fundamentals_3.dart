import 'package:flutter/material.dart';

import 'bordered_image.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Row(
        children: [
          BorderedImage(
            image: AssetImage('images/demo.jpg'), // 替換為你的圖片路徑
            borderWidth: 4.0,
            borderColor: Colors.blue,
            borderRadius: BorderRadius.circular(12.0),
            width: 200.0,
            height: 150.0,
          ),
          BorderedImage(
            image: AssetImage('images/demo.jpg'),
            borderWidth: 4.0,
            borderColor: Colors.blue,
            borderRadius: BorderRadius.circular(12.0),
            width: 200.0,
            height: 150.0,
          ),
        ],
      ),
    );
  }
}
