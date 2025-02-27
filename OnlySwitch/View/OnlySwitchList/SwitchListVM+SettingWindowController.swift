//
//  SwitchListVM+SettingWindowController.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2022/7/24.
//

import Foundation
import AppKit

extension SwitchListVM: SettingWindowController {
    private struct Holder {
        static var _settingsWindowPresented = false
        static var _settingsWindow:NSWindow?
        static var _coordinator:Coordinator = Coordinator()
    }
    
    internal var settingsWindowPresented: Bool {
        get {
            return Holder._settingsWindowPresented
        }
        set {
            Holder._settingsWindowPresented = newValue
        }
    }
    
    internal var settingsWindow: NSWindow? {
        get {
            return Holder._settingsWindow
        }
        set {
            newValue?.delegate = coodinator
            Holder._settingsWindow = newValue
        }
    }
    
    private var coodinator:Coordinator {
        return Holder._coordinator
    }
    
    func receiveSettingWindowOperation() {
        NotificationCenter.default.addObserver(forName: .settingsWindowOpened,
                                               object: nil,
                                               queue: .main,
                                               using: { notify in
            if let window = notify.object as? NSWindow {
                if self.settingsWindow == nil {
                    self.settingsWindow = window
                    self.settingsWindow?.makeKeyAndOrderFront(self)
                    
                    if #available(macOS 13.0, *) {
                        var windowFrame = window.frame
                        windowFrame.size.height = Layout.settingWindowHeight
                        window.setFrame(windowFrame, display: true)
                        window.styleMask.remove(.resizable)
                    } else {
                        self.settingsWindow?.styleMask = [.titled, .closable, .miniaturizable]
                    }
                } else {
                    if self.settingsWindowPresented == false {
                        self.showSettingsWindow()
                    } else {
                        window.close()
                    }
                }
            }
        })
        
        NotificationCenter.default.addObserver(forName: .settingsWindowClosed,
                                               object: nil,
                                               queue: .main,
                                               using: { _ in
            self.settingsWindowPresented = false
            NSApp.activate(ignoringOtherApps: false)
        })
        
        NotificationCenter.default.addObserver(forName: .toggleSplitSettingsWindow,
                                               object: nil,
                                               queue: .main,
                                               using: { _ in
            self.settingsWindow?
                .contentViewController?
                .tryToPerform(
                    #selector(
                        NSSplitViewController
                            .toggleSidebar(_:)),
                    with:nil)
        })
    }
    
    func showSettingsWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = self.settingsWindow {
            window.makeKeyAndOrderFront(self)
            if #available(macOS 13.0, *) {
                var windowFrame = window.frame
                windowFrame.size.height = Layout.settingWindowHeight
                window.setFrame(windowFrame, display: true)
                window.styleMask.remove(.resizable)
            }
        } else {
            if let url = URL(string: "onlyswitch://SettingsWindow") {
                if #available(macOS 13.3, *) {
                    if !isSettingViewShowing {
                        NSWorkspace.shared.open(url)
                        isSettingViewShowing = true
                        print("new setting window appears")
                    }
                } else {
                    NSWorkspace.shared.open(url)
                    print("new setting window appears")
                }
            }
        }
        self.settingsWindowPresented = true
        NotificationCenter.default.post(name: .shouldHidePopover, object: nil)
    }
    
    class Coordinator:NSObject, NSWindowDelegate {
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            onClose()
            return true
        }
        
        func onClose() {
            print("settings window closing")
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first!.makeKeyAndOrderFront(self)
            NSApp.setActivationPolicy(.accessory)
            NotificationCenter.default.post(name: .settingsWindowClosed, object: nil)
        }
    }
}

