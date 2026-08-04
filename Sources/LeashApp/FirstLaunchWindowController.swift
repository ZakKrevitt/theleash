import AppKit
import SwiftUI

@MainActor
final class FirstLaunchWindowController: NSWindowController {
    init(coordinator: LeashCoordinator) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 490),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Leash"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.contentView = NSHostingView(
            rootView: LeashMenuView(coordinator: coordinator)
                .frame(maxHeight: .infinity, alignment: .top)
        )
        super.init(window: window)
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate()
    }

    func showSetup() {
        window?.setContentSize(NSSize(width: 390, height: 760))
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
