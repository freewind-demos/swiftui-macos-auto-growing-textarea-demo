import SwiftUI
import AppKit

struct AutoGrowingTextArea: NSViewRepresentable {
    @Binding var text: String
    @Binding var metrics: TextLayoutMetrics
    let width: CGFloat
    let font: NSFont

    init(
        text: Binding<String>,
        metrics: Binding<TextLayoutMetrics>,
        width: CGFloat,
        font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
    ) {
        _text = text
        _metrics = metrics
        self.width = width
        self.font = font
    }

    func makeCoordinator() -> Coordinator {
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
        textView.font = font
        textView.textContainerInset = .zero

        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = false
            textContainer.heightTracksTextView = false
            textContainer.lineFragmentPadding = 0
        }

        textView.onTextChange = context.coordinator.handleTextChange
        textView.onMetricsChange = context.coordinator.handleMetricsChange
        textView.configure(text: text, width: width, font: font)
        return textView
    }

    func updateNSView(_ textView: AutoGrowingTextView, context: Context) {
        textView.onTextChange = context.coordinator.handleTextChange
        textView.onMetricsChange = context.coordinator.handleMetricsChange
        textView.configure(text: text, width: width, font: font)
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
    private var currentMetrics = TextLayoutMetrics.systemDefault

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: currentMetrics.contentHeight)
    }

    func configure(text: String, width: CGFloat, font: NSFont) {
        if string != text {
            string = text
        }

        if self.font != font {
            self.font = font
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
