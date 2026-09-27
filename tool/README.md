# tool/ —— 一次性工具脚本

这里放**不进构建流程**的辅助脚本。它们只是为了让某些操作可复现，
不需要在每次构建时运行。

---

## 应用图标

图标的原始设计是**代码画出来的**，没有用图标生成器，也没有外部素材：

- 咖啡棕圆角底（`#6F4E37`，与 `lib/app.dart` 的主题 seed 一致）
- 白色咖啡杯剪影（杯身梯形 + 圆角把手，把手先画、被杯身盖住内端）
- 奶泡色横带（`#C49A6C`）表示液面

输出：

| 文件 | 用途 |
|---|---|
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | 传统图标（48 / 72 / 96 / 144 / 192 px） |
| `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png` | 自适应图标前景（透明底，尺寸为传统图标的 2.25 倍） |
| `assets/icon/app_icon_512.png` | 512px 源图，留档与商店用 |

自适应图标的 XML 在 `android/app/src/main/res/mipmap-anydpi-v26/`，
背景色定义在 `res/values/colors.xml`。

### 重新生成

图标脚本用 PowerShell + `System.Drawing` 直接绘制。**注意两点**：

1. 脚本必须存成 **ANSI/UTF-8 无 BOM 且不含中文注释**——
   Windows PowerShell 5.1 会把无 BOM 的 UTF-8 当 ANSI 读，
   中文注释被解码坏以后会连带把语法解析搞崩（报 `Unexpected token '}'`）。
   所以这里没有把脚本文件留在仓库里，需要时按下文重建即可。
2. 改尺寸或配色时，改脚本顶部的颜色变量与几何比例即可。

重建脚本要点（可直接复制到 PowerShell 里执行）：

```powershell
Add-Type -AssemblyName System.Drawing
$brown = [System.Drawing.Color]::FromArgb(255,111,78,55)
$white = [System.Drawing.Color]::FromArgb(255,250,246,240)
$crema = [System.Drawing.Color]::FromArgb(255,196,154,108)
# 几何全部按画布比例给，保证各密度一致：
#   杯口半宽 0.265  杯底半宽 0.17  杯口 -0.205  杯底 +0.215
#   把手半径 0.19   把手中心 x +0.245  把手中心 y +0.005  笔宽 0.085
# 自适应图标前景用 scale = 0.72（给系统裁切留边）
```

> 图标改动后需要重新构建 APK 才会生效（`mipmap-*` 是编译期资源）。

---

## 为什么不用 flutter_launcher_icons

试过，但它的输入必须是一张现成的 PNG。既然图标本身要画，
直接画到各个密度反而少一层依赖（它还会顺带拉进 5 个传递依赖）。
如果将来换成设计师给的成品图，再引入这类工具更合适。
