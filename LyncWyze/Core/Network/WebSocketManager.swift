import Foundation
import UIKit

enum WebSocketEvents: String, Codable {
    case status = "STATUS"
    case nextStatus = "NEXT_STATUS"
    case rideStart = "RIDE_START"
    case locationUpdate = "LOCATION_UPDATE"
    case riderArrived = "RIDER_ARRIVED"
    case pickedUp = "PICKED_UP"
    case arrivedAtActivity = "ARRIVED_AT_ACTIVITY"
    case activityOngoing = "ACTIVITY_ONGOING"
    case returnedActivity = "RETURNED_ACTIVITY"
    case pickedUpFromActivity = "PICKED_UP_FROM_ACTIVITY"
    case returnedHome = "RETURNED_HOME"
    case rideEnd = "RIDE_END"
    case completed = "COMPLETED"
    case error = "ERROR"
}

struct WebSocketMessage: WebSocketMessageType {
    let socketEventType: WebSocketEvents
    let rideId: String?
    let takerId: String?
    let rideStatus: RideStatus?
    let nextStatus: String?
    let errorCode: Int?
    let errorDescription: String?
    let latitude: Double?
    let longitude: Double?
    let startLatitude: Double?
    let startLongitude: Double?
    let endLatitude: Double?
    let endLongitude: Double?
    let dateTime: String?
    
    enum CodingKeys: String, CodingKey {
        case socketEventType
        case rideId
        case takerId
        case rideStatus
        case nextStatus
        case errorCode
        case errorDescription
        case latitude
        case longitude
        case startLatitude
        case startLongitude
        case endLatitude
        case endLongitude
        case dateTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        socketEventType = try container.decode(WebSocketEvents.self, forKey: .socketEventType)
        rideId = try? container.decodeIfPresent(String.self, forKey: .rideId)
        takerId = try? container.decodeIfPresent(String.self, forKey: .takerId)
        rideStatus = try? container.decodeIfPresent(RideStatus.self, forKey: .rideStatus)
        nextStatus = try? container.decodeIfPresent(String.self, forKey: .nextStatus)
        errorCode = try? container.decodeIfPresent(Int.self, forKey: .errorCode)
        errorDescription = try? container.decodeIfPresent(String.self, forKey: .errorDescription)
        latitude = try? container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try? container.decodeIfPresent(Double.self, forKey: .longitude)
        startLatitude = try? container.decodeIfPresent(Double.self, forKey: .startLatitude)
        startLongitude = try? container.decodeIfPresent(Double.self, forKey: .startLongitude)
        endLatitude = try? container.decodeIfPresent(Double.self, forKey: .endLatitude)
        endLongitude = try? container.decodeIfPresent(Double.self, forKey: .endLongitude)
        dateTime = try? container.decodeIfPresent(String.self, forKey: .dateTime)
    }
    
    // General event initializer
    init(socketEventType: WebSocketEvents, rideId: String? = nil, takerId: String? = nil) {
        self.socketEventType = socketEventType
        self.rideId = rideId
        self.takerId = takerId
        self.rideStatus = nil
        self.nextStatus = nil
        self.errorCode = nil
        self.errorDescription = nil
        self.latitude = nil
        self.longitude = nil
        self.startLatitude = nil
        self.startLongitude = nil
        self.endLatitude = nil
        self.endLongitude = nil
        self.dateTime = nil
    }
    
    // Full initializer for other event types
    init(socketEventType: WebSocketEvents, rideId: String? = nil, takerId: String? = nil,
         rideStatus: RideStatus? = nil, nextStatus: WebSocketEvents? = nil,
         errorCode: Int? = nil, errorDescription: String? = nil,
         latitude: Double? = nil, longitude: Double? = nil,
         startLatitude: Double? = nil, startLongitude: Double? = nil,
         endLatitude: Double? = nil, endLongitude: Double? = nil,
         dateTime: String? = nil) {
        self.socketEventType = socketEventType
        self.rideId = rideId
        self.takerId = takerId
        self.rideStatus = rideStatus
        self.nextStatus = nextStatus?.rawValue
        self.errorCode = errorCode
        self.errorDescription = errorDescription
        self.latitude = latitude
        self.longitude = longitude
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.dateTime = dateTime
    }
}

// MARK: - WebSocket Message Types
protocol WebSocketMessageType: Codable {}

struct WsEventGeneral: WebSocketMessageType {
    let socketEventType: WebSocketEvents
    let rideId: String
    let takerId: String?
    let dateTime: String?
    
    init(socketEventType: WebSocketEvents, rideId: String, takerId: String? = nil, dateTime: String? = nil) {
        self.socketEventType = socketEventType
        self.rideId = rideId
        self.takerId = takerId
        self.dateTime = dateTime
    }
}

struct WsEvent: WebSocketMessageType {
    let socketEventType: WebSocketEvents
    let takerId: String?
    let rideId: String
    let latitude: Double?
    let longitude: Double?
    let dateTime: String?
    
    init(socketEventType: WebSocketEvents, takerId: String? = nil, rideId: String, 
         latitude: Double? = nil, longitude: Double? = nil, dateTime: String? = nil) {
        self.socketEventType = socketEventType
        self.takerId = takerId
        self.rideId = rideId
        self.latitude = latitude
        self.longitude = longitude
        self.dateTime = dateTime
    }
}

struct RideStartEvent: WebSocketMessageType {
    let socketEventType: WebSocketEvents
    let rideId: String
    let startLatitude: Double
    let startLongitude: Double
    let endLatitude: Double
    let endLongitude: Double
    let dateTime: String?
    
    init(socketEventType: WebSocketEvents, rideId: String,
         startLatitude: Double, startLongitude: Double,
         endLatitude: Double, endLongitude: Double,
         dateTime: String? = nil) {
        self.socketEventType = socketEventType
        self.rideId = rideId
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.dateTime = dateTime
    }
}

class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()
    private var webSocket: URLSessionWebSocketTask?
    private var pingPongTimer: Timer?
    private let wsUrl = "wss://lyncwyzeapi.intellylabs.com/match/connect"
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10 // Increased from 5 to 10
    private var lastConnectionParams: (rideId: String, userId: String, riderType: RiderType)?
    private var isReconnecting = false
    private var session: URLSession?
    private var isDisconnecting = false
    private var reconnectTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Exponential backoff parameters
    private let initialReconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0
    
    @Published var currentStatus: RideStatus = .scheduled
    @Published var nextStatus: WebSocketEvents = .rideStart
    @Published var isConnected = false {
        didSet {
            if isConnected {
                startPingPong()
                reconnectAttempts = 0 // Reset attempts on successful connection
                stopReconnectTimer()
            } else {
                stopPingPong()
            }
        }
    }
    @Published var error: String?
    
    var onStatusUpdate: ((RideStatus, WebSocketEvents, String?) -> Void)?
    var onError: ((String) -> Void)?
    
    private var messageQueue: [(message: String, completion: ((Error?) -> Void)?)] = []
    private var isProcessingQueue = false
    
    // Add taker-specific properties
    @Published var showRiderArrivedDialog = false
    @Published var showDropOffDialog = false
    @Published var dialogTitle = ""
    @Published var dialogMessage = ""
    @Published var dialogActionTitle = ""
    var dialogAction: (() -> Void)?
    
    private override init() {
        super.init()
        print("🔵 WebSocketManager initialized")
        setupBackgroundHandling()
    }
    
    deinit {
        cleanup()
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
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    private func calculateReconnectDelay() -> TimeInterval {
        let delay = initialReconnectDelay * pow(2.0, Double(reconnectAttempts - 1))
        return min(delay, maxReconnectDelay)
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
            self.connect(rideId: params.rideId, userId: params.userId, riderType: params.riderType)
        }
    }
    
    private func handleConnectionFailure() {
        guard !isDisconnecting else {
            print("⚠️ Connection failure ignored - disconnecting")
            return
        }
        
        print("❌ Connection failure detected")
        isConnected = false
        
        // Always attempt to reconnect unless explicitly disconnecting
        if !isDisconnecting {
            reconnect()
        }
    }
    
    private func cleanup() {
        print("🧹 Cleaning up WebSocket resources")
        stopPingPong()
        stopReconnectTimer()
        endBackgroundTask()
        
        if let ws = webSocket {
            ws.cancel(with: .normalClosure, reason: "Disconnecting".data(using: .utf8))
            webSocket = nil
        }
        
        session?.invalidateAndCancel()
        session = nil
        
        isConnected = false
        isReconnecting = false
        
        // Only reset these if explicitly disconnecting
        if isDisconnecting {
            reconnectAttempts = 0
            lastConnectionParams = nil
            onStatusUpdate = nil
            error = nil
            messageQueue.removeAll()
            isProcessingQueue = false
        }
    }
    
    // Add method to update status from API response
    func updateStatusFromApiResponse(status: RideStatus, nextStatus: String?) {
        print("🔄 Updating status from API - Current: \(status.rawValue), Next: \(nextStatus ?? "nil")")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentStatus = status
            
            // Convert string nextStatus to WebSocketEvents if possible
            if let nextStatusStr = nextStatus,
               let nextStatusEvent = WebSocketEvents(rawValue: nextStatusStr) {
                self.nextStatus = nextStatusEvent
            } else {
                // Default to rideStart if no next status is provided
                self.nextStatus = .rideStart
            }
            
            // Notify any listeners of the status update
            self.onStatusUpdate?(self.currentStatus, self.nextStatus, nil)
        }
    }
    
    func connect(rideId: String, userId: String, riderType: RiderType) {
        print("🔵 Attempting to connect WebSocket - RideID: \(rideId), UserID: \(userId), RiderType: \(riderType)")
        
        // Reset state
        isDisconnecting = false
        messageQueue.removeAll()
        isProcessingQueue = false
        
        // Store connection parameters for reconnection
        lastConnectionParams = (rideId: rideId, userId: userId, riderType: riderType)
        
        // Clean up any existing connection
        cleanup()
        
        // First fetch current status from API
        Task {
            do {
                let statusResponse: RideTrack = try await withCheckedThrowingContinuation { continuation in
                    NetworkManager.shared.makeRequest(
                        endpoint: "/match/get/\(rideId)",
                        method: .GET
                    ) { (result: Result<RideTrack, Error>) in
                        continuation.resume(with: result)
                    }
                }
                
                // Update the status
                await MainActor.run {
                    self.updateStatusFromApiResponse(status: statusResponse.status, nextStatus: statusResponse.nextStatus)
                }
                
            } catch {
                print("❌ Failed to fetch initial status: \(error)")
            }
        }

        // Continue with WebSocket connection
        guard var urlComponents = URLComponents(string: wsUrl) else {
            let error = "Failed to create URL components"
            print("❌ \(error)")
            handleError(error)
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "role", value: riderType.rawValue),
            URLQueryItem(name: "rideId", value: rideId),
            URLQueryItem(name: "\(riderType == .giver ? "giverId" : "takerId")", value: userId)
        ]
        
        guard let url = urlComponents.url else {
            let error = "Failed to create final URL"
            print("❌ \(error)")
            handleError(error)
            return
        }
        print("🔵 WebSocket URL: \(url.absoluteString)")
        
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
        
        // Create a new session configuration with proper settings
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300 // 5 minutes
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        
        // Create and store the session
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        
        // Create and store the WebSocket task
        webSocket = session?.webSocketTask(with: request)
        
        // Set up keep-alive interval
        webSocket?.maximumMessageSize = 1024 * 1024 // 1MB
        
        webSocket?.resume()
        print("🔵 WebSocket task created and resumed")
        
        // Start receiving messages
        receiveMessage()
    }
    
    func disconnect() {
        print("🔵 Disconnecting WebSocket")
        isDisconnecting = true
        cleanup()
    }
    
    private func startPingPong() {
        guard isConnected, !isDisconnecting else {
            print("⚠️ Cannot start ping-pong: WebSocket not connected or disconnecting")
            return
        }
        
        print("🔵 Starting ping-pong timer")
        stopPingPong() // Clear any existing timer
        pingPongTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingPong() {
        print("🔵 Stopping ping-pong timer")
        pingPongTimer?.invalidate()
        pingPongTimer = nil
    }
    
    private func sendPing() {
        guard isConnected, !isDisconnecting, let ws = webSocket else {
            print("⚠️ Cannot send PING: WebSocket not connected or disconnecting")
            return
        }
        
        print("📤 Sending PING")
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
    
    private func handleError(_ message: String) {
        print("❌ WebSocket error: \(message)")
        DispatchQueue.main.async { [weak self] in
            self?.error = message
            self?.onError?(message)
        }
    }
    
    func send(message: String, completion: ((Error?) -> Void)? = nil) {
        print("📤 Queuing message: \(message)")
        messageQueue.append((message, completion))
        processMessageQueue()
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
                // Put the message back at the front of the queue if it failed
                if !self.isDisconnecting {
                    self.messageQueue.insert((message, completion), at: 0)
                }
                completion?(error)
            } else {
                print("✅ Message sent successfully")
                completion?(nil)
            }
            
            self.isProcessingQueue = false
            // Process next message if any
            if !self.messageQueue.isEmpty {
                self.processMessageQueue()
            }
        }
    }
    
    // Helper method to send general events (matching Android format)
    func sendGeneralEvent(socketEventType: WebSocketEvents, rideId: String, takerId: String? = nil) {
        let event = WebSocketMessage(socketEventType: socketEventType, rideId: rideId, takerId: takerId)
        sendEvent(event)
    }
    
    func sendEvent(_ event: WebSocketMessageType) {
        print("📤 Preparing event")
        
        // Ensure we're connected before attempting to send
        guard isConnected else {
            print("⚠️ Cannot send event: WebSocket not connected")
            if !isReconnecting {
                // Try to reconnect if we have connection parameters
                if let params = lastConnectionParams {
                    print("🔄 Attempting to reconnect before sending event")
                    connect(rideId: params.rideId, userId: params.userId, riderType: params.riderType)
                }
            }
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(event)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Event JSON: \(jsonString)")
                send(message: jsonString) { [weak self] error in
                    if let error = error {
                        print("❌ Failed to send event - Error: \(error)")
                        // Attempt to reconnect if send fails
                        self?.handleConnectionFailure()
                    } else {
                        print("✅ Successfully sent event")
                    }
                }
            }
        } catch {
            print("❌ Error encoding WebSocket message: \(error)")
        }
    }
    
    private func receiveMessage() {
        guard !isDisconnecting else {
            print("⚠️ Not receiving messages: WebSocket is disconnecting")
            return
        }
        
        webSocket?.receive { [weak self] result in
            guard let self = self, !self.isDisconnecting else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Received text message: \(text)")
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📥 Received data message: \(text)")
                        self.handleMessage(text)
                    }
                @unknown default:
                    print("⚠️ Received unknown message type")
                    break
                }
                
                // Only continue receiving messages if not disconnecting
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
    
    private func handleMessage(_ text: String) {
        print("📥 Processing message: \(text)")
        
        do {
            guard let data = text.data(using: .utf8) else {
                print("❌ Could not convert text to data")
                return
            }
            
            // First try to decode as WebSocketMessage
            if let message = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                print("✅ Successfully decoded WebSocketMessage")
                handleWebSocketMessage(message)
                return
            }
            
            // Handle special messages
            if text.uppercased() == "PONG" {
                print("📍 Received pong")
                return
            }
            if text.uppercased() == "PING" {
                print("📍 Received ping, sending pong")
                sendPong()
                return
            }
            
            // Try to decode as specific event types
            if let event = try? JSONDecoder().decode(WsEventGeneral.self, from: data) {
                print("✅ Successfully decoded WsEventGeneral")
                handleGeneralEvent(event)
                return
            }
            
            if let event = try? JSONDecoder().decode(WsEvent.self, from: data) {
                print("✅ Successfully decoded WsEvent")
                handleLocationEvent(event)
                return
            }
            
            if let event = try? JSONDecoder().decode(RideStartEvent.self, from: data) {
                print("✅ Successfully decoded RideStartEvent")
                handleRideStartEvent(event)
                return
            }
            
            print("❌ Failed to decode message into any known type")
            print("Message content: \(text)")
        } catch {
            print("❌ Error processing message: \(error)")
        }
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        print("📥 Processing WebSocket message: \(message.socketEventType)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch message.socketEventType {
            case .status:
                if let status = message.rideStatus {
                    print("📊 Status update - Current: \(status.rawValue), Next: \(message.nextStatus ?? "nil"), DateTime: \(message.dateTime ?? "nil")")
                    self.currentStatus = status
                    
                    // Convert string nextStatus to WebSocketEvents if possible
                    if let nextStatusStr = message.nextStatus,
                       let nextStatusEvent = WebSocketEvents(rawValue: nextStatusStr) {
                        self.nextStatus = nextStatusEvent
                    }
                    
                    // Handle status-specific actions
                    switch status {
                    case .started:
                        // No dialog needed for started status
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        
                    case .riderArrived:
                        // Notify status update which will trigger showPickupConfirmation in the view
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        
                    case .pickedUp:
                        // Just update status for picked up
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        
                    case .activityOngoing:
                        // Update status for activity ongoing
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        
                    case .returnedActivity:
                        // Update status for returned to activity
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        
                    case .pickedUpFromActivity:
                        // Update status for picked up from activity
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        
                    case .returnedHome:
                        // Notify status update which will trigger showDropOffConfirmation in the view
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        
                    case .completed:
                        // Notify completion and cleanup
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                        self.cleanup() // This will handle WebSocket disconnection
                        
                    default:
                        print("⚠️ Unhandled status: \(status.rawValue)")
                        self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                    }
                }
                
            case .error:
                if let errorCode = message.errorCode {
                    switch errorCode {
                    case 7007:
                        self.nextStatus = .rideStart
                    default:
                        print("⚠️ Unhandled error code: \(errorCode)")
                    }
                    
                    if let errorDesc = message.errorDescription {
                        self.error = errorDesc
                        self.onError?(errorDesc)
                    }
                }
                
            default:
                print("📍 Handling other event type: \(message.socketEventType)")
                // For other event types, still update status if available
                if let status = message.rideStatus {
                    self.currentStatus = status
                    if let nextStatusStr = message.nextStatus,
                       let nextStatusEvent = WebSocketEvents(rawValue: nextStatusStr) {
                        self.nextStatus = nextStatusEvent
                    }
                    self.onStatusUpdate?(status, self.nextStatus, message.dateTime)
                }
            }
        }
    }
    
    private func handleGeneralEvent(_ event: WsEventGeneral) {
        // Handle general events
        print("📍 Handling general event: \(event.socketEventType)")
    }
    
    private func handleLocationEvent(_ event: WsEvent) {
        // Handle location events
        print("📍 Handling location event: \(event.socketEventType)")
    }
    
    private func handleRideStartEvent(_ event: RideStartEvent) {
        // Handle ride start events
        print("📍 Handling ride start event")
    }
    
    private func sendPong() {
        webSocket?.send(.string("PONG")) { error in
            if let error = error {
                print("❌ Error sending pong: \(error)")
            }
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected successfully")
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isDisconnecting else { return }
            self.isConnected = true // This will automatically start ping-pong
            self.reconnectAttempts = 0
            self.isReconnecting = false
            self.error = nil
            
            // Process any queued messages
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isConnected = false // This will automatically stop ping-pong
            
            // Only attempt reconnection for unexpected closures and when not explicitly disconnecting
            if closeCode != .normalClosure && !self.isDisconnecting && !self.isReconnecting {
                self.handleConnectionFailure()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ URLSession error: \(error)")
            DispatchQueue.main.async { [weak self] in
                guard let self = self, !self.isDisconnecting, !self.isReconnecting else { return }
                self.handleConnectionFailure()
            }
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Accept all certificates for development
        #if DEBUG
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }
        #endif
        
        // Default handling for production
        completionHandler(.performDefaultHandling, nil)
    }
} 
