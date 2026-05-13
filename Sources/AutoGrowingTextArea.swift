import SwiftUI
import AppKit

struct AutoGrowingTextArea: View {
    @Binding private var text: String
    private let font: NSFont

    @State private var measuredWidth: CGFloat = 0
    @State private var contentHeight: CGFloat

    init(
        text: Binding<String>,
        font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
    ) {
        _text = text
        self.font = font
        _contentHeight = State(
            initialValue: Self.defaultMetrics(for: font).contentHeight
        )
    }

    var body: some View {
        Representable(
            text: $text,
            width: measuredWidth,
            contentHeight: $contentHeight,
            font: font
        )
        .frame(height: contentHeight)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        updateMeasuredWidth(proxy.size.width)
                    }
                    .onChange(of: proxy.size.width) { nextWidth in
                        updateMeasuredWidth(nextWidth)
                    }
            }
        }
    }

    private func updateMeasuredWidth(_ nextWidth: CGFloat) {
        guard nextWidth > 0, abs(measuredWidth - nextWidth) > 0.5 else {
            return
        }

        measuredWidth = nextWidth
    }
}

private extension AutoGrowingTextArea {
    struct Representable: NSViewRepresentable {
        @Binding var text: String
        let width: CGFloat
        @Binding var contentHeight: CGFloat
        let font: NSFont

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text, contentHeight: $contentHeight)
        }

        func makeNSView(context: Context) -> AppKitTextView {
            let textView = AppKitTextView()
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
            textView.onHeightChange = context.coordinator.handleHeightChange
            textView.configure(text: text, width: width, font: font)
            return textView
        }

        func updateNSView(_ textView: AppKitTextView, context: Context) {
            textView.onTextChange = context.coordinator.handleTextChange
            textView.onHeightChange = context.coordinator.handleHeightChange
            textView.configure(text: text, width: width, font: font)
        }
    }

    final class Coordinator {
        private var text: Binding<String>
        private var contentHeight: Binding<CGFloat>

        init(text: Binding<String>, contentHeight: Binding<CGFloat>) {
            self.text = text
            self.contentHeight = contentHeight
        }

        func handleTextChange(_ nextText: String) {
            guard text.wrappedValue != nextText else {
                return
            }

            text.wrappedValue = nextText
        }

        func handleHeightChange(_ nextHeight: CGFloat) {
            guard abs(contentHeight.wrappedValue - nextHeight) > 0.5 else {
                return
            }

            DispatchQueue.main.async {
                self.contentHeight.wrappedValue = nextHeight
            }
        }
    }

    final class AppKitTextView: NSTextView {
        var onTextChange: ((String) -> Void)?
        var onHeightChange: ((CGFloat) -> Void)?

        private var measuredWidth: CGFloat = 0
        private var contentHeight: CGFloat = 0

        override var intrinsicContentSize: NSSize {
            NSSize(width: NSView.noIntrinsicMetric, height: contentHeight)
        }

        func configure(text: String, width: CGFloat, font: NSFont) {
            if string != text {
                string = text
            }

            if self.font != font {
                self.font = font
            }

            updateMeasuredWidth(width)
            recomputeHeight()
        }

        override func didChangeText() {
            super.didChangeText()
            onTextChange?(string)
            recomputeHeight()
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

        private func recomputeHeight() {
            guard measuredWidth > 0 else {
                return
            }

            let font = font ?? .systemFont(ofSize: NSFont.systemFontSize)
            let nextMetrics = AutoGrowingTextArea.measureLayoutMetrics(
                text: string,
                width: measuredWidth,
                font: font
            )
            let nextHeight = nextMetrics.contentHeight

            guard abs(contentHeight - nextHeight) > 0.5 else {
                return
            }

            contentHeight = nextHeight
            invalidateIntrinsicContentSize()
            needsLayout = true
            onHeightChange?(nextHeight)
        }
    }

    struct LayoutMetrics {
        let lineCount: Int
        let singleLineHeight: CGFloat

        var contentHeight: CGFloat {
            CGFloat(lineCount) * singleLineHeight
        }
    }

    static func defaultMetrics(for font: NSFont) -> LayoutMetrics {
        LayoutMetrics(
            lineCount: 1,
            singleLineHeight: ceil(
                NSLayoutManager().defaultLineHeight(for: font)
            )
        )
    }

    static func measureLayoutMetrics(
        text: String,
        width: CGFloat,
        font: NSFont
    ) -> LayoutMetrics {
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

        if layoutManager.extraLineFragmentTextContainer != nil,
           !layoutManager.extraLineFragmentRect.isEmpty {
            lineCount += 1
        }

        return LayoutMetrics(
            lineCount: max(1, lineCount),
            singleLineHeight: lineHeight
        )
    }
}
