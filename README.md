# Christmas Tree 🎄

一个用 **SwiftUI + Metal** 写的 macOS 圣诞树小程序。屏幕上会实时渲染一棵由几万个发光点组成的 3D 圣诞树，缓慢自转，树顶飘着一颗心形，地上有几圈光环点缀，再叠一行 "Merry Christmas" 字样。

> **仅支持 macOS。** 项目依赖 AppKit（`NSViewRepresentable`）和 Metal，无法在 iOS、Windows 或 Linux 上运行。详见[运行环境](#运行环境)。

## 目录

- [特性](#特性)
- [运行环境](#运行环境)
- [如何运行](#如何运行)
- [项目结构](#项目结构)
- [把你的名字加上去](#把你的名字加上去)
- [想再玩点花的](#想再玩点花的)
- [License](#license)

## 特性

- **GPU 点云渲染**：默认 56,200 个发光点（树 50,000 + 地面 4,000 + 星星 1,200 + 心形 1,000），全部由 Metal vertex/fragment shader 实时绘制
- **3D 自动旋转**：每帧绕 Y 轴缓慢旋转，带轻微俯角
- **多层次构图**：螺旋树形 + 填充体积 + 地面光环 + 背景星点 + 树顶心形
- **紫白渐变配色**：按高度从紫色过渡到白色
- **SwiftUI 文字叠层**：在 Metal 视图上方叠 "Merry Christmas"

## 运行环境

- macOS 14+ （使用了 Metal 和 SwiftUI 的 macOS 版本）
- Xcode 16+
- 有 Metal 支持的 Mac（基本上 2012 年以后的都行）

## 如何运行

1. 克隆仓库
   ```bash
   git clone https://github.com/Euswbnix/Christmas_tree.git
   cd Christmas_tree
   ```
2. 用 Xcode 打开 `Christmas_tree.xcodeproj`
3. 在窗口顶部 scheme 选择器里选 **`ChristmasTreeApp`**
4. ⌘R 运行

## 项目结构

```
ChristmasTreeApp/
├── ChristmasTreeAppApp.swift   # @main 入口，SwiftUI App
├── ContentView 2.swift         # 主界面：MetalView + 文字叠层
├── MetalView.swift             # SwiftUI 包装的 NSViewRepresentable，承载 MTKView
├── Renderer.swift              # Metal 渲染器 + 点云几何生成（CPU 一次性构建）
└── Shaders.metal               # 顶点 / 片元着色器（旋转、投影、点精灵）
```

## 把你的名字加上去

如果你想在 "Merry Christmas" 旁边加上自己的名字，打开 `ChristmasTreeApp/ContentView 2.swift`，找到 `body` 里的 `HStack`：

```swift
HStack {
    Text("Merry Christmas")
        .font(.custom("Times New Roman Italic", size: 38))
        .foregroundColor(.white)
        .shadow(color: .white.opacity(0.35), radius: 6)
        .padding(.leading, 60)

    Spacer()
}
```

把它改成一个 `VStack`，在下面再加一行 `Text` 写你的名字：

```swift
HStack {
    VStack(alignment: .leading, spacing: 12) {
        Text("Merry Christmas")
            .font(.custom("Times New Roman Italic", size: 38))

        Text("— Your Name")          // ← 改成你想要的名字
            .font(.custom("Times New Roman Italic", size: 28))
    }
    .foregroundColor(.white)
    .shadow(color: .white.opacity(0.35), radius: 6)
    .padding(.leading, 60)

    Spacer()
}
```

几个可以调的地方：
- `size: 38` —— 字号大小
- `"Times New Roman Italic"` —— 字体名（换成 `"Snell Roundhand"` / `"Zapfino"` 这种花体也很有圣诞感）
- `.foregroundColor(.white)` —— 颜色，比如换成 `.red` 或 `Color(red: 1, green: 0.8, blue: 0.85)`
- `.padding(.leading, 60)` —— 距离左边的距离
- `alignment: .leading` —— 改成 `.center` 文字居中对齐

改完直接 ⌘R 重新运行就能看到。

## 想再玩点花的

`Renderer.swift` 顶部有几个常量可以直接调：

```swift
private let TREE_POINTS = 50_000     // 树本身的点数，越多越密
private let GROUND_POINTS = 4_000    // 地面光环点数
private let STAR_POINTS = 1_200      // 背景星星
private let HEART_POINTS = 1_000     // 树顶心形
private let TREE_HEIGHT: Float = 12.0
private let CAM_DIST: Float = 13.0   // 相机距离，越大树越远越小
private let CAM_HEIGHT: Float = 6.0  // 相机高度
```

旋转速度在 `Renderer.draw(in:)` 里：
```swift
angle += 0.0045   // 改大转得快，改小转得慢
```

颜色在 `buildScenePoints()` 里搜 `purple` / `white` / `rgb` 就能找到，想换成红绿配色也很简单。

注意这些点的几何是在 `buildScenePoints()` 里一次性构建好上传到 GPU 的，不是每帧重算，所以改完上面任何一个常量都要重新 ⌘R 编译运行才会生效。

## License

随便用，玩得开心 🎄
