# tool/ —— 一次性工具脚本

这里放**不进构建流程**的辅助脚本。它们只是为了让某些操作可复现，
不需要在每次构建时运行。

---

## 应用图标

现在的图标是**用户提供的成品图**：米白圆角方块 + 深棕圆环 + 中间一颗咖啡豆 +
一圈刻度点（呼应「记录刻度」）。

- 原图留档：`assets/icon/app_icon_source.png`（1254×1254，24bpp 无透明通道）
- 生成脚本：`tool/make_app_icons.ps1`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\make_app_icons.ps1
```

输出：

| 文件 | 用途 |
|---|---|
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | 传统图标（48 / 72 / 96 / 144 / 192 px）。把原图里**圆角方块之外的白色页面**抠成透明，留下米白方块；方块按 `$legacyKeep` 内缩，和自适应图标视觉等大 |
| `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png` | 自适应图标前景（尺寸为传统图标的 2.25 倍）。把米白背景**也**抠成透明，只留圆环 / 豆 / 刻度点；原图按 `$foregroundKeep` 缩小后居中，四周留出系统裁切要吃的空白 |
| `assets/icon/app_icon_512.png` | 512px 留档与商店用；**故意满幅**（keep 1.00），商店自己会做遮罩 |
| `tool/out/app_icon_preview.png` | 复核用对照表（传统图标 / 前景叠米白底 / 前景叠棋盘格） |

抠图是**按亮度**做的（`Key-OutPixels`）：传统图标把亮度 ≥252 的当页面白去掉；
前景把亮度 ≥215 的（页面白 + 米白背景）都去掉，中间一段做线性过渡当作抗锯齿边。
`res/values/colors.xml` 里的 `ic_launcher_background` 取原图的米白 `#F3EBDC`，
所以自适应图标裁切后的观感和传统图标一致。

### 两种图标为什么一起缩小（`$foregroundKeep` = `$legacyKeep` = 0.82）

自适应图标画在 108dp 画布上，但**系统只显示中间一块**：圆形遮罩只有 72/108 ≈ 67%，
MIUI 的圆角方形大约 78%。原图铺满整个画布时，深棕圆环会占画布的 ~85%，
裁切之后几乎贴到遮罩边缘（四周只剩 2～5%），看起来就是「图标太大了」。
`$foregroundKeep` 把原图缩到画布的 82% 再居中，圆环回到画布的 ~70%。

`$legacyKeep` **取同一个值**：传统图标是整块画布直接显示的（老 Android、
部分厂商桌面），原来铺满时它的圆角方块比自适应图标大一圈，两者并排尺寸不一致；
缩到 82% 之后，两块画布里的图案视觉等大。

> 缩图留出的空白靠 `Key-OutPixels` 里的 `if ($bytes[$i+3] -eq 0) { continue }` 保住
> —— 清空的像素是 `(0,0,0,0)`、亮度算出来是 0，不跳过就会被写成不透明的黑边。

### 图标预览脚本（决策用，不进构建）

| 脚本 | 输出 | 用途 |
|---|---|---|
| `tool/icon_scale_preview.ps1` | `tool/out/icon_scale_candidates.png` | 一次排开 5 个候选缩放比，每个给「原样 / 圆形遮罩 / 圆角方形遮罩」三视图 |
| `tool/icon_review_sheet.ps1 -Keep 0.82` | `tool/out/icon_review_keep82.png` | 选定一个缩放比，按真实遮罩形状（方形 / 圆形 / 圆角方形）＋传统图标出对照表 |

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\icon_review_sheet.ps1 -Keep 0.82
```

> 这两个脚本里的 `Key-OutPixels` 必须**保留已有透明像素**（`if ($bytes[$i+3] -eq 0) { continue }`）。
> 抠图前画布被清成 `(0,0,0,0)`，亮度算出来是 0，如果不跳过就会把它当成「很暗的内容」
> 写成 `alpha=255` —— 于是缩图留出的空白会变成一个**不透明的黑方块**。

### 重新生成 / 换图

换图标时把新图覆盖 `assets/icon/app_icon_source.png` 再跑一次脚本即可；
如果新图的背景色不同，记得同步改 `res/values/colors.xml` 与脚本里的两个亮度阈值。

> ⚠️ 脚本必须存成 **ANSI/UTF-8 无 BOM 且不含中文注释**——
> Windows PowerShell 5.1 会把无 BOM 的 UTF-8 当 ANSI 读，中文注释被解码坏以后
> 连带把语法解析搞崩（报 `Unexpected token '}'`）。所以这个文件里只有英文注释。

改动 `mipmap-*` 后必须重新构建 APK 才生效（编译期资源），
而且**桌面可能缓存旧图标**：重装后如果还是旧的，重启桌面或卸载重装。

> 历史：M1～M2.7 的图标是代码画出来的（棕色底 + 白色咖啡杯剪影），
> 那个脚本没留在仓库里（见 git 历史）。M2.8 起改用用户提供的成品图。

---

## 为什么不用 flutter_launcher_icons

试过，但它的输入必须是一张现成的 PNG，而且不方便做「自适应前景要单独抠背景」
这种处理。本项目需要一个几十行的脚本把原图切成三份不同处理方式的产物，
自己写反而更清楚，也少 5 个传递依赖。
