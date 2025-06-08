import Foundation
import UIKit
import CoreLocation
import Combine

@MainActor
class RideGiverWebSocketManager: NSObject, ObservableObject {
    static let shared = RideGiverWebSocketManager()
    private var webSocket: URLSessionWebSocketTask?
    private var pingPongTimer: Timer?
    private let wsUrl = "wss://lyncwyzeapi.intellylabs.com/match/connect"
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var lastConnectionParams: (rideId: String, userId: String)?
    private var isReconnecting = false
    private var session: URLSession?
    private var isDisconnecting = false
    private var reconnectTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var locationUpdateCancellable: AnyCancellable?
    
    // Exponential backoff parameters
    private let initialReconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0
    
    @Published var currentStatus: RideStatus = .scheduled
    @Published var nextStatus: WebSocketEvents = .rideStart
    @Published var isConnected = false {
        didSet {
            if isConnected {
                startPingPong()
                reconnectAttempts = 0
                stopReconnectTimer()
                startLocationUpdates()
            } else {
                stopPingPong()
                stopLocationUpdates()
            }
        }
    }
    @Published var error: String?
    @Published var buttonTitle: String = "Start Ride"
    @Published var showFeedbackSheet = false
    @Published var feedbackData: FeedBackPreReq?
    
    var onStatusUpdate: ((RideStatus, WebSocketEvents, String?) -> Void)?
    var onError: ((String) -> Void)?
    var currentRide: EachRide?
    
    private var messageQueue: [(message: String, completion: ((Error?) -> Void)?)] = []
    private var isProcessingQueue = false
    
    private var statusUpdateWorkItem: DispatchWorkItem?
    
    private var lastStatusFetchTime: Date = .distantPast
    
    private override init() {
        super.init()
        print("🔵 RideGiverWebSocketManager initialized")
        setupBackgroundHandling()
    }
    
    deinit {
        Task { @MainActor in
            cleanup()
        }
    }
    
    private func startLocationUpdates() {
        Task { @MainActor in
            LocationManager.shared.startUpdatingLocation { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let coordinates):
                    if self.isConnected {
                        let event = WsEvent(
                            socketEventType: .locationUpdate,
                            rideId: self.lastConnectionParams?.rideId ?? "",
                            latitude: coordinates[0],
                            longitude: coordinates[1]
                        )
                        self.sendEvent(event)
                    }
                case .failure(let error):
                    self.handleError("Location error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopLocationUpdates() {
        Task { @MainActor in
            LocationManager.shared.stopUpdatingLocation()
        }
    }
    
    func handleButtonAction() {
        Task {
            do {
                let coordinates = try await LocationManager.shared.getCurrentCoordinates()
                
                // Check if we have valid ride data
                guard let ride = currentRide else {
                    handleError("No ride data available")
                    return
                }
                
                // Verify current status matches expected flow
                if nextStatus == .rideStart && currentStatus != .scheduled {
                    // Fetch current status to sync UI
                    fetchCurrentRideStatus(rideId: ride.id)
                    return
                }
                
                switch nextStatus {
                case .rideStart:
                    let startEvent = RideStartEvent(
                        socketEventType: .rideStart,
                        rideId: ride.id,
                        startLatitude: coordinates[0],
                        startLongitude: coordinates[1],
                        endLatitude: ride.dropoffAddress.location.coordinates[1],
                        endLongitude: ride.dropoffAddress.location.coordinates[0]
                    )
                    sendEvent(startEvent)
                    
                case .riderArrived:
                    sendLocationEvent(.riderArrived, coordinates: coordinates)
                    
                case .arrivedAtActivity:
                    sendLocationEvent(.arrivedAtActivity, coordinates: coordinates)
                    
                case .returnedActivity:
                    sendLocationEvent(.returnedActivity, coordinates: coordinates)
                    
                case .pickedUpFromActivity:
                    sendLocationEvent(.pickedUpFromActivity, coordinates: coordinates)
                    
                case .returnedHome:
                    sendLocationEvent(.returnedHome, coordinates: coordinates)
                    
                default:
                    print("⚠️ Unknown next status: \(nextStatus)")
                }
            } catch {
                handleError("Current location not available: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendLocationEvent(_ event: WebSocketEvents, coordinates: [Double]) {
        guard let ride = currentRide else { return }
        
        let event = WsEvent(
            socketEventType: event,
            takerId: ride.rideTakers[0].userId,
            rideId: ride.id,
            latitude: coordinates[0],
            longitude: coordinates[1]
        )
        sendEvent(event)
    }
    
    func fetchCurrentRideStatus(rideId: String) {
        let statusEvent = WsEventGeneral(
            socketEventType: .status,
            rideId: rideId
        )
        sendEvent(statusEvent)
    }
    
    private func debouncedStatusUpdate(status: RideStatus, dateTime: String? = nil) {
        statusUpdateWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.updateButtonTitle(for: status)
                if let nextStatus = self?.nextStatus {
                    self?.onStatusUpdate?(status, nextStatus, dateTime)
                }
            }
        }
        
        statusUpdateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func handleMessage(_ text: String) {
        print("📥 Processing message: \(text)")
        
        do {
            guard let data = text.data(using: .utf8) else {
                print("❌ Could not convert text to data")
                return
            }
            
            if text.uppercased() == "PONG" {
                print("📍 Received pong")
                return
            }
            
            if text.uppercased() == "PING" {
                print("📍 Received ping, sending pong")
                send(message: "PONG")
                return
            }
            
            if let message = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                
                Task { @MainActor in
                    switch message.socketEventType {
                    case .status:
                        if let status = message.rideStatus {
                            self.currentStatus = status
                            
                            // Use debounced status update with datetime
                            self.debouncedStatusUpdate(status: status, dateTime: message.dateTime)
                        }
                        
                    case .error:
                        if let errorCode = message.errorCode {
                            switch errorCode {
                            case 7007:
                                print("⚠️ Invalid ride status transition")
                                if let rideId = self.lastConnectionParams?.rideId {
                                    self.fetchCurrentRideStatus(rideId: rideId)
                                }
                            case 7010:
                                print("⚠️ Already an ongoing ride")
                                if let rideId = self.lastConnectionParams?.rideId {
                                    self.fetchCurrentRideStatus(rideId: rideId)
                                }
                            default:
                                print("⚠️ Unhandled error code: \(errorCode)")
                                if let description = message.errorDescription {
                                    self.handleError(description)
                                }
                            }
                        }
                        
                    default:
                        break
                    }
                }
            }
        } catch {
            print("❌ Error processing message: \(error)")
        }
    }
    
    private func handleRideCompletion() {
        guard let ride = currentRide else { return }
        
        let feedback = FeedBackPreReq(
            rideId: ride.id,
            fromUserId: ride.userId,
            fromUserName: "\(ride.userFirstName) \(ride.userLastName)",
            forUserId: ride.rideTakers[0].userId,
            forUserName: "\(ride.rideTakers[0].userFirstName) \(ride.rideTakers[0].userLastName)",
            date: ride.date,
            riderType: .giver
        )
        
        feedbackData = feedback
        showFeedbackSheet = true
        disconnectWebSocket()
    }
    
    func disconnect() {
        print("🔵 Disconnecting WebSocket")
        isDisconnecting = true
        cleanup()
    }
    
    private func cleanup() {
        print("🧹 Cleaning up WebSocket resources")
        stopPingPong()
        stopReconnectTimer()
        stopLocationUpdates()
        endBackgroundTask()
        
        if let ws = webSocket {
            ws.cancel(with: .normalClosure, reason: "Disconnecting".data(using: .utf8))
            webSocket = nil
        }
        
        session?.invalidateAndCancel()
        session = nil
        
        isConnected = false
        isReconnecting = false
        
        if isDisconnecting {
            reconnectAttempts = 0
            lastConnectionParams = nil
            onStatusUpdate = nil
            error = nil
            messageQueue.removeAll()
            isProcessingQueue = false
        }
    }
    
    private func startPingPong() {
        guard isConnected, !isDisconnecting else { return }
        
        stopPingPong()
        pingPongTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingPong() {
        pingPongTimer?.invalidate()
        pingPongTimer = nil
    }
    
    private func sendPing() {
        guard isConnected, !isDisconnecting, let ws = webSocket else {
            print("⚠️ Cannot send PING: WebSocket not connected or disconnecting")
            return
        }
        
        ws.sendPing { [weak self] error in
            guard let self = self, !self.isDisconnecting else { return }
            
            if let error = error {
                print("❌ PING failed: \(error)")
                self.handleConnectionFailure()
            } else {
                print("✅ PING successful")
            }
        }
    }
    
    func sendEvent(_ event: WebSocketMessageType) {
        guard isConnected else {
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(event)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Event JSON: \(jsonString)")
                send(message: jsonString)
                
                // After sending an event, fetch current status after a longer delay
                // and only if enough time has passed since last fetch
                Task {
                    try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                    
                    // Guard against redundant fetches
                    guard Date().timeIntervalSince(lastStatusFetchTime) >= 0.5 else {
                        print("⚠️ Skipping status fetch - too soon since last fetch")
                        return
                    }
                    
                    lastStatusFetchTime = Date()
                    fetchCurrentRideStatus(rideId: lastConnectionParams?.rideId ?? "")
                }
            }
        } catch {
            print("❌ Error encoding WebSocket message: \(error)")
        }
    }
    
    private func send(message: String) {
        print("📤 Sending message: \(message)")
        webSocket?.send(.string(message)) { [weak self] error in
            if let error = error {
                print("❌ Failed to send message: \(error)")
                self?.handleConnectionFailure()
            }
        }
    }
    
    private func handleConnectionFailure() {
        guard !isDisconnecting else { return }
        
        isConnected = false
        if !isDisconnecting {
            reconnect()
        }
    }
    
    private func reconnect() {
        guard !isDisconnecting,
              !isReconnecting,
              reconnectAttempts < maxReconnectAttempts,
              let params = lastConnectionParams else {
            print("❌ Cannot reconnect: isDisconnecting=\(isDisconnecting), isReconnecting=\(isReconnecting), attempts=\(reconnectAttempts), hasParams=\(lastConnectionParams != nil)")
            if reconnectAttempts >= maxReconnectAttempts {
                handleError("Failed to reconnect after \(maxReconnectAttempts) attempts")
            }
            return
        }
        
        isReconnecting = true
        reconnectAttempts += 1
        let delay = calculateReconnectDelay()
        
        print("🔄 Attempting to reconnect in \(delay) seconds (Attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, !self.isDisconnecting else { return }
            
            print("🔄 Reconnecting with stored parameters")
            self.isReconnecting = false
            self.connect(rideId: params.rideId, userId: params.userId)
        }
    }
    
    private func calculateReconnectDelay() -> TimeInterval {
        let delay = initialReconnectDelay * pow(2.0, Double(reconnectAttempts - 1))
        return min(delay, maxReconnectDelay)
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self, !self.isDisconnecting else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                if !self.isDisconnecting {
                    self.receiveMessage()
                }
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                if !self.isDisconnecting {
                    self.handleConnectionFailure()
                }
            }
        }
    }
    
    private func handleError(_ message: String) {
        print("❌ WebSocket error: \(message)")
        DispatchQueue.main.async { [weak self] in
            self?.error = message
            self?.onError?(message)
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func setupBackgroundHandling() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }
    
    @objc private func handleAppDidEnterBackground() {
        print("📱 App entering background - Starting background task")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        print("📱 App entering foreground")
        if !isConnected && !isDisconnecting {
            print("🔄 Reconnecting due to app becoming active")
            reconnect()
        }
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func disconnectWebSocket() {
        stopPingPong()
        webSocket?.cancel(with: .normalClosure, reason: "Disconnecting".data(using: .utf8))
        webSocket = nil
    }

    private func processMessageQueue() {
        guard !isProcessingQueue,
              !messageQueue.isEmpty,
              isConnected,
              !isDisconnecting,
              let ws = webSocket else {
            return
        }
        
        isProcessingQueue = true
        let (message, completion) = messageQueue.removeFirst()
        
        print("📤 Sending message from queue: \(message)")
        ws.send(.string(message)) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ WebSocket sending error: \(error)")
                if !self.isDisconnecting {
                    self.messageQueue.insert((message, completion), at: 0)
                }
                completion?(error)
            } else {
                print("✅ Message sent successfully")
                completion?(nil)
            }
            
            self.isProcessingQueue = false
            if !self.messageQueue.isEmpty {
                self.processMessageQueue()
            }
        }
    }

    func connect(with ride: EachRide) {
        currentRide = ride
        connect(rideId: ride.id, userId: ride.rideTakers[0].userId)
    }
    
    func connect(rideId: String, userId: String) {
        print("🔵 Attempting to connect WebSocket - RideID: \(rideId), UserID: \(userId)")
        
        isDisconnecting = false
        messageQueue.removeAll()
        isProcessingQueue = false
        lastConnectionParams = (rideId: rideId, userId: userId)
        
        cleanup()
        
        guard var urlComponents = URLComponents(string: wsUrl) else {
            handleError("Failed to create URL components")
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "role", value: RiderType.giver.rawValue),
            URLQueryItem(name: "rideId", value: rideId),
            URLQueryItem(name: "giverId", value: userId)
        ]
        
        guard let url = urlComponents.url else {
            handleError("Failed to create final URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔵 Added authorization token to request")
        } else {
            let error = "No authorization token found"
            print("⚠️ \(error)")
            handleError(error)
            return
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        webSocket = session?.webSocketTask(with: request)
        webSocket?.maximumMessageSize = 1024 * 1024
        
        webSocket?.resume()
        print("🔵 WebSocket task created and resumed")
        
        receiveMessage()
    }
    
    private func updateButtonTitle(for status: RideStatus) {
        Task { @MainActor in
            switch status {
            case .scheduled:
                buttonTitle = "Start Ride"
                nextStatus = .rideStart
            case .started:
                if currentRide?.rideTakers[0].role == .pick {
                    buttonTitle = "Returned to Activity"
                    nextStatus = .returnedActivity
                } else {
                    buttonTitle = "Arrived at Location"
                    nextStatus = .riderArrived
                }
            case .riderArrived:
                buttonTitle = "Arrived at Location"
                nextStatus = .riderArrived
            case .pickedUp:
                buttonTitle = "Arrived at Activity"
                nextStatus = .arrivedAtActivity
            case .arrivedAtActivity:
                buttonTitle = "Heading to Pick from Activity"
                nextStatus = .activityOngoing
            case .activityOngoing:
                if currentRide?.rideTakers[0].role == .pick {
                    buttonTitle = "Drop Off at Home"
                } else {
                    buttonTitle = "Returned to Activity"
                    nextStatus = .returnedActivity
                }
            case .returnedActivity:
                buttonTitle = "Pick Up from Activity"
                nextStatus = .pickedUpFromActivity
            case .pickedUpFromActivity:
                buttonTitle = "Drop Off at Home"
                nextStatus = .returnedHome
            case .returnedHome:
                buttonTitle = "Drop Off at Home"
                nextStatus = .returnedHome
            case .completed:
                buttonTitle = "Ride Completed"
            @unknown default:
                buttonTitle = "Next"
            }
            print("🚦 RideGiver - Stage: \(status.rawValue), Next: \(nextStatus.rawValue), Button: \(buttonTitle)")
        }
    }
}

extension RideGiverWebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected successfully")
        Task { @MainActor in
            guard !self.isDisconnecting else { return }
            self.isConnected = true
            self.reconnectAttempts = 0
            self.isReconnecting = false
            self.error = nil
            
            if !self.messageQueue.isEmpty {
                print("📤 Processing queued messages")
                self.processMessageQueue()
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔵 WebSocket closed - Code: \(closeCode)")
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("🔵 Close reason: \(reasonString)")
        }
        
        Task { @MainActor in
            self.isConnected = false
            
            if closeCode != .normalClosure && !self.isDisconnecting && !self.isReconnecting {
                self.handleConnectionFailure()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ URLSession error: \(error)")
            Task { @MainActor in
                guard !self.isDisconnecting, !self.isReconnecting else { return }
                self.handleConnectionFailure()
            }
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        #if DEBUG
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }
        #endif
        
        completionHandler(.performDefaultHandling, nil)
    }
} 
