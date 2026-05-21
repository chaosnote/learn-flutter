# learn-flutter

學習

```
建立空專案
flutter create --platforms=android 專案名稱

未來想增加 web 平台、切換至 專案根目錄
flutter create --platforms=web,android .
```

### 官方學習 - first_app

https://codelabs.developers.google.com/codelabs/flutter-codelab-first?hl=zh-tw#0

### 測試彈跳視窗/通知訊息 - test-alert

### 測試雲端服務 - test-google-driver

```
1、申請 Google Cloud 專案
  ∟ IAM 與管理
  ∟ 建立專案(對應: 資源管理)
```

```
2、API 和服務
  ∟ OAuth 同意畫面
  ∟ 用戶端
  ∟ SHA1

cd Flutter Project/android
set JAVA_HOME="install path\Android\Android Studio\jbr"
gradlew signingReport
```

### 官方學習 - test_media