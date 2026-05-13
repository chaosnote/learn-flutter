import 'package:flutter/material.dart';

class LineContactsPage extends StatefulWidget {
  const LineContactsPage({super.key});

  @override
  State<LineContactsPage> createState() => _LineContactsPageState();
}

class _LineContactsPageState extends State<LineContactsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Line 聯絡人')),
      body: const Center(child: Text('這裡將實作 Line 聯絡人清單')),
    );
  }
}
