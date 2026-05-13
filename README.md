# SwiftUI macOS Auto-growing Text Area

## 简介

演示一个 macOS SwiftUI 文本输入区：

1. 高度随内容增长和收缩。
2. 不出现内部滚动条。
3. 不裁剪文本。
4. 不保留多余底部空行。

核心做法不是自己桥接 `NSTextView`，而是直接使用 SwiftUI 原生 `TextField(axis: .vertical)`，再用本地 `keyDown` 监听，把 plain `Return` 直接转给当前 field editor 的 `insertNewlineIgnoringFieldEditor:`。

## 快速开始

```bash
cd swiftui-macos-auto-growing-textarea-demo
./scripts/build.sh
open build/DerivedData/Build/Products/Debug/SwiftUIAutoGrowingTextAreaDemo.app
```

## 用法

```swift
AutoGrowingTextArea(
    text: $text,
    prompt: "请输入多行内容",
    lineLimit: 1...16
)
```

## 核心点

```swift
TextField("请输入内容", text: $text, axis: .vertical)
    .textFieldStyle(.plain)
    .lineLimit(1...12)
    .focused($isFocused)
    .background {
        ReturnKeyInterceptor(isEnabled: isFocused)
    }
```

这版取舍：

1. 好处：代码极短，纯 SwiftUI，可直接拷。
2. 好处：不再需要 `NSViewRepresentable`、`Coordinator`、手动测量高度。
3. 好处：这次不是全局 `sendAction`，而是只命中当前编辑中的文本对象，通常更稳，闪烁更少。
