import 'package:flutter/material.dart';

class PhoneContactsPage extends StatefulWidget {
  const PhoneContactsPage({super.key});

  @override
  State<PhoneContactsPage> createState() => _PhoneContactsPageState();
}

class _PhoneContactsPageState extends State<PhoneContactsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone 聯絡人'),
      ),
      body: const Center(
        child: Text('這裡將實作 Phone 聯絡人清單'),
      ),
    );
  }
}
