import 'package:flutter/material.dart';

class SoundControlPage extends StatefulWidget {
  const SoundControlPage({super.key});

  @override
  State<SoundControlPage> createState() => _SoundControlPageState();
}

class _SoundControlPageState extends State<SoundControlPage> {
  bool _isSoundOn = true;

  void _toggleMute(bool turnOn) {
    setState(() {
      _isSoundOn = turnOn;
    });

    if (turnOn) {
      debugPrint('開');
    } else {
      debugPrint('關');
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
            Text(
              _isSoundOn ? '目前狀態：聲音已開啟' : '目前狀態：聲音已關閉',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _isSoundOn ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1.8,
                  child: Switch(
                    value: _isSoundOn,
                    onChanged: (value) {
                      _toggleMute(value);
                    },
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
