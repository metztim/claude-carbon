//
//  AppDelegate.swift
//  ClaudeCarbon
//
//  Application delegate handling URL scheme registration.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("ClaudeCarbon: applicationDidFinishLaunching")

        // SINGLE INSTANCE CHECK: Quit if another instance is already running
        let runningApps = NSWorkspace.shared.runningApplications
        let myBundleId = Bundle.main.bundleIdentifier ?? "com.claudecarbon.app"
        let instances = runningApps.filter { $0.bundleIdentifier == myBundleId }

        if instances.count > 1 {
            print("ClaudeCarbon: Another instance is already running. Quitting.")
            NSApp.terminate(nil)
            return
        }

        // Disable automatic termination - prevents macOS from auto-quitting/restarting
        ProcessInfo.processInfo.disableAutomaticTermination("ClaudeCarbon is a menu bar app")
        ProcessInfo.processInfo.disableSuddenTermination()

        // Register URL scheme handler
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        print("ClaudeCarbon: Initialization complete")
    }

    // MARK: - URL Scheme Handling

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        URLSchemeHandler.shared.handle(url: url)
    }
}
