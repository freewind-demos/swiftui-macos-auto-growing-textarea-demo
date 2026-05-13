import SwiftUI

struct ContentView: View {
    private let editorFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

    @State private var text = """
第一行
第二行会随内容继续增长，不会出现内部滚动条。
"""
    @State private var editorMetrics = TextLayoutMetrics.systemDefault

    var body: some View {
        GeometryReader { proxy in
            let editorWidth = max(proxy.size.width - 48, 200)

            VStack(alignment: .leading, spacing: 12) {
                Text("Auto-growing text area")
                    .font(.title2)

                Text("高度只跟内容走；不留多余空行；不裁剪；不出内部滚动。")
                    .foregroundStyle(.secondary)

                AutoGrowingTextArea(
                    text: $text,
                    metrics: $editorMetrics,
                    width: editorWidth,
                    font: editorFont
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
