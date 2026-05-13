import AppKit

// 全局独立 helper：
// 只负责“文本 + 宽度 + 字体 -> 视觉行数 + 单行高”。
// 它不依赖具体 View，也不碰 SwiftUI state。
func measureTextLayoutMetrics(text: String, width: CGFloat, font: NSFont) -> TextLayoutMetrics {
    let textStorage = NSTextStorage(string: text)
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(
        containerSize: NSSize(
            width: width,
            height: CGFloat.greatestFiniteMagnitude
        )
    )

    textContainer.widthTracksTextView = false
    textContainer.heightTracksTextView = false
    textContainer.lineFragmentPadding = 0

    textStorage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(textContainer)
    layoutManager.ensureLayout(for: textContainer)

    let lineHeight = ceil(layoutManager.defaultLineHeight(for: font))
    var lineCount = 0
    let glyphRange = layoutManager.glyphRange(for: textContainer)

    layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, _, _ in
        lineCount += 1
    }

    // 文本以换行结尾时，AppKit 会额外留一条空白行，要把它也算进去。
    if layoutManager.extraLineFragmentTextContainer != nil,
       !layoutManager.extraLineFragmentRect.isEmpty {
        lineCount += 1
    }

    return TextLayoutMetrics(
        lineCount: max(1, lineCount),
        singleLineHeight: lineHeight
    )
}
