import SwiftUI

extension String {
    func formatDateTime() -> String {
        guard !self.isEmpty else { return "" }
        
        // Create ISO8601 formatter for parsing the input
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let date = isoFormatter.date(from: self) else {
            return self
        }
        
        // Create output formatter with local time zone
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "hh:mm a"
        outputFormatter.amSymbol = "AM"
        outputFormatter.pmSymbol = "PM"
        outputFormatter.timeZone = TimeZone.current // Use local time zone
        
        return outputFormatter.string(from: date)
    }
}


func getAMPM(from isoString: String) -> String? {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    isoFormatter.timeZone = TimeZone(abbreviation: "UTC") // interpret incoming time as UTC
    
    guard let date = isoFormatter.date(from: isoString) else {
        return nil
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    formatter.amSymbol = "AM"
    formatter.pmSymbol = "PM"
    formatter.timeZone = .current // convert to device's local timezone

    return formatter.string(from: date)
}

// MARK: - Ride Stage Row
private struct RideStageRow: View {
    let icon: String
    let title: String
    let location: String?
    let time: String?
    let isActive: Bool
    let isLastItem: Bool
    
    init(icon: String, title: String, location: String? = nil, time: String? = nil, isActive: Bool = false, isLastItem: Bool = false) {
        self.icon = icon
        self.title = title
        self.location = location
        self.time = time
        self.isActive = isActive
        self.isLastItem = isLastItem
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon column with connecting dots
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .foregroundColor(isActive ? Color.primaryButton : .gray)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(.white)
                            .shadow(color: isActive ? Color.primaryButton.opacity(0.3) : .clear, radius: isActive ? 4 : 0)
                    )
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isActive)
                
                if !isLastItem {
                    Rectangle()
                        .fill(isActive ? Color.primaryButton : Color.gray.opacity(0.3))
                        .frame(width: 2, height: 24)
                        .padding(.vertical, 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isActive ? Color.primaryButton : .gray)
                if let location = location {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(isActive ? Color.primaryButton : .gray)
                }
            }
            
            Spacer()
            
            if let time = time {
                if time == "" {
                    Image(systemName: "chevron.right")
                        .foregroundColor(isActive ? Color.primaryButton : .gray)
                        .opacity(0.5)
                } else {
                    Text(getAMPM(from: time) ?? "")
                        .font(.caption)
                        .foregroundColor(Color.primaryButton)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Drop Stages View
private struct DropStagesView: View {
    let viewModel: RideTrackingViewModel
    let pickupAddress: String
    let dropoffAddress: String
    let startTime: String
    let pickupTime: String
    let dropoffTime: String
    
    var body: some View {
        VStack(spacing: 0) {
            RideStageRow(
                icon: "location.circle.fill",
                title: "Start",
                time: startTime,
                isActive: viewModel.startStageActive
            )
            
            RideStageRow(
                icon: "mappin.circle.fill",
                title: "Pick up",
                location: pickupAddress,
                time: pickupTime,
                isActive: viewModel.pickupStageActive
            )
            
            RideStageRow(
                icon: "mappin.and.ellipse",
                title: "Drop Off at Activity",
                location: dropoffAddress,
                time: dropoffTime,
                isActive: viewModel.dropoffStageActive,
                isLastItem: true
            )
        }
    }
}

// MARK: - Pick Stages View
private struct PickStagesView: View {
    let viewModel: RideTrackingViewModel
    let pickupAddress: String
    let dropoffAddress: String
    let returnStartTime: String
    let returnPickupTime: String
    let returnDropoffTime: String
    
    var body: some View {
        VStack(spacing: 0) {
            RideStageRow(
                icon: "location.circle.fill",
                title: "Start from Activity",
                time: returnStartTime,
                isActive: viewModel.returnStartStageActive
            )
            
            RideStageRow(
                icon: "mappin.circle.fill",
                title: "Pick up from Activity",
                location: dropoffAddress,
                time: returnPickupTime,
                isActive: viewModel.returnPickupStageActive
            )
            
            RideStageRow(
                icon: "mappin.and.ellipse",
                title: "Drop Off at Home",
                location: pickupAddress,
                time: returnDropoffTime,
                isActive: viewModel.returnDropoffStageActive,
                isLastItem: true
            )
        }
    }
}

// MARK: - Contact Section View
private struct ContactSectionView: View {
    @Binding var pickupNotes: String
    let onCall: () -> Void
    let onMessage: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            TextField("Any pick-up notes?", text: $pickupNotes)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color(.systemGray4).opacity(0.2), radius: 2, x: 0, y: 1)
                )
                .textFieldStyle(PlainTextFieldStyle())
            
            Button(action: onCall) {
                Image(systemName: "phone.circle")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(Color.primaryButton)
            }
            
            Button(action: onMessage) {
                Image(systemName: "message.circle")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(Color.primaryButton)
            }
        }
        .padding(.horizontal)
    }
}

struct RideTakerTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: RideTrackingViewModel
    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var pickupNotes: String = ""
    @State private var showConfirmationDialog = false
    @State private var confirmationTitle = ""
    @State private var confirmationMessage = ""
    @State private var confirmationAction: (() -> Void)?
    @State private var showFeedbackDialog = false
    @State private var completionMessage = ""
    @State private var showFeedbackSheet = false
    
    // Stage times
    @State private var startTime = ""
    @State private var pickupTime = ""
    @State private var dropoffTime = ""
    @State private var returnStartTime = ""
    @State private var returnPickupTime = ""
    @State private var returnDropoffTime = ""
    
    // Add timer for ping-pong
    @State private var pingTimer: Timer? = nil
    
    // Add state to track if we should force refresh dialogs
    @State private var shouldRefreshDialog = false
    
    let rideId: String
    let childName: String
    let vehicleNumber: String
    let riderImage: UIImage?
    let onCall: () -> Void
    let onMessage: () -> Void
    let isFromOngoing: Bool
    let rideType: RideType
    let date: String
    let pickupAddress: String
    let dropoffAddress: String
    let riderId: String
    
    init(rideId: String, 
         childName: String, 
         vehicleNumber: String, 
         riderImage: UIImage?,
         pickupAddress: String,
         dropoffAddress: String,
         rideType: RideType,
         riderId: String,
         date: String,
         onCall: @escaping () -> Void,
         onMessage: @escaping () -> Void, 
         isFromOngoing: Bool) {
        self.rideId = rideId
        self.childName = childName
        self.vehicleNumber = vehicleNumber
        self.riderImage = riderImage
        self.onCall = onCall
        self.onMessage = onCall
        self.isFromOngoing = isFromOngoing
        self.rideType = rideType
        self.date = date
        self.pickupAddress = pickupAddress
        self.dropoffAddress = dropoffAddress
        self.riderId = riderId
        
        // Initialize view model first
        let viewModel = RideTrackingViewModel(rideId: rideId, isFromOngoing: isFromOngoing)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private func initializeRideData() async {
        print("🔄 RideTaker - Initializing ride data")
        if isFromOngoing {
            await viewModel.getRideData()
        }

        // If we have status history, assign times based on it
        if !viewModel.statusHistory.isEmpty {
            // Handle Drop stages
            if let startedTime = viewModel.statusHistory["STARTED"] {
                stageStarted(startedTime)
            }
            if let pickedUpTime = viewModel.statusHistory["PICKED_UP"] {
                stagePickedFromHome(pickedUpTime)
            }
            if let arrivedAtActivityTime = viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] {
                stageDroppedAtActivity(arrivedAtActivityTime)
            }
            
            // Handle Pick stages
            if let returnedActivityTime = viewModel.statusHistory["RETURNED_ACTIVITY"] {
                stageReturnedAtActivity(returnedActivityTime)
            }
            if let pickedFromActivityTime = viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] {
                stagePickedFromActivity(pickedFromActivityTime)
            }
            if let returnedHomeTime = viewModel.statusHistory["COMPLETED"] {
                stageDroppedAtHome(returnedHomeTime)
            }
            
            // Set active stages based on latest status
            if let latestStatus = viewModel.statusHistory.max(by: { $0.value < $1.value }) {
                switch latestStatus.key {
                case "STARTED":
                    viewModel.startStageActive = true
                case "PICKED_UP":
                    viewModel.startStageActive = true
                    viewModel.pickupStageActive = true
                case "ARRIVED_AT_ACTIVITY":
                    viewModel.startStageActive = true
                    viewModel.pickupStageActive = true
                    viewModel.dropoffStageActive = true
                case "RETURNED_ACTIVITY":
                    viewModel.returnStartStageActive = true
                case "PICKED_UP_FROM_ACTIVITY":
                    viewModel.returnStartStageActive = true
                    viewModel.returnPickupStageActive = true
                case "RETURNED_HOME":
                    viewModel.returnStartStageActive = true
                    viewModel.returnPickupStageActive = true
//                    viewModel.returnDropoffStageActive = true
                default:
                    break
                }
            }
        }

        // If we're not coming from ongoing rides, initialize status
        if !isFromOngoing && viewModel.rideTrack?.status == nil {
            await MainActor.run {
                viewModel.rideTrack?.status = .started
            }
        }
        
        print("📊 RideTaker - Current status: \(String(describing: viewModel.rideTrack?.status))")
    }
    
    private func initializeWebSocket() {
        print("🔌 RideTaker - Initializing WebSocket")
        webSocketManager.onStatusUpdate = handleWebSocketStatus
        
        // Setup ping timer - Note: Ping/Pong is now handled internally by WebSocketManager
        pingTimer?.invalidate()
        pingTimer = nil
        
        if let userId = TokenManager.shared.getDecodedAccessToken()?.userId {
            print("🔌 Connecting WebSocket - RideID: \(rideId), UserID: \(userId)")
            webSocketManager.connect(rideId: rideId, userId: userId, riderType: .taker)
            
            // Get initial status after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                wsGetRideStatus()
            }
        } else {
            print("⚠️ Missing userId for WebSocket connection")
        }
    }
    
    private func cleanup() {
        print("🧹 RideTaker - Cleaning up resources")
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketManager.onStatusUpdate = nil
        webSocketManager.disconnect()
    }
    
    private func wsGetRideStatus() {
        print("🔍 RideTaker - Getting ride status")
        let message = WsEventGeneral(
            socketEventType: .status,
            rideId: rideId,
            takerId: nil
        )
        webSocketManager.sendEvent(message)
    }
    
    private func handleWebSocketStatus(_ status: RideStatus, _ nextStatus: WebSocketEvents, dateTime: String? = nil) {
        print("🎯 RideTaker - Handling status update: \(status) -> \(nextStatus)")
        print("📅 DateTime from WebSocket: \(dateTime ?? "nil")")
        
        Task { @MainActor in
            // Ensure we have ride data before processing status
            if viewModel.rideTrack == nil {
                print("⚠️ RideTaker - No ride data available, fetching...")
                await viewModel.getRideData()
            }
            
            // Update the status immediately to trigger UI refresh
            viewModel.updateRideStatus(status)
            
            // Update status history with WebSocket datetime
            if let dateTime = dateTime {
                print("📅 Updating status history with datetime: \(dateTime)")
                viewModel.statusHistory[status.rawValue] = dateTime
                
                // If this is a pickup status, update the pickup time immediately
                if status == .pickedUp {
                    print("📍 Updating pickup time from status history")
                    pickupTime = dateTime.formatDateTime()
                    print("📍 Updated pickup time to: \(pickupTime)")
                }
            }
            
            // Handle dialog presentation first, before updating stages
            switch status {
            case .riderArrived:
                print("📍 RideTaker - Rider arrived, showing pickup dialog")
                // Show dialog first
                showPickupConfirmation()
                // Then update stages
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stageArrivedAtHome()
                
            case .returnedHome:
                print("🏠 RideTaker - Returned home, showing drop-off dialog")
                // Show dialog first
                showDropOffConfirmation()
                // Then update stages
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageArrivedAtHome()
                stageDroppedAtActivity(viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] ?? "")
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                stagePickedFromActivity(viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] ?? "")
                
            case .completed:
                print("✅ RideTaker - Completed, showing completion dialog")
                // Update all stages first
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stageArrivedAtHome()
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageDroppedAtActivity(viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] ?? "")
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                stagePickedFromActivity(viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] ?? "")
                stageDroppedAtHome(viewModel.statusHistory["RETURNED_HOME"] ?? "")
                // Then show completion dialog
                stageCompleted()
                
            // Handle other statuses without dialogs
            case .started:
                if rideType == .pick {
                    stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                }
                
            case .pickedUp:
                print("📍 RideTaker - Picked up status received")
                // Update stages with the latest status history time
                if let pickupDateTime = viewModel.statusHistory["PICKED_UP"] {
                    print("📍 Using status history time for pickup: \(pickupDateTime)")
                    pickupTime = pickupDateTime.formatDateTime()
                    print("📍 Updated pickup time to: \(pickupTime)")
                }
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stageArrivedAtHome()
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? dateTime ?? "")
                
            case .arrivedAtActivity:
                if rideType == .pick {
                    stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                    stageArrivedAtHome()
                    stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                    stageDroppedAtActivity(viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] ?? "")
                }
                
            case .activityOngoing:
                if rideType == .pick {
                    stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                    stageArrivedAtHome()
                    stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                    stageDroppedAtActivity(viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] ?? "")
                }
                
            case .returnedActivity:
                if rideType == .pick {
                    // No additional UI updates needed
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                    stageArrivedAtHome()
                    stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                    stageDroppedAtActivity(viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] ?? "")
                }
                stageReachedActivity()
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                
            case .pickedUpFromActivity:
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageArrivedAtHome()
                stageDroppedAtActivity(viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] ?? "")
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                stagePickedFromActivity(viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] ?? "")
                
            default:
                print("⚠️ RideTaker - Unknown status: \(status)")
            }
            
            // Handle next status
            switch nextStatus {
            case .rideStart:
                print("🚦 RideTaker - Next: Start ride and notify")
                // Show toast: "Start ride, and notify ride taker."
            default:
                break
            }
        }
    }
    
    private func showPickupConfirmation() {
        print("🔔 RideTaker - Showing pickup confirmation")
        // Reset dialog state
        showConfirmationDialog = false
        confirmationTitle = ""
        confirmationMessage = ""
        confirmationAction = nil
        
        // Force UI update
        shouldRefreshDialog.toggle()
        
        // Set new dialog state after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.confirmationTitle = "Rider Arrived"
            self.confirmationMessage = "The rider has arrived at the pickup location"
            self.confirmationAction = {
                print("✅ RideTaker - Pickup confirmed")
                print("📍 Current pickup time before confirmation: \(self.pickupTime)")
                
                // Get current time in ISO8601 format
                let currentTime = Date().ISO8601Format()
                print("📍 Setting initial pickup time: \(currentTime)")
                
                // Update pickup time immediately for responsive UI
                self.pickupTime = currentTime.formatDateTime()
                print("📍 Updated pickup time to: \(self.pickupTime)")
                
                // Update status history
                self.viewModel.statusHistory["PICKED_UP"] = currentTime
                
                // Send pickup event
                self.webSocketManager.sendGeneralEvent(
                    socketEventType: .pickedUp,
                    rideId: self.rideId,
                    takerId: TokenManager.shared.getDecodedAccessToken()?.userId
                )
                
                // Update stages
                self.stageArrivedAtHome()
                self.stagePickedFromHome(currentTime)
                
                // Update ride data to get the server's timestamp
                Task {
                    await self.viewModel.getRideData()
                    // After getting ride data, update the pickup time with the server's timestamp if available
                    if let serverPickupTime = self.viewModel.statusHistory["PICKED_UP"] {
                        print("📍 Updating pickup time with server timestamp: \(serverPickupTime)")
                        self.pickupTime = serverPickupTime.formatDateTime()
                        print("📍 Final pickup time: \(self.pickupTime)")
                    }
                }
            }
            
            // Show dialog
            self.showConfirmationDialog = true
        }
    }
    
    private func showDropOffConfirmation() {
        print("🔔 RideTaker - Showing drop-off confirmation")
        // Reset dialog state
        showConfirmationDialog = false
        confirmationTitle = ""
        confirmationMessage = ""
        confirmationAction = nil
        
        // Force UI update
        shouldRefreshDialog.toggle()
        
        // Set new dialog state after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.confirmationTitle = "Rider Arrived Home"
            self.confirmationMessage = "The rider has arrived at the drop-off location"
            self.confirmationAction = {
                print("✅ RideTaker - Drop-off confirmed")
                self.webSocketManager.sendGeneralEvent(
                    socketEventType: .rideEnd,
                    rideId: self.rideId,
                    takerId: TokenManager.shared.getDecodedAccessToken()?.userId
                )
                self.stageDroppedAtHome()
                self.stageCompleted()
                Task {
                    await self.viewModel.getRideData()
                }
            }
            
            // Show dialog
            self.showConfirmationDialog = true
        }
    }
    
    private func stageStarted(_ at: String = "") {
        print("🚦 RideTaker - Stage: Started")
        if let track = viewModel.rideTrack {
            let time = {
                if let startTime = viewModel.statusHistory["STARTED"] {
                    print("📍 Using status history time")
                    return startTime
                } else if !track.routeLocations.isEmpty {
                    print("📍 Using first route location time")
                    return track.routeLocations[0].dateTime
                } else if !at.isEmpty {
                    print("📍 Using provided time: \(at)")
                    return at
                } else {
                    print("📍 Using current time")
                    return Date().ISO8601Format()
                }
            }()
            
            // Update UI state
            viewModel.startStageActive = true
            startTime = time
        }
    }
    
    private func stageArrivedAtHome() {
        print("🏠 RideTaker - Stage: Arrived at home")
//        viewModel.pickupStageActive = true
    }
    
    private func stagePickedFromHome(_ at: String = "") {
        print("👋 RideTaker - Stage: Picked from home")
        print("📍 Input time for pickup: \(at)")
        if let track = viewModel.rideTrack {
            let time = {
                if let pickupTime = viewModel.statusHistory["PICKED_UP"] {
                    print("📍 Using status history time: \(pickupTime)")
                    return pickupTime
                } else if !track.pickupLocations.isEmpty {
                    print("📍 Using first pickup location time: \(track.pickupLocations[0].dateTime)")
                    return track.pickupLocations[0].dateTime
                } else if !at.isEmpty {
                    print("📍 Using provided time: \(at)")
                    return at
                } else {
                    print("📍 Using current time")
                    return Date().ISO8601Format()
                }
            }()
            
            // Update UI state
            print("📍 Setting pickup time to: \(time)")
            pickupTime = time.formatDateTime()
            print("📍 Formatted pickup time: \(pickupTime)")
            viewModel.pickupStageActive = true
        }
    }
    
    private func stageDroppedAtActivity(_ at: String = "") {
        print("🎯 RideTaker - Stage: Dropped at activity")
        if let track = viewModel.rideTrack {
            let time = {
                if let dropoffTime = viewModel.statusHistory["ARRIVED_AT_ACTIVITY"] {
                    print("📍 Using status history time")
                    return dropoffTime
                }
                if let dropoffTime = viewModel.statusHistory["ACTIVITY_ONGOING"] {
                    print("📍 Using status history time")
                    return dropoffTime
                }
                else if !track.routeLocations.isEmpty {
                    print("📍 Using last route location time")
                    return track.routeLocations.last?.dateTime ?? Date().ISO8601Format()
                } else if !at.isEmpty {
                    print("📍 Using provided time: \(at)")
                    return at
                } else {
                    print("📍 Using current time")
                    return Date().ISO8601Format()
                }
            }()
            
            // Update UI state
            viewModel.dropoffStageActive = true
            dropoffTime = time.formatDateTime()
        }
    }
    
    private func stageReachedActivity() {
        print("🎯 RideTaker - Stage: Reached activity")
        viewModel.returnStartStageActive = true
    }
    
    private func stageReturnedAtActivity(_ at: String = "") {
        print("↩️ RideTaker - Stage: Returned at activity")
        if let track = viewModel.rideTrack {
            let time = {
                if let returnTime = viewModel.statusHistory["RETURNED_ACTIVITY"] {
                    print("📍 Using status history time")
                    return returnTime
                } else if !track.routeLocations.isEmpty {
                    print("📍 Using first route location time")
                    return track.routeLocations[0].dateTime
                } else if !at.isEmpty {
                    print("📍 Using provided time: \(at)")
                    return at
                } else {
                    print("📍 Using current time")
                    return Date().ISO8601Format()
                }
            }()
            
            // Update UI state
            viewModel.returnStartStageActive = true
            returnStartTime = time.formatDateTime()
        }
    }
    
    private func stagePickedFromActivity(_ at: String = "") {
        print("👋 RideTaker - Stage: Picked from activity")
        if let track = viewModel.rideTrack {
            let time = {
                if let pickupTime = viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] {
                    print("📍 Using status history time")
                    return pickupTime
                } else if !track.routeLocations.isEmpty {
                    print("📍 Using first route location time")
                    return track.routeLocations[0].dateTime
                } else if !at.isEmpty {
                    print("📍 Using provided time: \(at)")
                    return at
                } else {
                    print("📍 Using current time")
                    return Date().ISO8601Format()
                }
            }()
            
            // Update UI state
            viewModel.returnPickupStageActive = true
            returnPickupTime = time.formatDateTime()
        }
    }
    
    private func stageDroppedAtHome(_ at: String = "") {
        print("🏠 RideTaker - Stage: Dropped at home")
        if let track = viewModel.rideTrack {
            let time = {
                if let dropoffTime = viewModel.statusHistory["RETURNED_HOME"] {
                    print("📍 Using status history time")
                    return dropoffTime
                } else if !track.routeLocations.isEmpty {
                    print("📍 Using last route location time")
                    return track.routeLocations.last?.dateTime ?? Date().ISO8601Format()
                } else if !at.isEmpty {
                    print("📍 Using provided time: \(at)")
                    return at
                } else {
                    print("📍 Using current time")
                    return Date().ISO8601Format()
                }
            }()
            
            // Update UI state
            viewModel.returnDropoffStageActive = true
            returnDropoffTime = time.formatDateTime()
        }
    }
    
    private func stageCompleted() {
        print("✅ RideTaker - Stage: Completed")
        webSocketManager.disconnect()
        
        // Reset feedback dialog state
        showFeedbackDialog = false
        completionMessage = ""
        
        // Force UI update
        shouldRefreshDialog.toggle()
        
        // Set new dialog state after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Get start and end times based on ride type
            let (startTimeStr, endTimeStr, startLabel, endLabel) = {
                let start = self.viewModel.statusHistory["STARTED"] ?? ""
                let end = self.viewModel.statusHistory["COMPLETED"] ?? self.viewModel.statusHistory["RETURNED_HOME"] ?? ""
                return (start, end, "", "")
            }()
            
            // Format the times and handle missing information
            let formattedStart = startTimeStr.isEmpty ? "Not available" : (getAMPM(from: startTimeStr) ?? "Unknown")
            let formattedEnd = endTimeStr.isEmpty ? "Not available" : (getAMPM(from: endTimeStr) ?? "Unknown")
            
            if startTimeStr.isEmpty && endTimeStr.isEmpty {
                print("⚠️ Both start and end times are missing")
                self.completionMessage = "Ride completed (times not available)"
            } else if startTimeStr.isEmpty {
                print("⚠️ Start time is missing")
                self.completionMessage = "\(startLabel): Not available -- \(endLabel): \(formattedEnd)"
            } else if endTimeStr.isEmpty {
                print("⚠️ End time is missing")
                self.completionMessage = "\(startLabel): \(formattedStart) -- \(endLabel): Not available"
            } else {
                print("🕒 Ride duration: \(formattedStart) -- \(formattedEnd)")
                self.completionMessage = "\(formattedStart) -- \(formattedEnd)"
            }
            
            // Show feedback dialog
            self.showFeedbackDialog = true
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Ride stages based on type
                        VStack(spacing: 0) {
                            if rideType == .drop || rideType == .dropPick {
                                DropStagesView(
                                    viewModel: viewModel,
                                    pickupAddress: pickupAddress,
                                    dropoffAddress: dropoffAddress,
                                    startTime: startTime,
                                    pickupTime: pickupTime,
                                    dropoffTime: dropoffTime
                                )
                            }
                            
                            if rideType == .pick || rideType == .dropPick {
                                PickStagesView(
                                    viewModel: viewModel,
                                    pickupAddress: pickupAddress,
                                    dropoffAddress: dropoffAddress,
                                    returnStartTime: returnStartTime,
                                    returnPickupTime: returnPickupTime,
                                    returnDropoffTime: returnDropoffTime
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Rider info row
                        HStack {
                            if let riderImage = riderImage {
                                Image(uiImage: riderImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                            } else {
                                Image("check")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(childName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                            
                            Spacer()
                            
                            Text(vehicleNumber)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Contact section
                        ContactSectionView(
                            pickupNotes: $pickupNotes,
                            onCall: onCall,
                            onMessage: onCall
                        )
                    }
                    .padding(.vertical)
                }
            }
        }
        .withCustomBackButton(showBackButton: true)
        .alert(viewModel.error ?? "Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.error = nil
            }
        }
        .alert(webSocketManager.error ?? "Error", isPresented: .constant(webSocketManager.error != nil)) {
            Button("OK", role: .cancel) {
                webSocketManager.error = nil
            }
        }
        .alert(confirmationTitle, isPresented: $showConfirmationDialog) {
            Button(action: {
                confirmationAction?()
            }) {
                Text("Confirm")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(confirmationMessage)
        }
        .alert("Ride Completed", isPresented: $showFeedbackDialog) {
            Button("OK") {
                dismiss()
            }
            Button("Give Feedback") {
                showFeedbackSheet = true
            }
        } message: {
            Text(completionMessage)
        }
        .sheet(isPresented: $showFeedbackSheet, onDismiss: {
            dismiss()
        }) {
            if let userId = TokenManager.shared.getDecodedAccessToken()?.userId {
                FeedbackView(
                    rideId: rideId,
                    fromUserId: userId,
                    forUserId: riderId,
                    forUserName: childName,
                    riderType: .taker,
                    date: date
                )
            }
        }
        .onDisappear {
            print("👋 RideTaker view disappeared")
            cleanup()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            print("📱 RideTaker - App entering background")
            cleanup()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("📱 RideTaker - App becoming active")
            initializeWebSocket()
        }
        .onChange(of: shouldRefreshDialog) { _ in
            // This empty onChange forces SwiftUI to refresh the view
            // when dialog states are reset
        }
        .task {
            print("👀 RideTaker view appeared")
            // Initialize ride data first
            await initializeRideData()
            
            // Then setup WebSocket
            initializeWebSocket()
        }
    }
}

// MARK: - Status Action Button
private struct StatusActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primaryButton)
                )
        }
        .padding(.horizontal)
    }
}

#Preview {
    Group {
        RideTakerTrackingView(
            rideId: "123",
            childName: "Akshaya",
            vehicleNumber: "5:00 - 6:00",
            riderImage: UIImage(named: "check"),
            pickupAddress: "123 Home Street",
            dropoffAddress: "456 School Ave",
            rideType: .dropPick,
            riderId: "user123",
            date: "",
            onCall: {},
            onMessage: {},
            isFromOngoing: false
        )
        .previewDisplayName("Light Mode")
        
        RideTakerTrackingView(
            rideId: "123",
            childName: "Akshaya",
            vehicleNumber: "5:00 - 6:00",
            riderImage: UIImage(named: "check"),
            pickupAddress: "123 Home Street",
            dropoffAddress: "456 School Ave",
            rideType: .dropPick,
            riderId: "user123",
            date: "",
            onCall: {},
            onMessage: {},
            isFromOngoing: false
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
} 
