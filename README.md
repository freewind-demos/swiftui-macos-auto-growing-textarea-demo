# SwiftUI macOS Auto-growing Text Area

## 简介

演示一个 macOS SwiftUI 文本输入区：

1. 高度随内容增长和收缩。
2. 不出现内部滚动条。
3. 不裁剪文本。
4. 不保留多余底部空行。

核心做法不是直接用 `TextEditor`，而是用 1 个可拷走即用的 `AutoGrowingTextArea` 包装 `NSTextView`，把桥接与测量细节都藏进内部。

## 快速开始

```bash
cd swiftui-macos-auto-growing-textarea-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUIAutoGrowingTextAreaDemo.app
```

## 用法

```swift
AutoGrowingTextArea(text: $text)
```

## 核心点

```swift
textContainer.lineFragmentPadding = 0
textView.textContainerInset = .zero
```

这 2 处分别解决：

1. 行内左右额外 padding。
2. 上下额外 inset。

高度计算仍靠：

```swift
layoutManager.usedRect(for: textContainer).height
```

拿到实际排版后的内容高度，再由组件内部回写自己的 `frame(height:)`。
