# 隐私政策 / Privacy Policy

**豆刻 BeanClick**
生效日期：2026-01-01
适用版本：v0.1.0 及以后

---

## 一句话概括

**豆刻不收集你的任何数据。** 所有冲煮记录、豆子信息、磨豆机参数只保存在你手机本地的数据库里，
不会上传到任何服务器。

---

## 1. 我们收集的信息

**没有。**

豆刻不收集、不存储、不传输以下任何信息：

- 个人身份信息（姓名、手机号、邮箱、账号）
- 设备标识符（IMEI、Android ID、MAC 地址、广告 ID）
- 位置信息
- 通讯录、短信、相册（除你主动选择的豆子照片外）
- 使用行为、崩溃日志、统计数据

## 2. 你的数据存在哪里

所有数据存储在你设备的**本地 SQLite 数据库**中（应用私有目录）。
卸载应用即会删除全部数据。

豆刻**没有**自建服务器，**没有**云端账号系统。

## 3. 网络访问说明

豆刻在以下**你主动触发**的场景才会联网：

| 场景 | 说明 |
|---|---|
| 导出/导入备份 | 由你选择文件保存位置，文件不经过任何服务器 |
| 同步（P1，未来功能） | 仅在你自行配置 WebDAV 地址后，数据直接在你的设备与**你自己的**网盘之间传输 |

除此之外，豆刻在离线状态下功能完整可用。

## 4. 第三方 SDK

豆刻**不集成**任何以下类型的第三方 SDK：

- 广告 SDK
- 用户行为分析 / 埋点 SDK
- 崩溃上报 SDK
- 社交分享 SDK（分享功能为本地生成图片，不经第三方）

依赖的第三方开源库及其许可证，可在应用内「我的 → 开源许可」页面查看。

## 5. 权限说明

豆刻遵循最小权限原则，仅在你使用对应功能时申请权限：

| 权限 | 用途 | 是否必需 |
|---|---|---|
| 相机 / 相册 | 为咖啡豆或记录添加照片 | 否，可拒绝 |
| 存储（读写文件） | 导出 / 导入 JSON、CSV 备份 | 否，可拒绝 |

拒绝任何权限都不会影响核心记录功能的使用。

## 6. 儿童隐私

豆刻不面向儿童设计，也不会有意收集儿童信息——事实上它不收集任何人的信息。

## 7. 政策变更

本政策如有变更，会在仓库 `docs/PRIVACY.md` 与 Release Notes 中说明。

## 8. 联系方式

如有隐私相关问题，请在本仓库提交 Issue。

---

## English Summary

BeanClick is a **fully local, offline-first** coffee brewing log app.
It does **not** collect, store, or transmit any personal data.
There are no ads, no analytics, no crash reporting, and no accounts.
All data lives in a local SQLite database on your device and is deleted when you uninstall the app.
Network access happens only when you explicitly export a backup or configure your own WebDAV sync.
