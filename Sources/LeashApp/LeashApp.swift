import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}

@main
struct LeashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var coordinator = LeashCoordinator()

    var body: some Scene {
        MenuBarExtra {
            LeashMenuView(coordinator: coordinator)
        } label: {
            Label("Leash", systemImage: coordinator.session == nil ? "circle.dashed" : "link.circle.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
