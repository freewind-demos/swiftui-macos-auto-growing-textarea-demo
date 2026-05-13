import SwiftUI
import AppKit

struct TextLayoutMetrics: Equatable {
    let lineCount: Int
    let singleLineHeight: CGFloat

    var contentHeight: CGFloat {
        CGFloat(lineCount) * singleLineHeight
    }

    static func initial(font: NSFont) -> TextLayoutMetrics {
        let lineHeight = ceil(NSLayoutManager().defaultLineHeight(for: font))
        return TextLayoutMetrics(lineCount: 1, singleLineHeight: lineHeight)
    }
}

struct ContentView: View {
    // `@State` = 这个 View 自己持有的状态。这里存“文本内容”。
    @State private var text = """
第一行
第二行会随内容继续增长，不会出现内部滚动条。
"""
    // 这里不再直接存最终高度，只存“排版指标”：
    // 1. 视觉行数
    // 2. 单行高度
    // 真正高度由当前 View 自己决定怎么算。
    @State private var editorMetrics = TextLayoutMetrics.initial(
        font: .systemFont(ofSize: NSFont.systemFontSize)
    )

    var body: some View {
        GeometryReader { proxy in
            // 预留外层 padding 后，把稳定可用宽度传给 NSTextView 做真实换行测量。
            let editorWidth = max(proxy.size.width - 48, 200)

            VStack(alignment: .leading, spacing: 12) {
                Text("Auto-growing text area")
                    .font(.title2)

                Text("高度只跟内容走；不留多余空行；不裁剪；不出内部滚动。")
                    .foregroundStyle(.secondary)

                AutoGrowingTextArea(
                    // `$text` / `$editorMetrics` 不是值本身，是“可读可写入口”。
                    // 子 View 可经它回写父 View 的状态。
                    text: $text,
                    metrics: $editorMetrics,
                    width: editorWidth
                )
                .frame(width: editorWidth, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                )

                Text("视觉行数: \(editorMetrics.lineCount) · 单行高: \(Int(editorMetrics.singleLineHeight))pt · 内容高度: \(Int(editorMetrics.contentHeight))pt")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// SwiftUI 自带 TextEditor 在 macOS 上不方便精确控制内容高度。
// 所以这里包一层 AppKit 的 NSTextView，自行拿到底层 layout 结果。
struct AutoGrowingTextArea: NSViewRepresentable {
    // 父 View 传进来的“文本状态入口”。
    // 读它可拿到最新文本，写它可把新文本回传给父 View。
    @Binding var text: String
    // 父 View 传进来的“排版指标入口”。
    // 这里算出行数与单行高后，会写回它；父 View 再自行决定最终高度公式。
    @Binding var metrics: TextLayoutMetrics
    // 外层算好的可用宽度。高度测量必须依赖宽度，因为换行会影响总高度。
    let width: CGFloat

    func makeCoordinator() -> Coordinator {
        // Coordinator 负责把 AppKit 回调桥接回 SwiftUI state。
        Coordinator(text: $text, metrics: $metrics)
    }

    func makeNSView(context: Context) -> AutoGrowingTextView {
        let textView = AutoGrowingTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainerInset = .zero

        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = false
            textContainer.heightTracksTextView = false
            textContainer.lineFragmentPadding = 0
        }

        textView.onTextChange = context.coordinator.handleTextChange
        textView.onMetricsChange = context.coordinator.handleMetricsChange
        textView.configure(text: text, width: width)
        return textView
    }

    func updateNSView(_ textView: AutoGrowingTextView, context: Context) {
        textView.onTextChange = context.coordinator.handleTextChange
        textView.onMetricsChange = context.coordinator.handleMetricsChange
        textView.configure(text: text, width: width)
    }

    final class Coordinator {
        private var text: Binding<String>
        private var metrics: Binding<TextLayoutMetrics>

        init(text: Binding<String>, metrics: Binding<TextLayoutMetrics>) {
            self.text = text
            self.metrics = metrics
        }

        func handleTextChange(_ nextText: String) {
            guard text.wrappedValue != nextText else {
                return
            }

            text.wrappedValue = nextText
        }

        func handleMetricsChange(_ nextMetrics: TextLayoutMetrics) {
            guard metrics.wrappedValue != nextMetrics else {
                return
            }

            DispatchQueue.main.async {
                self.metrics.wrappedValue = nextMetrics
            }
        }
    }
}

final class AutoGrowingTextView: NSTextView {
    var onTextChange: ((String) -> Void)?
    var onMetricsChange: ((TextLayoutMetrics) -> Void)?

    private var measuredWidth: CGFloat = 0
    private var currentMetrics = TextLayoutMetrics.initial(
        font: .systemFont(ofSize: NSFont.systemFontSize)
    )

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: currentMetrics.contentHeight)
    }

    func configure(text: String, width: CGFloat) {
        if string != text {
            string = text
        }

        updateMeasuredWidth(width)
        recomputeMetrics()
    }

    override func didChangeText() {
        super.didChangeText()
        onTextChange?(string)
        recomputeMetrics()
    }

    private func updateMeasuredWidth(_ width: CGFloat) {
        guard width > 0, abs(measuredWidth - width) > 0.5 else {
            return
        }

        measuredWidth = width

        if let textContainer = textContainer {
            textContainer.containerSize = NSSize(
                width: width,
                height: CGFloat.greatestFiniteMagnitude
            )
        }
    }

    private func recomputeMetrics() {
        guard measuredWidth > 0 else {
            return
        }

        let font = font ?? .systemFont(ofSize: NSFont.systemFontSize)
        let nextMetrics = measureTextLayoutMetrics(
            text: string,
            width: measuredWidth,
            font: font
        )

        guard currentMetrics != nextMetrics else {
            return
        }

        currentMetrics = nextMetrics
        invalidateIntrinsicContentSize()
        needsLayout = true
        onMetricsChange?(nextMetrics)
    }
}
