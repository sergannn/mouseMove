// AppDelegate.swift
// MoveItMouse
//
// Created by Saadat Baig on 13.06.23.
//
import AppKit
import IOKit.pwr_mgt
import PubNubSDK

var noSleepAssertionID: IOPMAssertionID = 0
var noSleepReturn: IOReturn?

class AppDelegate: NSObject, NSApplicationDelegate {
    var pubnub: PubNub!
    var statusBarItem: NSStatusItem!
    var statusBarMenu: NSMenu!
    var webSocketHandler: WebSocketHandler!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("connecting")
        webSocketHandler = WebSocketHandler(appDelegate: self)
                webSocketHandler.connect(to: URL(string: "ws://77.222.46.176:8090")!)
        let id = UUID().uuidString
        
        // Add mouse move tracking
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            guard let self = self else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            let x = mouseLocation.x
            let y = mouseLocation.y
            
            // Отправляем координаты в формате словаря
            let coordinates = ["x": Double(x), "y": Double(y)]
            self.webSocketHandler.send("x:\(Int(x)),y:\(Int(y))")
            self.webSocketHandler.send(id)
            self.webSocketHandler.sendCoordinates(x: x, y: y)
        }
        
        let statusBar = NSStatusBar.system
        self.statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        self.statusBarItem.button?.image = NSImage(systemSymbolName: "cursorarrow.motionlines",
                                                 accessibilityDescription: "Status Bar Icon")
        self.setupStatusBarMenu()
    }
    
    public func moveMouseTo(x: Double, y: Double) {
        var mouseLocation = CGPoint(x: x, y: y)
        mouseLocation.y = NSHeight(NSScreen.screens[0].frame) - mouseLocation.y
        
        CGDisplayMoveCursorToPoint(0, mouseLocation)
    }
    
    private func setupStatusBarMenu() {
        self.statusBarMenu = NSMenu()
        
        // Добавляем пункты меню с правильными селекторами
        self.statusBarMenu.addItem(withTitle: "Start Mover",
                                 action: #selector(startMouseTracking),
                                 keyEquivalent: "")
        self.statusBarMenu.addItem(withTitle: "End Mover",
                                 action: #selector(stopMouseTracking),
                                 keyEquivalent: "")
        self.statusBarMenu.addItem(NSMenuItem(title: "Quit",
                                            action: #selector(NSApplication.terminate),
                                            keyEquivalent: "q"))
        
        self.statusBarItem.menu = self.statusBarMenu
    }
    
    @objc private func startMouseTracking() {
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handleMouseMove()
        }
    }
    
    @objc private func stopMouseTracking() {
    //    NSEvent.removeMonitor(.global)
    }
    
    private func handleMouseMove() {
        let mouseLocation = NSEvent.mouseLocation
        let x = mouseLocation.x
        let y = mouseLocation.y
        
        let coordinates = ["x": Double(x), "y": Double(y)]
        
        pubnub.publish(channel: "mouse-movements", message: coordinates) { result in
            print(result.map { "Координаты опубликованы в \($0.timetokenDate)" })
        }
    }
}
