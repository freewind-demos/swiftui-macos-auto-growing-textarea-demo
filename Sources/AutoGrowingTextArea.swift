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
        .background {
            ReturnKeyInterceptor(isEnabled: isFocused)
                .frame(width: 0, height: 0)
        }
    }
}

private struct ReturnKeyInterceptor: NSViewRepresentable {
    let isEnabled: Bool

    func makeNSView(context: Context) -> InterceptorView {
        let view = InterceptorView()
        view.isEnabled = isEnabled
        return view
    }

    func updateNSView(_ nsView: InterceptorView, context: Context) {
        nsView.isEnabled = isEnabled
    }
}

private final class InterceptorView: NSView {
    var isEnabled = false
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            removeMonitor()
            return
        }

        installMonitorIfNeeded()
    }

    deinit {
        removeMonitor()
    }

    private func installMonitorIfNeeded() {
        guard monitor == nil else {
            return
        }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else {
                return event
            }

            return self.handle(event)
        }
    }

    private func removeMonitor() {
        guard let monitor else {
            return
        }

        NSEvent.removeMonitor(monitor)
        self.monitor = nil
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard isEnabled else {
            return event
        }

        let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])
        guard event.keyCode == 36, modifiers.isEmpty else {
            return event
        }

        guard let textView = window?.firstResponder as? NSTextView else {
            return event
        }

        let selector = #selector(NSStandardKeyBindingResponding.insertLineBreak(_:))
        textView.doCommand(by: selector)
        return nil
    }
}
