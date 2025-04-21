import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '動態群組與項目範例',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<_GroupData> groups = [
    _GroupData(
      nameController: TextEditingController(),
      items: [
        _ItemData(typeController: TextEditingController()), // 初始群組的初始項目
      ],
    ), // 初始群組
  ];
  final List<String> typeOptions = ['', 'String', 'Integer', 'Boolean', 'Double'];

  void _addGroup() {
    setState(() {
      groups.add(_GroupData(
        nameController: TextEditingController(),
        items: [_ItemData(typeController: TextEditingController())], // 新增群組時包含一個初始項目
      ));
    });
  }

  void _removeGroup(int index) {
    setState(() {
      groups.removeAt(index);
    });
  }

  void _addItemToGroup(int groupIndex) {
    setState(() {
      groups[groupIndex].items.add(_ItemData(typeController: TextEditingController()));
    });
  }

  void _removeItemFromGroup(int groupIndex, int itemIndex) {
    setState(() {
      groups[groupIndex].items.removeAt(itemIndex);
    });
  }

  void _onTypeSelected(String? newValue, int groupIndex, int itemIndex) {
    if (newValue != null && newValue.isNotEmpty) {
      setState(() {
        groups[groupIndex].items[itemIndex].typeController.text = newValue;
      });
    } else {
      setState(() {
        groups[groupIndex].items[itemIndex].typeController.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('動態群組與項目範例'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...groups.asMap().entries.map((groupEntry) {
              int groupIndex = groupEntry.key;
              _GroupData group = groupEntry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('群組 ${groupIndex + 1}: ( 名稱: ${group.nameController.text.isNotEmpty ? group.nameController.text : '未命名'} )', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: group.nameController,
                    decoration: const InputDecoration(
                      labelText: '群組名稱',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ...group.items.asMap().entries.map((itemEntry) {
                    int itemIndex = itemEntry.key;
                    _ItemData item = itemEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Text('變數', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: '文字輸入框',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          const Text('型別', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextField(
                              controller: item.typeController,
                              decoration: const InputDecoration(
                                labelText: '文字輸入框',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          DropdownButton<String>(
                            value: item.typeController.text.isEmpty ? '' : item.typeController.text,
                            hint: const Text('選擇型別'),
                            items: typeOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              _onTypeSelected(newValue, groupIndex, itemIndex);
                            },
                          ),
                          const SizedBox(width: 16.0),
                          ElevatedButton(
                            onPressed: () => _removeItemFromGroup(groupIndex, itemIndex),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('刪除', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _addItemToGroup(groupIndex),
                      child: const Text('增加一筆'),
                    ),
                  ),
                  const Divider(height: 32.0),
                ],
              );
            }),
            ElevatedButton(
              onPressed: _addGroup,
              child: const Text('增加一個群組'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupData {
  TextEditingController nameController = TextEditingController();
  List<_ItemData> items = [];

  _GroupData({required this.nameController, required this.items});
}

class _ItemData {
  TextEditingController typeController = TextEditingController();

  _ItemData({required this.typeController});
}