import AppKit
import SwiftUI

@MainActor
final class CodexMuxLifecycleDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("CodexMux menu bar app")
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProcessInfo.processInfo.enableAutomaticTermination("CodexMux menu bar app")
    }
}

@main
struct CodexMuxApp: App {
    @NSApplicationDelegateAdaptor(CodexMuxLifecycleDelegate.self) private var lifecycleDelegate
    @StateObject private var coordinator = PulseCoordinator()

    var body: some Scene {
        MenuBarExtra {
            PulseMenuView(coordinator: self.coordinator)
                .task {
                    self.coordinator.start()
                    await self.coordinator.syncNow()
                }
        } label: {
            Image(nsImage: Self.codexMenuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }

    private static var codexMenuBarIcon: NSImage {
        let image = AppResources.image(named: "icon", withExtension: "png", subdirectory: "assets")
            ?? AppResources.image(named: "CodexMux", withExtension: "icns")
            ?? NSApplication.shared.applicationIconImage

        guard let image else {
            return NSImage(systemSymbolName: "gauge.with.needle", accessibilityDescription: "CodexMux") ?? NSImage()
        }

        image.size = NSSize(width: 16, height: 16)
        image.isTemplate = true
        image.accessibilityDescription = "CodexMux"
        return image
    }
}
