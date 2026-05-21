import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _fileContent = '';
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
  drive.DriveApi? _driveApi;

  /// 執行核心驗證邏輯，更新 [_driveApi] 實例。
  /// 成功回傳 true，失敗或取消回傳 false。
  Future<bool> _performAuth() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final headers = await account.authHeaders;
        final authenticateClient = GoogleAuthClient(headers);
        _driveApi = drive.DriveApi(authenticateClient);
        debugPrint('Google Auth 驗證成功');
        return true;
      }
      return false; // 使用者取消登入
    } catch (e) {
      debugPrint('Google Auth 驗證失敗: $e');
      _driveApi = null; // 確保失敗時 api 為 null
      return false;
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    try {
      final success = await _performAuth();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('驗證成功')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 確保 Drive API 已準備就緒，若需要則執行驗證。
  /// 若 API 準備就緒回傳 true，否則回傳 false。
  Future<bool> _ensureApiReady() async {
    if (_driveApi != null) return true;
    return await _performAuth();
  }

  Future<void> _readFile() async {
    setState(() => _isLoading = true);
    try {
      if (!await _ensureApiReady()) {
        debugPrint('驗證未完成，取消讀取動作');
        return;
      }

      final fileList = await _driveApi!.files.list(q: "name = 'test_google_driver.json' and trashed = false");

      if (fileList.files == null || fileList.files!.isEmpty) {
        setState(() {
          _fileContent = '';
        });
        debugPrint('無檔案，變數已重置為空字串');
      } else {
        final fileId = fileList.files!.first.id!;
        final drive.Media response =
            await _driveApi!.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

        final content = await utf8.decodeStream(response.stream);
        setState(() {
          _fileContent = content;
        });
        debugPrint('讀取檔案內容: $_fileContent');
      }
    } catch (e) {
      debugPrint('讀取失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _writeFile() async {
    setState(() => _isLoading = true);
    try {
      if (!await _ensureApiReady()) {
        debugPrint('驗證未完成，取消寫入動作');
        return;
      }
      final content = jsonEncode({"Time": DateTime.now().toIso8601String()});
      final stream = Future.value(utf8.encode(content)).asStream().asBroadcastStream();
      final media = drive.Media(stream, utf8.encode(content).length);

      final fileList = await _driveApi!.files.list(q: "name = 'test_google_driver.json' and trashed = false");

      if (fileList.files == null || fileList.files!.isEmpty) {
        final driveFile = drive.File()..name = 'test_google_driver.json';
        await _driveApi!.files.create(driveFile, uploadMedia: media);
        debugPrint('建立並寫入檔案成功: $content');
      } else {
        final fileId = fileList.files!.first.id!;
        await _driveApi!.files.update(drive.File(), fileId, uploadMedia: media);
        debugPrint('更新檔案內容成功: $content');
      }
      setState(() {
        _fileContent = content;
      });
    } catch (e) {
      debugPrint('寫入失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: _isLoading ? null : _authenticate, child: const Text('Google Sign Auth 驗證')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _readFile,
              child: const Text('讀取文件 (test_google_driver.json)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _writeFile,
              child: const Text('寫入文件 (test_google_driver.json)'),
            ),
            const SizedBox(height: 32),
            const Text('檔案內容:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(_fileContent.isEmpty ? '目前無檔案內容' : _fileContent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 用於包裝 Google SignIn 的驗證標頭為 HTTP Client，供 googleapis 呼叫使用
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
