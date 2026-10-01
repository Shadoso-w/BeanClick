/// 应用身份信息（名称与版本的**唯一来源**）。
///
/// ## 为什么要有这个文件
///
/// 版本号此前散在三处（`ExportDocument.appVersion` 的默认值、设置页的
/// 「关于豆刻」、设置页底部），结果 0.2.0 的包在界面上和导出的备份里
/// 都还自称 `0.1.0` —— 用户能直接看到。
///
/// 现在统一从这里取，并用 `test/domain/app_info_test.dart` 把
/// [kAppVersion] 与 `pubspec.yaml` 的 `version:` 钉在一起：
/// **只改 pubspec 而忘了改这里，测试会直接红。**
///
/// 之所以不做成运行时读 `pubspec.yaml`：那个文件不会被打进 APK，
/// Dart 侧拿不到（要拿就得引 `package_info_plus` 之类的插件，
/// 对这个需求来说不划算）。
library;

/// 展示用名称。
const String kAppName = '豆刻 BeanClick';

/// 一句话定位（「关于」里用）。
const String kAppTagline = '本地优先，无追踪';

/// 展示用版本号：对应 `pubspec.yaml` 的 `version:`，**不含** `+构建号`。
const String kAppVersion = '0.3.0';
