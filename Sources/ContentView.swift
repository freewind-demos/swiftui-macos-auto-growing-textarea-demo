import SwiftUI

struct ContentView: View {
    private let editorFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

    @State private var text = """
第一行
第二行会随内容继续增长，不会出现内部滚动条。
"""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auto-growing text area")
                .font(.title2)

            Text("外部只传 text binding；宽度与高度内部自处理。")
                .foregroundStyle(.secondary)

            AutoGrowingTextArea(
                text: $text,
                font: editorFont
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
