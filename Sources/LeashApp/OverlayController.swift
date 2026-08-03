import AppKit
import Combine
import SwiftUI

@MainActor
final class OverlayModel: ObservableObject {
    @Published var task = ""
    @Published var remaining = "0:00"
    @Published var caughtApp: String?
    @Published var modeLabel = ""
}

struct LeashOverlayView: View {
    @ObservedObject var model: OverlayModel

    var body: some View {
        Group {
            if let caughtApp = model.caughtApp {
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
            RoundedRectangle(cornerRadius: model.caughtApp == nil ? 18 : 16, style: .continuous)
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
        model.task = task
        model.remaining = remaining
        model.caughtApp = nil
        panel.setContentSize(NSSize(width: 280, height: 42))
        reposition()
        panel.orderFrontRegardless()
    }

    func update(task: String, remaining: String) {
        model.task = task
        model.remaining = remaining
        reposition()
    }

    func showCatch(appName: String, task: String, pulledBack: Bool) {
        resetWorkItem?.cancel()
        model.task = task
        model.caughtApp = appName
        model.modeLabel = pulledBack ? "Pulled you back to the task" : "Does this belong inside the task?"
        panel.setContentSize(NSSize(width: 330, height: 92))
        reposition()
        panel.orderFrontRegardless()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.model.caughtApp = nil
            self.panel.setContentSize(NSSize(width: 280, height: 42))
            self.reposition()
        }
        resetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: workItem)
    }

    func stop() {
        resetWorkItem?.cancel()
        panel.orderOut(nil)
    }

    func reposition() {
        guard panel.isVisible || !model.task.isEmpty else { return }
        let cursor = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }

        var origin = NSPoint(x: cursor.x + 18, y: cursor.y - panel.frame.height - 18)
        origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - panel.frame.width - 8)
        origin.y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - panel.frame.height - 8)
        panel.setFrameOrigin(origin)
    }
}
