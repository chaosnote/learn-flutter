import 'dart:io';

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '錄音與播放測試',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      home: const MediaHomePage(),
    );
  }
}

enum RecordState { idle, recording, stopped }

class MediaHomePage extends StatefulWidget {
  const MediaHomePage({super.key});

  @override
  State<MediaHomePage> createState() => _MediaHomePageState();
}

class _MediaHomePageState extends State<MediaHomePage> {
  // 錄音狀態與播放清單資料
  RecordState _recordState = RecordState.idle;
  final List<String> _playlist = [];
  String? _playingItem;

  late final FlutterSoundRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  String? _tempRecordPath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingItem = null;
        });
      }
    });

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _audioRecorder.openRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ================= 錄音相關操作 =================
  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要麥克風權限才能錄音')));
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    // 將副檔名改為 .aac
    _tempRecordPath = '${dir.path}/temp_record.aac';

    await _audioRecorder.startRecorder(
      toFile: _tempRecordPath,
      codec: Codec.aacADTS, // 明確指定使用 AAC 編碼格式
    );

    setState(() {
      _recordState = RecordState.recording;
    });
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stopRecorder();
    setState(() {
      _recordState = RecordState.stopped;
    });
  }

  Future<void> _cancelRecording() async {
    if (_audioRecorder.isRecording) {
      await _audioRecorder.stopRecorder();
    }
    if (_tempRecordPath != null) {
      final file = File(_tempRecordPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
      _tempRecordPath = null;
    }
    setState(() {
      _recordState = RecordState.idle;
    });
  }

  Future<void> _saveRecording() async {
    if (_tempRecordPath == null) return;

    final dir = await getApplicationDocumentsDirectory();
    // 儲存的檔案副檔名也同步改為 .aac
    final String newRecordName = '錄音檔_${DateTime.now().toIso8601String().replaceAll(':', '').split('.')[0]}.aac';
    final String newPath = '${dir.path}/$newRecordName';

    final tempFile = File(_tempRecordPath!);
    if (tempFile.existsSync()) {
      tempFile.copySync(newPath);
      tempFile.deleteSync();
    }

    setState(() {
      _playlist.add(newPath);
      _recordState = RecordState.idle;
      _tempRecordPath = null;
    });
  }

  // ================= 播放清單相關操作 =================
  Future<void> _startPlaying(String item) async {
    await _audioPlayer.play(DeviceFileSource(item));
    setState(() {
      _playingItem = item;
    });
  }

  Future<void> _stopPlaying() async {
    await _audioPlayer.stop();
    setState(() {
      _playingItem = null;
    });
  }

  Future<void> _deleteItem(String item) async {
    if (_playingItem == item) {
      await _stopPlaying();
    }

    final file = File(item);
    if (file.existsSync()) {
      file.deleteSync();
    }

    setState(() {
      _playlist.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: const Text('錄音與播放程式')),
      body: Column(children: [_buildRecorderSection(), const Divider(height: 1), _buildPlaylistSection()]),
    );
  }

  // 建構上方錄音控制區塊
  Widget _buildRecorderSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('錄音控制', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _recordState == RecordState.idle ? _startRecording : null,
                icon: const Icon(Icons.mic),
                label: const Text('開始'),
              ),
              ElevatedButton.icon(
                onPressed: _recordState == RecordState.recording ? _stopRecording : null,
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _recordState != RecordState.idle ? _cancelRecording : null,
                icon: const Icon(Icons.cancel),
                label: const Text('取消'),
              ),
              FilledButton.icon(
                onPressed: _recordState == RecordState.stopped ? _saveRecording : null,
                icon: const Icon(Icons.save),
                label: const Text('儲存'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 建構下方播放清單區塊
  Widget _buildPlaylistSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('播放清單 (${_playlist.length} 個物件)', style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: _playlist.isEmpty
                ? const Center(child: Text('目前沒有錄音檔'))
                : ListView.builder(
                    itemCount: _playlist.length,
                    itemBuilder: (context, index) {
                      final item = _playlist[index];
                      final isPlaying = _playingItem == item;
                      return ListTile(
                        leading: CircleAvatar(child: Icon(isPlaying ? Icons.volume_up : Icons.audio_file)),
                        title: Text(item.split('/').last), // 使用 split 切割路徑，只取最後面的檔名
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPlaying)
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.green),
                                onPressed: () => _startPlaying(item),
                                tooltip: '開始',
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.stop, color: Colors.orange),
                                onPressed: _stopPlaying,
                                tooltip: '停止',
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(item),
                              tooltip: '刪除',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
