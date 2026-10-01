---
name: beanclick-verify-before-done
description: "Use when a BeanClick change must be proven actually done: after an implementer reports DONE, when recording the G2 baseline, at G5 / G6 integration verification, when a claim of all tests passing has no numbers, or before an APK is handed to users."
---

# 豆刻完成前验证（verifier）

## Overview

你是 `verifier`：独立跑命令、交**原始输出**的只读角色。**没有证据就不算完成**——「测试全过」这句话在豆刻没有信息量，除非它后面跟着命令、通过数和退出码。

## When to Use

- 任何 subagent 报 `DONE` / `DONE_WITH_CONCERNS` 之后，来收口证据。
- **G2 工作区就绪**：记下基线测试数与包体——后续所有「没退化」都相对它。
- **G5 代码质量**：本卡测试绿，`flutter analyze` 0 问题。
- **G6 集成验证**：全量三项，碰过 schema 再加 dump / generate。
- 出 APK、真机覆盖安装、发版前的签名自检。
- 有人说了「全过」「没退化」，但没给数字。

**什么时候不该用：**

- 你自己就是这张卡的实现者：**实现者不得自审**，换人。
- 改动还在动、实现者还没报 `DONE`：这时跑的是中间态，结论无效。
- 只是只读探索、不产出可合并的变更。
- 你想顺手改代码或改测试「让它过」：`verifier` 只读，发现问题打回给 `lead`。

## Iron Laws

1. **没有原始输出不算完成。** 报告必须含命令原文 + 通过数 + 退出码；违反 = 无从判断是否退化。
2. **一切「没退化」都相对 G2 基线。** 违反 = 「全过」变成不可判定的空话。
3. **只读。** 不改产品代码、不改测试，只写验证报告；违反 = 验证与实现同一人，验证失去意义。
4. **假失败与假通过都要定性，不许拍脑袋放过或判死。** 卡死 / 无输出 / 单次 flake 都要给出判定依据（隔离用例、重跑、读输出）。
5. **碰过 schema 必须补跑 `schema dump` + `schema generate`，且 `git status --short` 干净。** 违反 = 快照漏了，MG 门等于没过。
6. **出包必须自检签名：`apksigner verify --print-certs`，期望 `CN=BeanClick`。** 违反 = debug 签名产物被当成可分发版本发出去。

## Process Flow

```mermaid
flowchart TD
    A["收到卡 + 验收命令 + G2 基线"] --> B["只读核对范围<br/>git diff --stat 与文件清单"]
    B --> C["dart format 检查 + flutter analyze"]
    C --> D{"碰过 schema 吗"}
    D -->|"碰过"| E["schema dump + generate<br/>git status --short 必须干净"]
    D -->|"没碰"| F["全量 flutter test"]
    E --> F
    F --> G{"与基线相比"}
    G -->|"低于基线或红"| H["报告失败<br/>附原始输出与复现命令"]
    G -->|"不低于基线"| I["出验证报告<br/>命令 + 通过数 + 退出码 + 未验证项"]
```

## Implementation

1. **先固定基线**（G2，每个新工作区做一次）：`flutter test` 记下通过数；要发版时再记下每个 ABI 的包体。不记录，后面就无法判断退化。
2. **只读核对范围**：`git diff --stat` + 文件清单，确认改动没有越过卡里声明的写作用域（同时跨 `lib/data` 与 `lib/features` 就是拆卡失败）。
3. **静态与格式检查**（与 CI 同款，只读不写）：

   ```powershell
   dart format --output=none --set-exit-if-changed .   # 退出码 0 = 没有需要格式化的文件
   flutter analyze                                     # 期望 No issues found!
   ```

   **不要跑全量 `dart format .`**：它会顺手改掉别人卡里的文件、污染 diff。
4. **碰过 schema 就补两条命令**（配合 `beanclick-drift-migration-guard`）：

   ```powershell
   dart run drift_dev schema dump lib/data/database.dart test/drift/schemas
   dart run drift_dev schema generate test/drift/schemas test/drift/generated
   git status --short        # 期望无输出：说明快照没漏、生成物无 diff
   ```

5. **全量测试**：`flutter test`。一张卡一次，集成阶段由你统一跑一次，不要与别人并发跑（互相拖慢，而且都要读工程根目录的 `sqlite3.dll`）。
6. **测试数对照基线**：少于基线 = 有测试被删或被跳过 = G6 不过，写进报告。
7. **出包与签名自检**（要发版时）：

   ```powershell
   flutter build apk --release --split-per-abi
   apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

   `apksigner` 在 Android SDK 的 build-tools 下，路径因机器而异，按本机 SDK 根目录定位。期望证书 `CN=BeanClick`；拿到 debug 签名说明 `android/key.properties` 没生效，该产物**不能分发**。
8. **真机覆盖安装**（不是全新安装）：旧数据原样在、进程存活、logcat 无 Flutter 与 drift / SQLite 异常。release 包 `debuggable=false`，`run-as` 用不了，别指望直接读设备上的 `PRAGMA user_version`。

## Common Mistakes

**假失败 / 假通过（最贵的一类，必须先识别再下结论）**

- **`flutter test` 卡死、无任何输出**：widget 测试里 `await db.close()` / `container.dispose()` 在订阅没取消前**永久阻塞**。用 `test/helpers/widget_harness.dart` 的 `harness.finish(tester)` 收尾——只拆树，不 await 关闭。更阴的一面：测试**失败**时 flutter_test 不卸载 widget 树，于是「失败 → 没卸树 → 卡死」；测试通过时反而能过。
- **`scrollUntilVisible` 只朝一个方向滚**：目标在上方时滚满 50 次抛 `Bad state: No element`。用 harness 的 `fillField` / `tapKey` / `tapTextScrolled`（先拉回顶部再往下找）。
- **fake-async 下文件写不出去**：`testWidgets` 里 `await file.writeAsBytes(...)` 的回调不会来，测试能过但文件其实没写，而且不报错。编码 + 真实落盘放普通 `test`（如 `test/domain/export_encoder_test.dart`），widget 层只测接线。
- **`setUp` 先注册先执行**：只在业务 `setUp` 里登记的覆盖项会静默失效。用 `WidgetTestHarness.useOverrides()`——它会立刻重建容器。
- **批次夹具写错**：批次模型下余量 / 烘焙日期在批次上，`CoffeeBean(remainingGrams: ...)` 这种写法已经不存在。用 `addBeanWithBatch`，断言落到批次（只断言 `log.doseGrams` 会漏掉「余量一分没动」的真事故）。
- **`sqlite3.dll` 不在工程根目录**：`flutter test` 起不来或直接失败；它是 gitignore 的，换工作区 / worktree 时必须拷过去。
- **CI 的 sqlite3 预编译库下载失败**（`Building assets for package:sqlite3 failed` / `SocketException: Connection reset by peer`）：网络抖动，不是代码坏了；`gh run rerun <id> --failed` 重跑即可，本地因为库已缓存所以看不到。
- **构建慢到小时级（实测 26741 秒 ≈ 7.4 小时）**：残留的 Gradle `java` 守护进程在拖后腿。先看 `Get-Process java`，必要时清掉再构建（正常 2~5 分钟）。
- **`Could not close incremental caches ... compileReleaseKotlin`**：Kotlin 增量缓存锁失败；工程已在 `android/gradle.properties` 关掉 `kotlin.incremental`，别删这一行去「优化」构建。
- **MIUI 拦安装 / 拦事件**：`INSTALL_FAILED_USER_RESTRICTED` 要在开发者选项打开「USB 安装」；`adb shell input tap` 会被 `INJECT_EVENTS` 拦下——**不要用 adb 驱动界面**，只能看首屏或让用户自己点。
- **一次 flake 就下结论**：先分清是环境、缓存还是真失败，再定性；重跑的结果也要贴出来。

## Evidence

验证报告必须能被别人**照着复现**，只含以下内容：

1. 命令原文（逐条，可直接粘贴）。
2. 原始输出摘要：**通过数 + 退出码**（失败时贴失败用例名与断言原文）。
3. 与基线的对照：测试数 `基线 → 本次`，包体变化（有变化就要有解释）。
4. `git status --short` 的输出（碰过 schema 时必须是空的）。
5. 签名自检输出（出包时）。
6. **未验证项清单**：没能验证的东西要写出来，不许用沉默代替结论。

```text
flutter analyze                                  → No issues found!，退出码 0
dart format --output=none --set-exit-if-changed . → 0 处改动，退出码 0
flutter test                                     → 299 个全部通过（基线 299），退出码 0
git status --short                               → 无输出
```

结尾只报 `DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED` 四态之一；发现风险但不确定是否阻断时报 `DONE_WITH_CONCERNS` 并逐条列出，既不要自己拍板放过，也不要把 `BLOCKED` 说成 `DONE_WITH_CONCERNS`。
