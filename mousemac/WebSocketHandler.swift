// WebSocketHandler.swift

import Foundation
import AppKit

class WebSocketHandler: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private let appDelegate: AppDelegate
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        super.init()
    }
    
    func connect(to url: URL) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessages()
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received: \(text)")
                    self?.handleReceivedCoordinates(text)
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    fatalError()
                }
                
                self?.receiveMessages()
                
            case .failure(let error):
                print("Error receiving message: \(error)")
            }
        }
    }
    
    private func handleReceivedCoordinates(_ message: String) {
        // Parse coordinates from string format: "x:123,y:456"
        guard let commaIndex = message.firstIndex(of: ","),
              let xIndex = message.firstIndex(of: ":"),
              let yIndex = message.lastIndex(of: ":") else {
            print("Invalid coordinate format")
            return
        }
        
        let xStr = message[xIndex...].dropFirst()
        let yStr = message[commaIndex...][yIndex...].dropFirst()
        
        guard let x = Double(xStr),
              let y = Double(yStr) else {
            print("Invalid coordinate values")
            return
        }
        appDelegate.showMessage("Координаты: \(message)")
        appDelegate.moveMouseTo(x: x, y: y)
    }
    
    func sendCoordinates(x: Double, y: Double) {
        guard let webSocketTask = webSocketTask else { return }
        
        let message = "x:\(Int(x)),y:\(Int(y))"
        let websocketMessage = URLSessionWebSocketTask.Message.string(message)
        
        webSocketTask.send(websocketMessage) { error in
            if let error = error {
                print("Error sending coordinates: \(error)")
            }
        }
    }
    func send(_ text: String) {
        guard let webSocketTask = webSocketTask else { return }
        
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
}
