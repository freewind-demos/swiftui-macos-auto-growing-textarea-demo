# SwiftUI macOS Auto-growing Text Area

## 简介

演示一个 macOS SwiftUI 文本输入区：

1. 高度随内容增长和收缩。
2. 不出现内部滚动条。
3. 不裁剪文本。
4. 不保留多余底部空行。

核心做法不是直接用 `TextEditor`，而是包装 `NSTextView`，并把测得内容高度回传给 SwiftUI。

## 快速开始

```bash
cd swiftui-macos-auto-growing-textarea-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUIAutoGrowingTextAreaDemo.app
```

## 核心点

```swift
textContainer.lineFragmentPadding = 0
textView.textContainerInset = .zero
scrollView.hasVerticalScroller = false
```

这 3 处分别解决：

1. 行内左右额外 padding。
2. 上下额外 inset。
3. 内部滚动条。

高度计算靠：

```swift
layoutManager.usedRect(for: textContainer).height
```

拿到实际排版后的内容高度，再回写给 SwiftUI `frame(height:)`。
