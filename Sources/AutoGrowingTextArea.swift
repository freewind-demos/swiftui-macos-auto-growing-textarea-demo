import SwiftUI

struct AutoGrowingTextArea: View {
    @Binding private var text: String
    private let prompt: LocalizedStringKey
    private let lineLimit: ClosedRange<Int>
    private let font: Font
    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        prompt: LocalizedStringKey = "请输入内容",
        lineLimit: ClosedRange<Int> = 1...12,
        font: Font = .body
    ) {
        _text = text
        self.prompt = prompt
        self.lineLimit = lineLimit
        self.font = font
    }

    var body: some View {
        TextField(
            prompt,
            text: $text,
            axis: .vertical
        )
        .textFieldStyle(.plain)
        .font(font)
        .lineLimit(lineLimit)
        .focused($isFocused)
        .overlay {
            Button(action: insertNewline) {
                EmptyView()
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.plain)
            .disabled(!isFocused)
            .opacity(0.001)
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
        }
    }

    private func insertNewline() {
        guard isFocused else {
            return
        }

        text.append("\n")
    }
}
