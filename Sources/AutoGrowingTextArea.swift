import SwiftUI

struct AutoGrowingTextArea: View {
    @Binding private var text: String
    private let prompt: LocalizedStringKey
    private let lineLimit: ClosedRange<Int>
    private let font: Font

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
    }
}
