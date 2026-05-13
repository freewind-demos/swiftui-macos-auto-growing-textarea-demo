import AppKit

struct TextLayoutMetrics: Equatable {
    let lineCount: Int
    let singleLineHeight: CGFloat

    var contentHeight: CGFloat {
        CGFloat(lineCount) * singleLineHeight
    }

    static let systemDefault = TextLayoutMetrics(
        lineCount: 1,
        singleLineHeight: ceil(
            NSLayoutManager().defaultLineHeight(
                for: .systemFont(ofSize: NSFont.systemFontSize)
            )
        )
    )
}
