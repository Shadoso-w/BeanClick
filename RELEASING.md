# 内测安装说明 / RELEASING

面向前两次真机测试。产物不入库（`.gitignore` 已忽略 `/dist/`）。

---

## 1. 选哪个 APK

本项目按 ABI 拆分打包，**只装一个**即可：

| 文件 | 适用机型 | 大小 |
|---|---|---|
| `app-arm64-v8a-release.apk` | **绝大多数 2017 年后的手机**（首选） | 19.7 MB |
| `app-armeabi-v7a-release.apk` | 老旧的 32 位机型 | 17.2 MB |
| `app-x86_64-release.apk` | 模拟器 / x86 平板 | 21.1 MB |

拿不准就先试 `arm64-v8a`；装不上（提示「应用未安装」或「不兼容」）再换 `armeabi-v7a`。

> 手机在「设置 → 关于手机」里看 CPU 架构。华为/小米/OPPO/vivo 近几年的机型基本都是 arm64。

---

## 2. 安装

### 方式 A：手机直接装（推荐）

1. 把对应的 APK 传到手机（微信文件传输助手、数据线、网盘均可）
2. 用文件管理器点开 APK
3. 系统会提示「禁止安装未知应用」→ 允许该来源安装
4. 装完桌面出现**豆刻**图标

### 方式 B：电脑用 adb 装

手机开「开发者选项 → USB 调试」，插线后：

```powershell
$env:Path = 'D:\Android\Sdk\platform-tools;' + $env:Path
adb devices                       # 确认能看到设备
adb install -r 'D:\BeanClick\dist\app-arm64-v8a-release.apk'
```

`-r` 表示覆盖安装、保留数据；想彻底重来先 `adb uninstall com.beanclick.beanclick`。

---

## 3. 这一版有哪些功能

M0–M2.5 的内容，**P0 除了独立搜索页都已具备**：

- 豆库：新增 / 编辑 / 删除咖啡豆（产地、处理法、烘焙度、烘焙日期、风味、余量、价格）
- 磨豆机：新增 / 编辑 / 删除（刻度单位、零点、每圈 click）
- 冲煮记录：新增 / 编辑 / 删除；手冲与摩卡壶；专业字段折叠
- 快速记录：点右下角 `+`，**自动带上次参数**（但不继承评分与备注）
- 余量：保存记录按粉量自动扣减；改粉量按差值补扣；可在「我的」里关掉
- 导出：我的 → 导出数据 → 选 JSON 或 CSV → 系统分享面板保存
- 主题：浅色 / 深色 / 跟随系统

### 还没有的

- **独立搜索页**（记录页顶部已有搜索框，能按豆子名/磨豆机/方法/评分过滤）
- **导入**（导出的是完整 JSON 备份，但还没有恢复入口）
- 计时器、统计图表、图片分享、同步

---

## 4. 请重点反馈什么

这一版**没有在真机上跑过**，以下这些是静态检查和单元测试覆盖不到的地方，最需要你实测：

| 优先级 | 要看的点 |
|---|---|
| 高 | **导出**：点「导出数据 → CSV」后，系统分享面板能否正常弹出？保存下来的 CSV 用手机 WPS/Excel 打开，**中文表头是否乱码**？ |
| 高 | **启动速度**：冷启动到能用，感觉快还是慢（目标 < 1.5s） |
| 高 | **复制上次**：点 `+` 是否确实带出了上次的粉量/水量/水温？再保存一条，原记录有没有被改掉？ |
| 中 | **余量扣减**：保存记录后，豆库里的余量是否按粉量减少？ |
| 中 | **深色模式**：切到深色后，表单、弹窗、列表有没有看不清的文字或对比度问题？ |
| 中 | **单手操作**：底部导航 + 中间 FAB 的位置，单手拇指够不够得着 |
| 低 | 中文输入法在弹出的表单里是否正常（尤其是数字键盘） |
| 低 | 列表滚动 1000 条时是否流畅（可以先用 JSON 造数据，暂时手动录入几十条也行） |

反馈方式：GitHub Issue（`.github/ISSUE_TEMPLATE/bug_report.yml` 有模板），
附上机型、系统版本、复现步骤。

---

## 5. 签名说明（重要）

这一版的 APK 用的是**项目自建的 release 密钥**
（`android/keystore/beanclick-release.p12`，口令在 `android/key.properties`，两者都不入库）。

需要知道的：

- **这是内测用的密钥，不是正式的。** 公开分发前应当重新生成一套自己的密钥并**离线备份**——
  一旦丢失，就无法再给已安装的用户推送更新（只能让他们卸载重装）。
- 换密钥后**必须先卸载旧版**再安装，否则会报「应用未安装」（签名冲突）。
- `key.properties` 不存在时，Gradle 会自动回落到 debug 签名，构建不会失败——
  这样新克隆仓库的人和 CI 都能直接构建。但那种产物**不能分发**。

自己生成正式密钥：

```powershell
$env:Path = 'D:\devtools\jdk17\bin;' + $env:Path
keytool -genkeypair -v `
  -keystore android\keystore\beanclick-release.p12 -storetype PKCS12 `
  -keyalg RSA -keysize 2048 -validity 10950 `
  -alias beanclick
# 按提示设口令，然后照 android/key.properties 的格式填好（注意 storeFile 路径相对 android/）
```

---

## 6. 出包命令

```powershell
$env:Path = 'D:\devtools\flutter\bin;D:\devtools\flutter\bin\cache\dart-sdk\bin;D:\devtools\Git\cmd;' + $env:Path
$env:JAVA_HOME='D:\devtools\jdk17'
$env:ANDROID_HOME='D:\Android\Sdk'; $env:ANDROID_SDK_ROOT='D:\Android\Sdk'
$env:GRADLE_USER_HOME='D:\devtools\gradle-home'
Set-Location 'D:\BeanClick'
flutter build apk --release --split-per-abi
Copy-Item 'build\app\outputs\flutter-apk\*.apk' 'dist\' -Force
```

约 2 分钟。构建前如果感觉异常慢，先按 `docs/DEVELOPMENT.md`「构建相关的两个坑」清一次 java 进程。
