import AppKit
import OSLog
import SwiftUI

@MainActor
final class CodexMuxAppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = PulseCoordinator()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    private let logger = Logger(subsystem: "dev.hsi.codexmux", category: "menubar")

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.logger.notice("applicationDidFinishLaunching bundleURL=\(Bundle.main.bundleURL.path(), privacy: .public)")
        self.coordinator.start()
        ProcessInfo.processInfo.disableAutomaticTermination("CodexMux menu bar app")
        DispatchQueue.main.async {
            self.logger.notice("installing status item")
            self.installStatusItem()
            self.installPopover()
            self.logger.notice("status item installed hasButton=\(self.statusItem?.button != nil, privacy: .public)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProcessInfo.processInfo.enableAutomaticTermination("CodexMux menu bar app")
    }

    private func installStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "CodexMuxStatusItem"
        statusItem.isVisible = true

        if let button = statusItem.button {
            button.image = Self.codexMenuBarIcon
            button.imagePosition = .imageOnly
            if button.image == nil {
                button.title = "CM"
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        self.statusItem = statusItem
    }

    private func installPopover() {
        let hostingController = NSHostingController(rootView: PulseMenuView(coordinator: self.coordinator))
        self.popover.contentViewController = hostingController
        self.popover.behavior = .transient
        self.popover.animates = true
        self.popover.contentSize = NSSize(width: 440, height: 620)
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = self.statusItem?.button else {
            return
        }

        if self.popover.isShown {
            self.popover.performClose(sender)
            return
        }

        self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.popover.contentViewController?.view.window?.becomeKey()
    }

    private static var codexMenuBarIcon: NSImage {
        guard let url = AppResources.bundle?.url(forResource: "icon", withExtension: "png", subdirectory: "assets"),
              let image = NSImage(contentsOf: url)
        else {
            return NSImage(systemSymbolName: "gauge.with.needle", accessibilityDescription: "CodexMux") ?? NSImage()
        }

        image.size = NSSize(width: 16, height: 16)
        image.isTemplate = true
        image.accessibilityDescription = "CodexMux"
        return image
    }
}

@main
struct CodexMuxApp: App {
    @NSApplicationDelegateAdaptor(CodexMuxAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
