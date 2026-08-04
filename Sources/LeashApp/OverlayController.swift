import AppKit
import Combine
import SwiftUI

@MainActor
final class OverlayModel: ObservableObject {
    @Published var task = ""
    @Published var remaining = "0:00"
    @Published var caughtApp: String?
    @Published var modeLabel = ""
    @Published var finishLine: String?
    @Published var canComplete = true
    @Published var isCompletion = false
    @Published var isTimeboxEnded = false
    var onComplete: (() -> Void)?
    var onReturn: (() -> Void)?
    var onExtend: (() -> Void)?
    var onRelease: (() -> Void)?
}

struct LeashOverlayView: View {
    @ObservedObject var model: OverlayModel

    var body: some View {
        Group {
            if model.isCompletion {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(red: 0.25, green: 0.49, blue: 0.23))
                        Text("Task complete")
                            .font(.system(size: 13, weight: .bold))
                    }
                    Text(model.task)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text("Leash released")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if model.isTimeboxEnded {
                VStack(alignment: .leading, spacing: 7) {
                    Label("Time is up", systemImage: "timer")
                        .font(.system(size: 13, weight: .bold))
                    Text(model.task)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    if let finishLine = model.finishLine {
                        Text(finishLine)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 7) {
                        Button("Finished") { model.onComplete?() }
                            .buttonStyle(OverlayCompletionButtonStyle())
                            .disabled(!model.canComplete)
                            .opacity(model.canComplete ? 1 : 0.38)
                        Button("+10 min") { model.onExtend?() }
                            .buttonStyle(OverlayReturnButtonStyle())
                        Button("Release") { model.onRelease?() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 3)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let caughtApp = model.caughtApp {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Color(red: 0.90, green: 0.33, blue: 0.21))
                            .frame(width: 9, height: 9)
                        Text("Caught \(caughtApp)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    Text(model.modeLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(model.task)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    if let finishLine = model.finishLine {
                        Text(finishLine)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 7) {
                        Button("Yes, finish") { model.onComplete?() }
                            .buttonStyle(OverlayCompletionButtonStyle())
                            .disabled(!model.canComplete)
                            .opacity(model.canComplete ? 1 : 0.38)
                        Button("No, back to task") { model.onReturn?() }
                            .buttonStyle(OverlayReturnButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 9) {
                    LeashGlyph(size: 18)
                    Text(model.task)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(model.remaining)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(Color(red: 0.12, green: 0.13, blue: 0.11))
        .background(
            RoundedRectangle(
                cornerRadius: model.caughtApp == nil && !model.isCompletion && !model.isTimeboxEnded ? 18 : 16,
                style: .continuous
            )
                .fill(Color(red: 0.98, green: 0.97, blue: 0.93).opacity(0.97))
                .stroke(Color.black.opacity(0.16), lineWidth: 1)
        )
        .padding(2)
    }
}

struct LeashGlyph: View {
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary, lineWidth: max(1.5, size * 0.08))
            Capsule()
                .fill(Color(red: 0.90, green: 0.33, blue: 0.21))
                .frame(width: size * 0.42, height: size * 0.13)
                .rotationEffect(.degrees(-35))
        }
        .frame(width: size, height: size)
    }
}

@MainActor
final class OverlayController {
    private let model = OverlayModel()
    private let panel: NSPanel
    private var resetWorkItem: DispatchWorkItem?

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 42),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: LeashOverlayView(model: model))
    }

    func start(task: String, remaining: String) {
        resetWorkItem?.cancel()
        model.task = task
        model.remaining = remaining
        model.caughtApp = nil
        model.isCompletion = false
        model.isTimeboxEnded = false
        model.finishLine = nil
        model.onComplete = nil
        model.onReturn = nil
        panel.ignoresMouseEvents = true
        panel.setContentSize(NSSize(width: 280, height: 42))
        panel.orderOut(nil)
    }

    func update(task: String, remaining: String) {
        model.task = task
        model.remaining = remaining
        if panel.isVisible { reposition() }
    }

    func showCatch(
        appName: String,
        task: String,
        finishLine: String?,
        canComplete: Bool,
        pulledBack: Bool,
        onComplete: @escaping () -> Void,
        onReturn: @escaping () -> Void
    ) {
        resetWorkItem?.cancel()
        model.task = task
        model.caughtApp = appName
        model.isCompletion = false
        model.isTimeboxEnded = false
        model.finishLine = finishLine
        model.canComplete = canComplete
        model.modeLabel = pulledBack ? "Pulled you back to the task" : "Does this belong inside the task?"
        model.onComplete = onComplete
        model.onReturn = onReturn
        panel.ignoresMouseEvents = false
        panel.setContentSize(NSSize(width: 370, height: finishLine == nil ? 132 : 154))
        reposition()
        panel.orderFrontRegardless()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.model.caughtApp = nil
            self.model.finishLine = nil
            self.model.onComplete = nil
            self.model.onReturn = nil
            self.panel.ignoresMouseEvents = true
            self.panel.orderOut(nil)
        }
        resetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: workItem)
    }

    func showTimeboxEnded(
        task: String,
        finishLine: String?,
        canComplete: Bool,
        onComplete: @escaping () -> Void,
        onExtend: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) {
        resetWorkItem?.cancel()
        model.task = task
        model.caughtApp = nil
        model.isCompletion = false
        model.isTimeboxEnded = true
        model.finishLine = finishLine
        model.canComplete = canComplete
        model.onComplete = onComplete
        model.onReturn = nil
        model.onExtend = onExtend
        model.onRelease = onRelease
        panel.ignoresMouseEvents = false
        panel.setContentSize(NSSize(width: 370, height: finishLine == nil ? 122 : 144))
        reposition()
        panel.orderFrontRegardless()
    }

    func updateTimeboxEnded(finishLine: String?, canComplete: Bool) {
        guard model.isTimeboxEnded else { return }
        model.finishLine = finishLine
        model.canComplete = canComplete
    }

    func showCompletion(task: String) {
        resetWorkItem?.cancel()
        model.task = task
        model.caughtApp = nil
        model.isCompletion = true
        model.isTimeboxEnded = false
        model.finishLine = nil
        model.onComplete = nil
        model.onReturn = nil
        panel.ignoresMouseEvents = true
        panel.setContentSize(NSSize(width: 300, height: 84))
        reposition()
        panel.orderFrontRegardless()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.model.isCompletion = false
            self.panel.orderOut(nil)
        }
        resetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8, execute: workItem)
    }

    func hide() {
        guard !model.isCompletion, !model.isTimeboxEnded else { return }
        resetWorkItem?.cancel()
        model.caughtApp = nil
        model.finishLine = nil
        model.onComplete = nil
        model.onReturn = nil
        panel.ignoresMouseEvents = true
        panel.orderOut(nil)
    }

    func stop() {
        resetWorkItem?.cancel()
        model.caughtApp = nil
        model.isCompletion = false
        model.isTimeboxEnded = false
        model.finishLine = nil
        model.onComplete = nil
        model.onReturn = nil
        model.onExtend = nil
        model.onRelease = nil
        panel.ignoresMouseEvents = true
        panel.orderOut(nil)
    }

    func reposition() {
        let cursor = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        var origin = NSPoint(x: cursor.x + 18, y: cursor.y - panel.frame.height - 18)
        origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - panel.frame.width - 8)
        origin.y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - panel.frame.height - 8)
        panel.setFrameOrigin(origin)
    }
}

private struct OverlayCompletionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color(red: 0.12, green: 0.13, blue: 0.11))
            .padding(.horizontal, 13)
            .frame(height: 28)
            .background(Color(red: 0.85, green: 0.98, blue: 0.39).opacity(configuration.isPressed ? 0.65 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct OverlayReturnButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 13)
            .frame(height: 28)
            .background(Color(red: 0.12, green: 0.13, blue: 0.11).opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
