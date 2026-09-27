# 开发环境搭建（Windows）

本项目在 Windows 上使用**便携式（免安装）工具链**，全部放在 `D:\devtools`，
Android SDK 放在 `D:\Android\Sdk`。不依赖任何安装程序，也不写入 `C:\` 全局目录
（除用户级环境变量外）。

---

## 1. 工具链布局

| 组件 | 版本 | 路径 |
|---|---|---|
| Git | 2.55.0.5 | `D:\devtools\Git` |
| JDK | Temurin 17.0.20.1+1 | `D:\devtools\jdk17` |
| Flutter SDK | 3.47.5 (Dart 3.13.4) | `D:\devtools\flutter` |
| Android SDK | cmdline-tools latest | `D:\Android\Sdk` |
| Gradle 缓存 | — | `D:\devtools\gradle-home` |
| 工程 | — | `D:\BeanClick` |

选便携布局的原因：Flutter + Android SDK + Gradle 缓存合计会超过 10GB，
放在 D 盘可以避免撑爆系统盘；全部解压式安装也便于整体删除或迁移。

---

## 2. 环境变量（用户级）

安装脚本已写入以下**用户级**环境变量（不需要管理员权限）：

| 变量 | 值 |
|---|---|
| `JAVA_HOME` | `D:\devtools\jdk17` |
| `ANDROID_HOME` | `D:\Android\Sdk` |
| `ANDROID_SDK_ROOT` | `D:\Android\Sdk` |
| `GRADLE_USER_HOME` | `D:\devtools\gradle-home` |
| `PUB_HOSTED_URL` | `https://pub.flutter-io.cn` |
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` |
| `PATH` | 追加 `D:\devtools\flutter\bin`、`D:\devtools\Git\cmd`、`D:\devtools\jdk17\bin`、`D:\Android\Sdk\platform-tools`、`D:\Android\Sdk\cmdline-tools\latest\bin` |

> `PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL` 指向国内镜像，用于加速
> `flutter pub get` 与 SDK 组件下载。若镜像异常，清空这两个变量即可回落到官方源。

**环境变量生效需要重开终端。** 当前已打开的终端可以临时加载：

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
```

---

## 3. 从零重建工具链

如果换了机器或需要重装，按顺序执行：

```powershell
# 1. 目录
New-Item -ItemType Directory -Force D:\devtools\_dl, D:\devtools\_tmp, D:\Android\Sdk | Out-Null

# 2. Git（便携版自解压）
Invoke-WebRequest 'https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/PortableGit-2.55.0.5-64-bit.7z.exe' -OutFile D:\devtools\_dl\PortableGit.7z.exe
& D:\devtools\_dl\PortableGit.7z.exe -oD:\devtools\Git -y

# 3. JDK 17（清华 Adoptium 镜像）
Invoke-WebRequest 'https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/x64/windows/OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip' -OutFile D:\devtools\_dl\jdk17.zip
Expand-Archive D:\devtools\_dl\jdk17.zip -DestinationPath D:\devtools\_tmp -Force
Move-Item D:\devtools\_tmp\jdk-17.0.20.1+1 D:\devtools\jdk17

# 4. Flutter SDK
Invoke-WebRequest 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.5-stable.zip' -OutFile D:\devtools\_dl\flutter.zip
Expand-Archive D:\devtools\_dl\flutter.zip -DestinationPath D:\devtools -Force

# 5. Android cmdline-tools
Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip' -OutFile D:\devtools\_dl\cmdline-tools.zip
Expand-Archive D:\devtools\_dl\cmdline-tools.zip -DestinationPath D:\devtools\_tmp\cmdline -Force
New-Item -ItemType Directory -Force D:\Android\Sdk\cmdline-tools | Out-Null
Move-Item D:\devtools\_tmp\cmdline\cmdline-tools D:\Android\Sdk\cmdline-tools\latest
```

---

## 4. 常用命令

```powershell
flutter doctor -v                # 体检
flutter pub get                  # 拉依赖
dart run build_runner build --delete-conflicting-outputs   # 生成 Drift 代码
flutter analyze                  # 静态分析（PR 必须通过）
flutter test                     # 单元 + Widget 测试（PR 必须通过）
flutter run                      # 跑真机/模拟器
flutter build apk --release      # 出包
```

修改了 Drift 表结构后**必须**重跑 `build_runner`，否则 `*.g.dart` 与表定义不一致。

---

## 5. 测试策略

| 层级 | 覆盖内容 |
|---|---|
| 单元测试 | 数据模型、导出（JSON/CSV）、统计计算、**余量扣减** |
| Widget 测试 | 表单、列表、搜索、主题切换 |
| 真机测试 | 低端机、中端机、暗黑模式 |
| 内测 | GitHub Releases APK + Issue 反馈 |

每个 P0 功能都必须有对应验收用例，清单见开发手册附录 A。

---

## 6. 目录结构

```text
D:\BeanClick
  docs/            开发手册、开发环境、数据模型、隐私政策、更新日志
  lib/
    app.dart       根 MaterialApp、主题（咖啡棕 + 米白/深棕黑）
    main.dart      入口：先开库，再 override databaseProvider 后 runApp
    core/widgets/  通用组件（EmptyState 等）
    domain/        纯 Dart 领域层：enums.dart、entities.dart、settings_keys.dart
    data/
      database.dart  一行内包含：类型转换器 + 表定义 + AppDatabase（+ database.g.dart）
      mappers.dart   行对象 ↔ 领域实体
      providers.dart Riverpod providers
      repositories/  bean / grinder / brew_log / settings
    features/      按功能切分的 UI（shell / record / beans / stats / settings）
  test/
    helpers/       共用测试脚手架（内存库 + ProviderContainer）
    domain/        实体与派生值测试
    data/          仓储、余量规则、schema 测试
    widget_test.dart  应用外壳冒烟测试
  .github/         Issue/PR 模板、CI 工作流
```

---

## 7. Drift 使用约定（踩过的坑）

这几条是 M1 实际调试出来的，违反任意一条都会产生**很难读的报错**。

### 7.1 表对象必须用数据库实例上的访问器

```dart
// 错：报 "The argument type 'BrewLogs' can't be assigned to
//      the parameter type 'ResultSetImplementation<HasResultSet, dynamic>'"
_db.select(BrewLogs());

// 对
_db.select(_db.brewLogs);
_db.into(_db.brewLogs);
_db.update(_db.brewLogs);
_db.delete(_db.brewLogs);
```

生成的访问器名是**表类名的首字母小写**：`CoffeeBeans` → `_db.coffeeBeans`。

### 7.2 表定义必须和用了自定义类型的代码在同一个 library

`textEnum<ProcessMethod>()`、`.map(const StringListConverter())` 这类写法，
要求生成器能在 `part` 文件里解析到这些类型。**drift_dev 不会把相对导入写进
`*.g.dart`**，所以把表拆到 `tables.dart`、枚举拆到 `enum.dart` 再互相相对导入，
会导致 `database.g.dart` 里出现上百条 `Undefined class`。

因此：**转换器、表定义、`AppDatabase` 全部放在 `lib/data/database.dart` 一个文件里。**
跨文件引用一律用 `package:beanclick/...` 绝对导入。

### 7.3 `app_settings` 的复合主键

`AppSettings` 用 `key` 作主键，写入走 `insertOnConflictUpdate` 实现 upsert。

### 7.4 数据库迁移（改表结构时必读）

`schemaVersion` 目前是 **4**。历史只有 `1 → 4` 一次变化（v2 / v3 从未存在过，
`git log -L` 可以确认）。迁移写在 `lib/data/database.dart` 的 `_upgradeToV4`。

**M2.6（v4）及以后的数据，任何升级都必须保住。** 这件事由工具锁住，不靠记性：

| 文件 | 作用 |
|---|---|
| `test/drift/schemas/drift_schema_v4.json` | v4 的**冻结快照** |
| `test/drift/generated/` | 配套校验代码（由快照生成） |
| `test/data/schema_snapshot_test.dart` | 两个守门用例（见下） |

```powershell
# 改完表结构后重新生成快照与校验代码（两个命令都要跑）
dart run drift_dev schema dump lib/data/database.dart test/drift/schemas
dart run drift_dev schema generate test/drift/schemas test/drift/generated
```

两个守门用例分别挡住两类事故：

1. **改了表却忘了 dump 新快照** → `migrateAndValidate(db, 当前版本)` 逐列比对
   （类型、NOT NULL、DEFAULT、外键、索引都算），失败信息会直接点名
   `Contains the following unexpected entries: xxx_column`。
2. **改了表却没写迁移** → 第二个用例拿 v4 快照灌入真实数据（两支豆子 / 两袋 /
   一条拼配记录 + 用量行 / 一条扩展属性 / 两个改过的设置项），用当前代码打开
   （**真的跑 `onUpgrade`**），再断言数据一条不少、值没变、迁移后余量扣减照常工作。

  它的 `oldVersion` 永远钉在 `4`：以后每次升 `schemaVersion`，这个用例**自动变成
   「v4 → 新版本」的数据保活测试**，不需要改代码。`newVersion` 取的是
   `AppDatabase.schemaVersion`，所以版本一升就会被覆盖到。

三条硬规矩：

1. **`onUpgrade` 必须是逐列迁移**，不能删表重建。用户的数据只有这一份。
2. **搬迁顺序不能变**：先建新表 → 搬数据到新表 → 最后才删旧列。
   旧列一删，数据就没有第二个来源了。
3. **改表必须配一个「旧库升上来」的测试**。v1 → v4 那次的写法见
   `test/data/migration_v1_to_v4_test.dart`：造一个旧版本库（建表语句从旧提交
   dump 出来）、跑迁移、断言数据没丢 **且结构与全新建库完全一致**
   （`PRAGMA table_info` / `foreign_key_list` / `sqlite_master` 对比）。
   只比列名不够，`NOT NULL`、`DEFAULT`、漏建索引都要能测出来。

> 写新迁移时可以先用 `dart run drift_dev schema steps test/drift/schemas lib/data/migrations.dart`
> 生成 `stepByStep` 辅助代码，逐版本搬运更省事。

**为什么 v1 → v4 用 `dropColumn` 而不是 `alterTable` 重建表**：
重建要 DROP 掉父表，而 `coffee_beans` 被 `bean_batches` / `brew_log_beans` /
`brew_logs` 用外键引用着，删父表会触发级联删除，把刚搬好的数据一起删掉。
`ALTER TABLE ... DROP COLUMN` 不动表本身，没有这个风险
（要求 SQLite ≥ 3.35；本项目通过 `sqlite3_flutter_libs` 自带较新的 SQLite，
不受 Android 系统版本限制）。

**造旧库来测迁移**：不要手抄旧建表语句。用 `git worktree` 把旧提交检出到另一个目录，
写个临时的 test 打印 `sqlite_master`：

```dart
final rows = await db.customSelect(
  "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL "
  "AND name NOT LIKE 'sqlite_%' ORDER BY type, name").get();
```

> 工作树里跑 `dart run` 会要求重新下载 sqlite3 原生库（GitHub 直连会超时）。
> 把主仓库的 `.dart_tool\hooks_runner\shared`（以及根目录的 `sqlite3.dll`，
> 它是 gitignore 的）拷过去，然后用 `flutter test`（不是 `dart run`）执行那个临时脚本。

---

## 8. 测试注意事项

### 8.1 测试需要 SQLite 原生库

`flutter test` 在桌面运行，需要能找到 `sqlite3.dll`。本仓库把 DLL 放在工程根目录
（`D:\BeanClick\sqlite3.dll`），Dart 进程启动时会从当前目录加载。

该 DLL 取自 [sqlite.org 官方预编译包](https://www.sqlite.org/download.html)
（`sqlite-dll-win-x64-*.zip`），SQLite 本身属公有领域，可随仓库分发。
升级时替换该文件即可，命令：

```powershell
Invoke-WebRequest 'https://www.sqlite.org/2026/sqlite-dll-win-x64-3530400.zip' -OutFile $env:TEMP\sqlite.zip
Expand-Archive $env:TEMP\sqlite.zip -DestinationPath $env:TEMP\sqlite -Force
Copy-Item $env:TEMP\sqlite\sqlite3.dll D:\BeanClick\sqlite3.dll -Force
```

### 8.2 widget 测试里关库要先拆树并让出若干帧

`AppDatabase.close()` 内部会 `await streamQueries.close()`，而 drift 的流查询
在订阅未全部取消前不会归零。如果 widget 树还挂着，`close()` 会**永久阻塞**——
表现为 `flutter test` 卡死且没有任何输出。

**更阴的一点**：`flutter_test` 的 `_runTestBody` 只在**测试没失败时**才卸载 widget 树：

```dart
if (_pendingExceptionDetails == null) {
  runApp(Container(key: UniqueKey(), child: _postTestMessage)); // 卸载 widget 树
  await pump();
}
```

所以「测试失败 → 树没卸 → tearDown 里 `close()` 永久等待 → 整个进程卡住」。
反过来，不拆树直接 `close()` 在测试通过时**反而能过**——这具有欺骗性，不要依赖。

本项目的做法（见 `test/helpers/widget_harness.dart`）：收尾只把 widget 树换成空树，
让订阅取消；**不 await 关闭**容器与数据库。每个测试各有一个内存库实例，
进程结束时自然回收——用「泄漏一个几 KB 的内存库」换「绝不卡死」。

```dart
testWidgets('...', (tester) async {
  await tester.pumpWidget(harness.app(const BeanClickApp()));
  // ... 断言 ...
  await harness.finish(tester);   // 放在最后一行
});
```

### 8.3 表单测试：字段要先滚入可视区

表单字段在 `ListView` 里，**视口外的控件不会被构建**，`find.byKey` / `find.text`
会直接找不到（而不是"找到了但不可见"）。所以断言前要先滚动：

```dart
await tester.scrollUntilVisible(field, 120, scrollable: find.byType(Scrollable).first);
await tester.ensureVisible(field);
```

另外输入框里的值是放在 `EditableText.controller.text` 里，**不是 `Text` widget**，
`find.text('15')` 找不到它。本项目给关键字段加了 `Key`（`brew.dose`、`bean.name`、
`grinder.brand` 等），测试用 `find.byKey` 定位，比按 hint 文字或按下标更稳。

**`scrollUntilVisible` 只朝一个方向滚。** 它（内部是 `dragUntilVisible`）固定把列表
往下推，所以目标在**上方**时永远滚不到：滚满 50 次后抛 `Bad state: No element`
（不是「找不到控件」那种友好报错）。典型触发场景：先填下面的「粉量」，再回头点上面
豆子那一栏的按钮。

因此 `test/helpers/widget_harness.dart` 给 `WidgetTester` 加了扩展
（`scrollTo` / `fillField` / `readField` / `tapKey` / `tapTextScrolled` /
`tapSaveButton`）：先看控件在不在树里，不在就**先拉回顶部**再往下找，两个方向都能到。

```dart
await tester.fillField('brew.dose', '20');
await tester.tapKey('brew.addPick');     // 这个按钮在上方，也不会失败
await tester.tapSaveButton();
```

### 8.4 内存库测试

仓储测试统一用 `AppDatabase.memory()`（SQLite 内存库），
每次测试独立一份，见 `test/helpers/test_harness.dart`。

### 8.5 fake-async 下真实文件 I/O 不会完成

`testWidgets` 跑在 fake-async 环境里，`await file.writeAsBytes(...)` 之后的回调
**不会来**——测试能跑完，但文件其实没写出来，而且不报错，很容易误判成"功能坏了"。

所以导出的测试分两层：

| 层 | 位置 | 覆盖内容 |
|---|---|---|
| 编码 + 真实落盘 | `test/domain/export_encoder_test.dart`（普通 `test`，不受 fake-async 影响） | JSON 往返、CSV 转义、BOM、写文件、分享失败兜底 |
| UI 接线 | `test/features/export_test.dart`（`testWidgets`） | 弹窗默认值、格式选择、传参、选择被记住 |

widget 层注入一个 `Exporter` 的假实现（`_RecordingExportService`）只记录调用与格式，
不碰文件系统。为此 `ExportService` 抽出了 `Exporter` 接口——
这也是为什么 UI 依赖接口而不是具体类。

### 8.6 测试脚手架的 setUp 执行顺序

flutter_test 里**先注册的 setUp 先执行**。`setUpWidgetTest()` 在 `main()` 顶部就
注册了 `reset`，所以业务测试里后注册的 `setUp` 一定在 reset **之后**才跑。
如果某个覆盖项只在业务 `setUp` 里登记、却指望 reset 时被读到，就会静默失效
（容器里还是旧实例）。

因此 `WidgetTestHarness.useOverrides()` 除了存下构造器，还会**立刻重建容器**。

### 8.7 批次模型下的夹具

批次模型（schema v4）之后，「余量 / 购入总重 / 价格 / 烘焙日期」都在**批次**上，
不在豆子上。测试里不要再手写 `CoffeeBean(remainingGrams: ...)`——那个构造函数
已经没有这些参数了。两个脚手架都提供了组合夹具：

```dart
final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
// a.beanId / a.batchId
await harness.addBrewLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15);
```

断言余量时要落到批次：

```dart
final BeanBatch batch = (await beanRepo.getBatch(a.batchId))!;
expect(batch.remainingGrams, 185);
```

反过来，**UI 保存后要顺手断言批次**。踩过一次：`brew_log_form_page` 一度只写
`brew_logs.doseGrams`、不同步 `brew_log_beans.doseGrams`，于是「编辑粉量」把
`doseGrams` 改了、余量却一分没动，而只断言 `log.doseGrams` 的测试全绿。
现在的做法是表单在 `_save` 里用 `_syncUsages()` 把豆子选择与粉量对齐成用量行。

`tapText` 这类按文字点的辅助函数要先滚动再点：视口外的控件**根本不存在**，
`ensureVisible` 会抛 `Bad state: No element`（不是"找到了但不可见"）。

---

## 9. 发布签名

签名配置在 `android/app/build.gradle.kts`：

- 读 `android/key.properties`（**不入库**，`.gitignore` 已忽略）
- 文件不存在时自动回落到 **debug 签名**，构建不会失败——
  这样新克隆仓库的人和 CI 都能直接 `flutter build`。但那种产物**不能分发**。

`android/key.properties` 格式：

```properties
storeFile=keystore/beanclick-release.p12
storePassword=...
keyAlias=beanclick
keyPassword=...
```

> **路径坑**：`storeFile` 是**相对 `android/`** 的路径，所以 Gradle 里必须用
> `rootProject.file(...)`。若写成 `file(...)`，它会相对 `android/app/` 解析，
> 报 `Keystore file ... not found for signing config 'release'`。

生成正式密钥：

```powershell
$env:Path = 'D:\devtools\jdk17\bin;' + $env:Path
keytool -genkeypair -v `
  -keystore android\keystore\beanclick-release.p12 -storetype PKCS12 `
  -keyalg RSA -keysize 2048 -validity 10950 -alias beanclick
```

两条硬规则：

1. **密钥必须离线备份。** 丢了就无法给已安装用户推送更新，只能让他们卸载重装。
2. **换密钥后必须先卸载旧版**再安装，否则签名冲突（「应用未安装」）。

用 JKS 也行，但 `keytool` 会提示 JKS 是私有旧格式、建议迁到 PKCS12，所以直接用 PKCS12。

---

## 10. 应用图标

图标是**代码画出来的**（`System.Drawing`），没有外部素材，也没有引图标生成器。
几何比例、配色与重新生成方法见 [`tool/README.md`](../tool/README.md)。

改动 `mipmap-*` 后必须重新构建 APK 才生效（编译期资源）。

> 生成脚本本身没有留在仓库里：Windows PowerShell 5.1 会把无 BOM 的 UTF-8 当 ANSI 读，
> 中文注释被解码坏以后会连带把语法解析搞崩（报 `Unexpected token '}'`）。
> `tool/README.md` 里记录了全部参数，需要时重建即可。

---

## 11. 已验证状态（实测）

以下是在本机 `D:\BeanClick` 上真实跑过的结果，可作为回归基线：

| 命令 | 结果 |
|---|---|
| `flutter doctor` | Flutter / Android toolchain / 设备全部通过（Chrome 与 VS 缺失，与安卓无关） |
| `flutter analyze` | `No issues found!`，退出码 0 |
| `dart format --output=none --set-exit-if-changed .` | 0 处改动，退出码 0（CI 同款检查） |
| `dart run build_runner build --delete-conflicting-outputs` | 成功；生成物与仓库里的 `database.g.dart` 完全一致（无 diff） |
| `flutter test` | **264 个测试全部通过**，退出码 0（M2.8 第一批 + M2.7/M2.6） |
| `flutter build apk --release --split-per-abi` | 成功，**1.3 分钟**（M2.8，release 签名） |

包体（验收清单要求 < 30MB）：

| ABI | M1 | M2 | M2.5 | M2.6 | M2.7 | **M2.8** |
|---|---|---|---|---|---|---|
| `app-armeabi-v7a-release.apk` | 16.24 MB | 16.99 MB | 17.21 MB | 17.46 MB | 17.46 MB | **18.40 MB** |
| `app-arm64-v8a-release.apk` | 18.84 MB | 19.46 MB | 19.67 MB | 19.93 MB | 19.93 MB | **20.75 MB** |
| `app-x86_64-release.apk` | 20.16 MB | 20.85 MB | 21.12 MB | 21.32 MB | 21.32 MB | **22.14 MB** |

> M2.8 比 M2.7 大了 **约 0.8 MB**，全部来自 `flutter_localizations`
> （日期/时间选择器的中文本地化数据 + intl 的日期符号表）。
> 换来的是弹窗不再是英文的「September / OK / Cancel」。仍在 30MB 以内。

M2.6 的 APK 实测（`apksigner verify` / `aapt2 dump badging`）：

- 签名：`CN=BeanClick`，SHA-256 `d967a4c0…6d51`（内测密钥，与 M2.5 同一把，
  可以直接覆盖安装以验证迁移）
- `versionName 0.1.0`、`versionCode 2001`、`minSdk 24`、`targetSdk 36`、应用名 `豆刻`

### 构建相关的两个坑

**① 残留的 Gradle 守护进程会让构建慢到不可用。**
有一次 `assembleRelease` 耗时 **26741s（约 7.4 小时）**，排查发现是一个从数小时前
就一直挂着的 `java`（Gradle daemon）在拖后腿。清掉后同样的构建只要 **2~5 分钟**。
构建异常慢时先看一眼：

```powershell
Get-Process java | Select-Object Id, CPU, StartTime
Get-Process java | Stop-Process -Force   # 之后重新构建
```

**② Kotlin 增量缓存会锁不住，导致构建失败。**
现象是构建在十几秒内失败，报：

```text
Execution failed for task ':share_plus:compileReleaseKotlin'.
> java.lang.Exception: Could not close incremental caches in
  build\share_plus\kotlin\compileReleaseKotlin\cacheable\caches-jvm\jvm\kotlin:
  class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
```

清 `build\share_plus` 只能临时绕开，下次还会犯。本项目已在
`android/gradle.properties` 里关闭 Kotlin 增量编译：

```properties
kotlin.incremental=false
```

代价是增量构建略慢，换来构建稳定。换机器后若想恢复，删掉这一行即可。

### 镜像相关

| 用途 | 源 | 备注 |
|---|---|---|
| Flutter SDK / 引擎产物 | `https://storage.flutter-io.cn` | 约 10 MB/s，官方 `storage.googleapis.com` 仅约 120 KB/s |
| Pub 包 | `https://pub.flutter-io.cn` | 由 `PUB_HOSTED_URL` 控制 |
| Git for Windows | `https://registry.npmmirror.com/-/binary/git-for-windows/` | 官方 GitHub Releases 极慢 |
| Gradle 发行包 | `https://mirrors.cloud.tencent.com/gradle/` | **官方 `services.gradle.org` 完全不可达（0 KB/s）**，见 `android/gradle/wrapper/gradle-wrapper.properties` |
| JDK 17 | `https://mirrors.tuna.tsinghua.edu.cn/Adoptium/` | |
| Android SDK 组件 | `https://googledownloads.cn/` | 由 sdkmanager 自动走 Google 官方 CDN |

---

## 12. 排障

| 现象 | 处理 |
|---|---|
| `flutter` 不是内部或外部命令 | 环境变量未生效，重开终端 |
| `dart analyze` 报 `Unable to determine engine version` | `git` 不在 PATH 里，Flutter 需要它 |
| `Android license status unknown` | `flutter doctor --android-licenses` 全部输 `y` |
| Gradle 下载卡住 | 确认 `GRADLE_USER_HOME` 已指向 D 盘，或配置国内 Maven 镜像 |
| `pub get` 超时 | 检查 `PUB_HOSTED_URL`，或临时清空该变量回落官方源 |
| `database.g.dart` 里大量 `Undefined class` | 见 §7.2，把表定义并回 `database.dart` |
| 仓储里 `Undefined class '%Table%'` / `argument_type_not_assignable` | 见 §7.1，改用 `_db.%table%` 访问器 |
| `flutter test` 无输出卡死 | 见 §8.2，是 `db.close()` 在等流查询归零 |
| 构建报 JDK 版本不符 | 确认 `JAVA_HOME` 指向 `D:\devtools\jdk17`，不要用 JDK 21+ |
| `Keystore file ... not found for signing config 'release'` | 见 §9，`storeFile` 要用 `rootProject.file(...)` 解析 |
| 构建突然变得极慢（小时级） | 见 §11「构建相关的两个坑」，清残留 java 进程 |
| `Could not close incremental caches ... compileReleaseKotlin` | 已在 `android/gradle.properties` 关掉 Kotlin 增量编译，见 §11 |
| 用 PowerShell 改源码后 `flutter test` 报 `Failed to decode data using encoding 'utf-8'` | 见 §13，**别用 PowerShell 的文本 cmdlet 碰源码** |

---

## 13. 协作约定

### 13.1 UI 改动：先出设计稿，确认后再写代码

**规则（用户明确要求）：任何 UI 改动，先给设计稿讨论定稿，再动代码。**

不要看到「把 A 挪到 B」「加个按钮」就直接改，因为：

- 布局是牵一发动全身的（比如把悬浮 FAB 并进 dock，会连带改列表底部内边距、
  空状态文案、以及所有断言 FAB 的测试）
- 同一个词常常有两种理解（「收藏」是收藏豆子还是收藏这套参数？
  「右滑」是滑开后停住，还是滑走即删除？），实现完再改成本高得多
- 用户改主意的成本远低于你改代码的成本

#### 什么必须先发稿，什么可以直接做

| 直接做，做完在汇报里说明 | **必须先发稿等确认** |
|---|---|
| 纯文案措辞、错别字 | 布局结构调整（增删栏位、换位置、改层级） |
| 图标替换成等价图标 | 交互行为（手势、长按、滑动、双击） |
| 颜色 / 间距的微调（不改变结构） | 新增或删除控件、新的页面/弹层 |
| 不触碰测试断言的内部整理 | 导航结构、dock / 标题栏的组成 |
| | 新增状态或空态、改变既有空态含意 |
| | 任何会让现有测试断言失效的改动 |

拿不准就按「先发稿」处理。

#### 设计稿必须包含的五项

| 项 | 说明 |
|---|---|
| **目标** | 这次要解决什么、用户原话是什么 |
| **布局示意** | 线框图（ASCII 即可），标出各元素位置与相对关系 |
| **尺寸与状态** | 关键尺寸（高度 / 圆角 / 图标大小）、空态 / 有数据 / 滑开 / 长按等状态 |
| **与现状的差异** | 删了什么、加了什么、哪些地方会连带变化（含受影响的测试） |
| **待确认项** | 我拿不准的 2~3 个点，列成选项让用户挑，而不是自己拍板 |

#### 呈现形式：先线框图，定稿前再渲染一张 PNG（用户选定的默认）

1. **第一步：聊天里的线框图 + 标注** —— 结构、层级、文案、状态用线框图快速对齐，
   尺寸和「与现状的差异」写在图下面。这一步要来回改到结构没争议为止。
2. **第二步：真实渲染的 PNG** —— 结构确认后，用真实的主题、字体、控件把这一屏
   渲染成图给用户看最终观感（配色、字重、间距），他点头才算定稿。

渲染脚手架放 `tool/design_preview/`，用 `flutter test tool/design_preview/xxx.dart
--update-goldens` 之类的方式单独跑：

- **不要**放进 `test/`，否则会被 CI 当 golden 比对，跨平台字体差异会导致假红
- 渲染用的数据要覆盖空态 / 有数据两条路径，别只画「有数据」那版

只有纯文案这种一句话的改动才跳过这两步（见上面的表格）。

#### 定稿之后

改代码 → 补测试 → `dart analyze` / `dart format` / `flutter test` 全绿 →
文档同步 → 提交推送 → CI 绿 → 需要的话重新出包给用户装机看。


### 13.2 别用 PowerShell 的文本 cmdlet 改源码

踩过两次，都是真损坏（不是显示问题）：

```powershell
# ❌ 这样会把 UTF-8 中文按 GBK 解码再写回，文件直接坏掉
(Get-Content foo.dart -Raw) -replace 'a', 'b' | Set-Content -NoNewline foo.dart
```

报错是 `Failed to decode data using encoding 'utf-8'`（`flutter test` 直接跑不起来），
而 `dart analyze` 可能还是干净的，很容易误判。要改源码就用编辑器/补丁工具，
或者在 Dart 侧改。已经写坏了就 `git checkout -- <file>` 重来。

> 确实要用脚本批量改时，**不要**用 `Get-Content` / `Set-Content`，
> 改用 .NET 的显式编码读写（它不看控制台代码页）：
>
> ```powershell
> $c = [System.IO.File]::ReadAllText($f)
> $c = $c.Replace('旧', '新')
> [System.IO.File]::WriteAllText($f, $c, (New-Object System.Text.UTF8Encoding($false)))
> ```

