import 'package:flutter/material.dart';
import 'line_contacts_page.dart';
import 'phone_contacts_page.dart';
import 'sound_control_page.dart';
import 'launch_app_page.dart';

class MainScaffoldPage extends StatefulWidget {
  const MainScaffoldPage({super.key});

  @override
  State<MainScaffoldPage> createState() => _MainScaffoldPageState();
}

class _MainScaffoldPageState extends State<MainScaffoldPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LineContactsPage(),
    PhoneContactsPage(),
    SoundControlPage(),
    LaunchAppPage(), // 加入新建立的啟動軟體頁面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        iconSize: 40.0,
        selectedFontSize: 20.0,
        unselectedFontSize: 18.0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Phone'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Line'),
          BottomNavigationBarItem(icon: Icon(Icons.volume_up), label: '聲音'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: '軟體'),
        ],
      ),
    );
  }
}
