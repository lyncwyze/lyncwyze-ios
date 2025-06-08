import SwiftUI

// MARK: - Location Row View
private struct LocationRowView: View {
    let icon: String
    let title: String
    let address: String?
    let isActive: Bool
    let time: String?
    let isLastItem: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(icon: String, title: String, address: String? = nil, isActive: Bool = false, time: String? = nil, isLastItem: Bool = false) {
        self.icon = icon
        self.title = title
        self.address = address
        self.isActive = isActive
        self.time = time
        self.isLastItem = isLastItem
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon column with connecting dots
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .foregroundColor(isActive ? Color.primaryButton : .secondary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: isActive ? Color.primaryButton.opacity(0.3) : .clear, radius: isActive ? 4 : 0)
                    )
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isActive)
                
                if !isLastItem {
                    Rectangle()
                        .fill(isActive ? Color.primaryButton : Color(.systemGray3))
                        .frame(width: 2, height: 24)
                        .padding(.vertical, 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isActive ? Color.primaryButton : .secondary)
                if let address = address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(isActive ? Color.primaryButton : .secondary)
                }
            }
            
            Spacer()
            
            if let time = time {
                if time == "" {
                    Image(systemName: "chevron.right")
                        .foregroundColor(isActive ? Color.primaryButton : .secondary)
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
    let startStageActive: Bool
    let pickupStageActive: Bool
    let dropoffStageActive: Bool
    let startTime: String
    let pickupTime: String
    let dropoffTime: String
    
    var body: some View {
        VStack(spacing: 0) {
            LocationRowView(
                icon: "location.circle.fill",
                title: "Start",
                isActive: startStageActive,
                time: startTime
            )
            
            LocationRowView(
                icon: "mappin.circle.fill",
                title: "Pick up",
                address: pickupAddress,
                isActive: pickupStageActive,
                time: pickupTime
            )
            
            LocationRowView(
                icon: "mappin.and.ellipse",
                title: "Drop Off at Activity",
                address: dropoffAddress,
                isActive: dropoffStageActive,
                time: dropoffTime,
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
    let returnStartStageActive: Bool
    let returnPickupStageActive: Bool
    let returnDropoffStageActive: Bool
    let returnStartTime: String
    let returnPickupTime: String
    let returnDropoffTime: String
    
    var body: some View {
        VStack(spacing: 0) {
            LocationRowView(
                icon: "location.circle.fill",
                title: "Start from Activity",
                isActive: returnStartStageActive,
                time: returnStartTime
            )
            
            LocationRowView(
                icon: "mappin.circle.fill",
                title: "Pick up from Activity",
                address: dropoffAddress,
                isActive: returnPickupStageActive,
                time: returnPickupTime
            )
            
            LocationRowView(
                icon: "mappin.and.ellipse",
                title: "Drop Off at Home",
                address: pickupAddress,
                isActive: returnDropoffStageActive,
                time: returnDropoffTime,
                isLastItem: true
            )
        }
    }
}

// MARK: - Contact Section View
private struct ContactSectionView: View {
    @Binding var pickupNotes: String
    @State private var textFieldElevation: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    let onCall: () -> Void
    let onMessage: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            TextField("Any pick-up notes?", text: $pickupNotes)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color(.systemGray4).opacity(textFieldElevation > 0 ? 0.2 : 0.1), radius: textFieldElevation, x: 0, y: textFieldElevation)
                )
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    textFieldElevation = 2
                }
                .onSubmit {
                    textFieldElevation = 0
                }
            
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

// MARK: - Main Content View
private struct MainContentView: View {
    let viewModel: RideTrackingViewModel
    let webSocketManager: RideGiverWebSocketManager
    let rideType: RideType
    let pickupAddress: String
    let dropoffAddress: String
    @Binding var pickupNotes: String
    let startStageActive: Bool
    let pickupStageActive: Bool
    let dropoffStageActive: Bool
    let returnStartStageActive: Bool
    let returnPickupStageActive: Bool
    let returnDropoffStageActive: Bool
    let startTime: String
    let pickupTime: String
    let dropoffTime: String
    let returnStartTime: String
    let returnPickupTime: String
    let returnDropoffTime: String
    let riderName: String
    let caption: String
    let riderImage: UIImage?
    let notifyNextStage: () -> Void
    let handleCall: () -> Void
    let handleMessage: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location details
                LocationDetailsView(
                    viewModel: viewModel,
                    rideType: rideType,
                    pickupAddress: pickupAddress,
                    dropoffAddress: dropoffAddress,
                    startStageActive: startStageActive,
                    pickupStageActive: pickupStageActive,
                    dropoffStageActive: dropoffStageActive,
                    returnStartStageActive: returnStartStageActive,
                    returnPickupStageActive: returnPickupStageActive,
                    returnDropoffStageActive: returnDropoffStageActive,
                    startTime: startTime,
                    pickupTime: pickupTime,
                    dropoffTime: dropoffTime,
                    returnStartTime: returnStartTime,
                    returnPickupTime: returnPickupTime,
                    returnDropoffTime: returnDropoffTime
                )
                
                // Action Button
                ActionButtonView(
                    buttonTitle: webSocketManager.buttonTitle,
                    action: notifyNextStage
                )
                
                // Rider info row
                RiderInfoView(
                    riderName: riderName,
                    caption: caption,
                    riderImage: riderImage
                )
                
                // Contact section
                ContactSectionView(
                    pickupNotes: $pickupNotes,
                    onCall: handleCall,
                    onMessage: handleMessage
                )
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Location Details View
private struct LocationDetailsView: View {
    let viewModel: RideTrackingViewModel
    let rideType: RideType
    let pickupAddress: String
    let dropoffAddress: String
    let startStageActive: Bool
    let pickupStageActive: Bool
    let dropoffStageActive: Bool
    let returnStartStageActive: Bool
    let returnPickupStageActive: Bool
    let returnDropoffStageActive: Bool
    let startTime: String
    let pickupTime: String
    let dropoffTime: String
    let returnStartTime: String
    let returnPickupTime: String
    let returnDropoffTime: String
    
    var body: some View {
        VStack(spacing: 0) {
            if rideType == .drop || rideType == .dropPick {
                DropStagesView(
                    viewModel: viewModel,
                    pickupAddress: pickupAddress,
                    dropoffAddress: dropoffAddress,
                    startStageActive: startStageActive,
                    pickupStageActive: pickupStageActive,
                    dropoffStageActive: dropoffStageActive,
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
                    returnStartStageActive: returnStartStageActive,
                    returnPickupStageActive: returnPickupStageActive,
                    returnDropoffStageActive: returnDropoffStageActive,
                    returnStartTime: returnStartTime,
                    returnPickupTime: returnPickupTime,
                    returnDropoffTime: returnDropoffTime
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Action Button View
private struct ActionButtonView: View {
    let buttonTitle: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                if buttonTitle.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                } else {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Text(buttonTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorScheme == .dark ? .white : .black, lineWidth: 1)
                    )
            )
        }
        .padding()
    }
}
                    
// MARK: - Rider Info View
private struct RiderInfoView: View {
    let riderName: String
    let caption: String
    let riderImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme
                    
    var body: some View {
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
            
            Text(riderName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
            
            Spacer()
            
            Text(caption)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

struct RideGiverTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: RideTrackingViewModel
    @StateObject private var webSocketManager = RideGiverWebSocketManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var pickupNotes: String = ""
    @State private var showCompletionDialog = false
    @State private var completionMessage = ""
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Stage active states
    @State private var startStageActive = false
    @State private var pickupStageActive = false
    @State private var dropoffStageActive = false
    @State private var returnStartStageActive = false
    @State private var returnPickupStageActive = false
    @State private var returnDropoffStageActive = false
    
    // Stage times
    @State private var startTime = ""
    @State private var pickupTime = ""
    @State private var dropoffTime = ""
    @State private var returnStartTime = ""
    @State private var returnPickupTime = ""
    @State private var returnDropoffTime = ""
    
    let rideId: String
    let riderName: String
    let takerId: String
    let caption: String
    let pickupAddress: String
    let dropoffAddress: String
    let dropoffLatitude: Double
    let dropoffLongitude: Double
    let date: String
    let onCall: () -> Void
    let onMessage: () -> Void
    let onStartRide: () -> Void
    let isFromOngoing: Bool
    let rideType: RideType
    let riderImage: UIImage?
    
    @State private var showStartDialog = false
    @State private var showPickupDialog = false
    @State private var showDropoffDialog = false
    @State private var showFeedbackSheet = false
    
    init(rideId: String, 
         riderName: String, 
         takerId: String,
         caption: String,
         pickupAddress: String,
         dropoffAddress: String,
         dropoffLatitude: Double, dropoffLongitude: Double,
         riderImage: UIImage?,
         date: String,
         onCall: @escaping () -> Void,
         onMessage: @escaping () -> Void, 
         onStartRide: @escaping () -> Void,
         isFromOngoing: Bool, 
         rideType: RideType) {
        self.rideId = rideId
        self.riderName = riderName
        self.takerId = takerId
        self.caption = caption
        self.pickupAddress = pickupAddress
        self.dropoffAddress = dropoffAddress
        self.dropoffLatitude = dropoffLatitude
        self.dropoffLongitude = dropoffLongitude
        self.riderImage = riderImage
        self.date = date
        self.onCall = onCall
        self.onMessage = onMessage
        self.onStartRide = onStartRide
        self.isFromOngoing = isFromOngoing
        self.rideType = rideType
        _viewModel = StateObject(wrappedValue: RideTrackingViewModel(rideId: rideId, isFromOngoing: isFromOngoing))
    }
    
    private func handleWebSocketStatus(_ status: RideStatus, _ nextStatus: WebSocketEvents, dateTime: String? = nil) {
        print("🎯 RideGiver - Handling status update: \(status) -> \(nextStatus)")
        Task { @MainActor in
            // Ensure we have ride data before processing status
            if viewModel.rideTrack == nil {
                print("⚠️ RideGiver - No ride data available, fetching...")
                await viewModel.getRideData()
            }
            
            // Update the status immediately to trigger UI refresh
            viewModel.updateRideStatus(status)
            
            // Update status history with WebSocket datetime
            if let dateTime = dateTime {
                print("📅 Updating status history with datetime: \(dateTime)")
                // Only update if we don't already have a time for this status
                if viewModel.statusHistory[status.rawValue] == nil {
                    viewModel.statusHistory[status.rawValue] = dateTime
                }
            }
            
            // Update UI based on current status
            switch status {
            case .started:
                print("🚗 RideGiver - Ride started")
                if rideType == .pick {
                    stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                }
                
            case .riderArrived:
                print("📍 RideGiver - Rider arrived")
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stageArrivedAtHome()
                
            case .pickedUp:
                print("👋 RideGiver - Picked up")
                if rideType == .pick {
                    stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                    stagePickedFromActivity(viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] ?? "")
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                    stageArrivedAtHome()
                    stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                }
                
            case .arrivedAtActivity:
                print("🎯 RideGiver - Arrived at activity")
                if rideType == .pick {
                    stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                    stageArrivedAtHome()
                    stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                    stageDroppedAtActivity(viewModel.statusHistory["ACTIVITY_ONGOING"] ?? "")
                }
                
            case .activityOngoing:
                print("🎯 RideGiver - Activity ongoing")
                if rideType == .pick {
                    stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                } else {
                    stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                    stageArrivedAtHome()
                    stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                    stageDroppedAtActivity(viewModel.statusHistory["ACTIVITY_ONGOING"] ?? "")
                }
                
            case .returnedActivity:
                print("↩️ RideGiver - Returned to activity")
                // if rideType == .pick {
                //     stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                // } else {
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stageArrivedAtHome()
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageDroppedAtActivity(viewModel.statusHistory["ACTIVITY_ONGOING"] ?? "")
                // }
                stageReachedActivity()
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                
            case .pickedUpFromActivity:
                print("👋 RideGiver - Picked up from activity")
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageArrivedAtHome()
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageDroppedAtActivity(viewModel.statusHistory["ACTIVITY_ONGOING"] ?? "")
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                stagePickedFromActivity(viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] ?? "")
                
            case .returnedHome:
                print("🏠 RideGiver - Returned home")
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageArrivedAtHome()
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageDroppedAtActivity(viewModel.statusHistory["ACTIVITY_ONGOING"] ?? "")
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                stagePickedFromActivity(viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] ?? "")
                stageReachedHome()
                
            case .completed:
                print("✅ RideGiver - Completed")
                stageStarted(viewModel.statusHistory["STARTED"] ?? "")
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageArrivedAtHome()
                stagePickedFromHome(viewModel.statusHistory["PICKED_UP"] ?? "")
                stageDroppedAtActivity(viewModel.statusHistory["ACTIVITY_ONGOING"] ?? "")
                stageReturnedAtActivity(viewModel.statusHistory["RETURNED_ACTIVITY"] ?? "")
                stagePickedFromActivity(viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] ?? "")
                stageReachedHome()
                stageDroppedAtHome(viewModel.statusHistory["RETURNED_HOME"] ?? "")
                stageCompleted()
                return
                
            default:
                print("⚠️ RideGiver - Unknown status: \(status)")
            }
        }
    }
    
    private func notifyNextStage() {
        print("🔔 RideGiver - Notifying next stage")
        guard let coordinates = locationManager.currentLocation?.coordinate else {
            print("❌ Current location not available")
            return
        }
        
        switch webSocketManager.nextStatus {
        case .rideStart:
            print("🚦 RideGiver - Sending ride start event")
            let message = RideStartEvent(
                socketEventType: .rideStart,
                rideId: rideId,
                startLatitude: coordinates.latitude,
                startLongitude: coordinates.longitude,
                endLatitude: dropoffLatitude,
                endLongitude: dropoffLongitude
            )
            webSocketManager.sendEvent(message)
            
            // Reset all stage states
            startStageActive = false
            pickupStageActive = false
            dropoffStageActive = false
            returnStartStageActive = false
            returnPickupStageActive = false
            returnDropoffStageActive = false
            
            // Reset times
            startTime = ""
            pickupTime = ""
            dropoffTime = ""
            returnStartTime = ""
            returnPickupTime = ""
            returnDropoffTime = ""
            
            // Update stages based on ride type
            if rideType == .pick {
                stageReturnedAtActivity()
            } else {
                stageStarted()
            }
            
            // Fetch fresh ride data and reconnect websocket
            Task {
                // Get fresh ride data
                await viewModel.getRideData()
                
                // Reconnect websocket to ensure fresh connection
                webSocketManager.disconnect()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                connectWebSocket()
            }
            
        case .riderArrived:
            print("📍 RideGiver - Sending rider arrived event")
            let message = WsEvent(
                socketEventType: .riderArrived,
                takerId: takerId,
                rideId: rideId,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            webSocketManager.sendEvent(message)
            stageStarted()
            stageArrivedAtHome()
            
            // Show toast message
            toastMessage = "Parent notified: Ride has arrived"
            showToast = true
            
            // Hide toast after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showToast = false
            }
            
        case .pickedUp:
            print("👋 RideGiver - Sending picked up event")
                let message = WsEvent(
                   socketEventType: .riderArrived,
                   takerId: takerId,
                   rideId: rideId,
                   latitude: coordinates.latitude,
                   longitude: coordinates.longitude
               )
               webSocketManager.sendEvent(message)

         
            if rideType == .pick {
                stageReturnedAtActivity()
                stagePickedFromActivity()
            } else {
                stageStarted()
                stageArrivedAtHome()
//                stagePickedFromHome()
            }
            
        case .arrivedAtActivity:
            print("🎯 RideGiver - Sending arrived at activity event")
            let message = WsEvent(
                socketEventType: .arrivedAtActivity,
                takerId: takerId,
                rideId: rideId,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            webSocketManager.sendEvent(message)
            stageStarted()
            stageArrivedAtHome()
            stagePickedFromHome()
            stageDroppedAtActivity()
            
        case .returnedActivity:
            print("↩️ RideGiver - Sending returned to activity event")
            let message = WsEvent(
                socketEventType: .returnedActivity,
                takerId: takerId,
                rideId: rideId,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            webSocketManager.sendEvent(message)
            stageStarted()
            stageArrivedAtHome()
            stagePickedFromHome()
            stageDroppedAtActivity()
            stageReachedActivity()
            stageReturnedAtActivity()
            
        case .pickedUpFromActivity:
            print("👋 RideGiver - Sending picked up from activity event")
            let message = WsEvent(
                socketEventType: .pickedUpFromActivity,
                takerId: takerId,
                rideId: rideId,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            webSocketManager.sendEvent(message)
            stageStarted()
            stageArrivedAtHome()
            stagePickedFromHome()
            stageDroppedAtActivity()
            stageReturnedAtActivity()
            stagePickedFromActivity()
            
        case .returnedHome:
            print("🏠 RideGiver - Sending returned home event")
            let message = WsEvent(
                socketEventType: .returnedHome,
                takerId: takerId,
                rideId: rideId,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            webSocketManager.sendEvent(message)
            stageStarted()
            stagePickedFromHome()
            stageArrivedAtHome()
            stageDroppedAtActivity()
            stageReturnedAtActivity()
            stagePickedFromActivity()
            stageReachedHome()
            
            // Show toast message
            toastMessage = "Parent notified: Child reached home"
            showToast = true
            
            // Hide toast after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showToast = false
            }
            
        case .completed:
            print("✅ RideGiver - Completed")
            stageStarted()
            stagePickedFromHome()
            stageArrivedAtHome()
            stageDroppedAtActivity()
            stageReturnedAtActivity()
            stagePickedFromActivity()
            stageReachedHome()
            stageDroppedAtHome()
        default:
            print("⚠️ RideGiver - Unknown stage: \(webSocketManager.nextStatus)")
        }
        
        // Update the WebSocket status immediately after sending the event
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait for 1 second
            webSocketManager.fetchCurrentRideStatus(rideId: rideId)
        }
    }
    
    private func stageStarted(_ at: String = "") {
        print("🚦 RideGiver - Stage: Started")
        startStageActive = true
        
        let time = {
            if let startTime = viewModel.statusHistory["STARTED"] {
                print("📍 Using status history time")
                return startTime
            } else {
                return ""
            }
        }()
        startTime = time
    }
    
    private func stageArrivedAtHome() {
        print("🏠 RideGiver - Stage: Arrived at home")
    }
    
    private func stagePickedFromHome(_ at: String = "") {
        print("👋 RideGiver - Stage: Picked from home")
        pickupStageActive = true
        
        let time = {
            if let pickupTime = viewModel.statusHistory["PICKED_UP"] {
                print("📍 Using status history time")
                return pickupTime
            }else {
                return ""
            }
        }()
        pickupTime = time
    }
    
    private func stageDroppedAtActivity(_ at: String = "") {
        print("🎯 RideGiver - Stage: Dropped at activity")
        dropoffStageActive = true
        
        let time = {
            if let dropoffTime = viewModel.statusHistory["ACTIVITY_ONGOING"] {
                print("📍 Using status history time")
                return dropoffTime
            }  else {
                return ""
            }
        }()
        dropoffTime = time
    }
    
    private func stageReachedActivity() {
        print("🎯 RideGiver - Stage: Reached activity")
        returnStartStageActive = true
    }
    
    private func stageReturnedAtActivity(_ at: String = "") {
        print("↩️ RideGiver - Stage: Returned at activity")
        returnStartStageActive = true
        
        let time = {
            if let returnTime = viewModel.statusHistory["RETURNED_ACTIVITY"] {
                print("📍 Using status history time")
                return returnTime
            }  else {
                return ""
            }
        }()
        returnStartTime = time
    }
    
    private func stagePickedFromActivity(_ at: String = "") {
        print("👋 RideGiver - Stage: Picked from activity")
        returnPickupStageActive = true
        
        let time = {
            if let pickupTime = viewModel.statusHistory["PICKED_UP_FROM_ACTIVITY"] {
                print("📍 Using status history time")
                return pickupTime
            } else {
                return ""
            }
        }()
        returnPickupTime = time
    }
    
    private func stageReachedHome() {
        print("🏠 RideGiver - Stage: Reached home")
    }
    
    private func stageDroppedAtHome(_ at: String = "") {
        print("🏠 RideGiver - Stage: Dropped at home")
        returnDropoffStageActive = true
        
        let time = {
            if let dropoffTime = viewModel.statusHistory["RETURNED_HOME"] {
                print("📍 Using status history time")
                return dropoffTime
            } else {
                return ""
            }
        }()
        returnDropoffTime = time
    }
    
    private func stageCompleted() {
        print("✅ RideGiver - Stage: Completed")
        returnDropoffStageActive = true

        let startTime = self.viewModel.statusHistory["STARTED"] ?? ""
        let endTime = self.viewModel.statusHistory["COMPLETED"] ?? ""
        let duration = "\(getAMPM(from: startTime) ?? "") -- \(getAMPM(from: endTime) ?? "")"
        
        showCompletionDialog = true
        completionMessage = duration
        webSocketManager.buttonTitle = "Ride Completed"
        
        webSocketManager.disconnect()
    }
    
    private func handleCall() {
        if let phoneNumber = viewModel.rideTrack?.pickupLocations.first?.takerId {
            let tel = "tel:\(phoneNumber)"
            if let url = URL(string: tel), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func handleMessage() {
        if let phoneNumber = viewModel.rideTrack?.pickupLocations.first?.takerId {
            let sms = "sms:\(phoneNumber)&body=\(pickupNotes)"
            if let url = URL(string: sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                MainContentView(
                    viewModel: viewModel,
                    webSocketManager: webSocketManager,
                    rideType: rideType,
                    pickupAddress: pickupAddress,
                    dropoffAddress: dropoffAddress,
                    pickupNotes: $pickupNotes,
                    startStageActive: startStageActive,
                    pickupStageActive: pickupStageActive,
                    dropoffStageActive: dropoffStageActive,
                    returnStartStageActive: returnStartStageActive,
                    returnPickupStageActive: returnPickupStageActive,
                    returnDropoffStageActive: returnDropoffStageActive,
                    startTime: startTime,
                    pickupTime: pickupTime,
                    dropoffTime: dropoffTime,
                    returnStartTime: returnStartTime,
                    returnPickupTime: returnPickupTime,
                    returnDropoffTime: returnDropoffTime,
                    riderName: riderName,
                    caption: caption,
                    riderImage: riderImage,
                    notifyNextStage: notifyNextStage,
                    handleCall: handleCall,
                    handleMessage: handleMessage
                )
            }
            
            // Enhanced Toast Message
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage, isError: false)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showToast)
            }
        }
        .alert(webSocketManager.error ?? "Error", isPresented: .constant(webSocketManager.error != nil)) {
            Button("OK", role: .cancel) {
                webSocketManager.error = nil
            }
        }
        .alert("Ride Completed", isPresented: $showCompletionDialog) {
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
                    forUserId: takerId,
                    forUserName: riderName,
                    riderType: .giver,
                    date: date
                )
            }
        }
        .onDisappear {
            print("👋 RideGiver view disappeared")
            webSocketManager.disconnect()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            print("📱 RideGiver - App entering background")
            webSocketManager.disconnect()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("📱 RideGiver - App becoming active")
            connectWebSocket()
        }
        .task {
            print("👀 RideGiver view appeared")
            
            // Reset button title to initial state
            if isFromOngoing{
                webSocketManager.buttonTitle = ""
            } else {
                webSocketManager.buttonTitle = "Start Ride"
                webSocketManager.currentStatus = .scheduled
                webSocketManager.nextStatus = .rideStart
            }
            
            if isFromOngoing {
                print("📱 RideGiver - Loading ongoing ride data")
                await viewModel.getRideData()
                
                if let rideTrack = viewModel.rideTrack {
                    print("🔄 RideGiver - Current status: \(rideTrack.status)")
                    
                    // Update WebSocket manager with current and next status
                    webSocketManager.currentStatus = rideTrack.status
                    
                    // Handle initial status
                    if rideTrack.status == .scheduled {
                        print("🎯 RideGiver - Ride is scheduled, setting up for start")
                        webSocketManager.buttonTitle = "Start Ride"
                        webSocketManager.nextStatus = .rideStart
                        return // Don't setup WebSocket for scheduled rides
                    }
                    
                    // Update UI based on current status
                    updateRideStatusUI(rideTrack.status)
                }
            }
            
            // Setup WebSocket
            connectWebSocket()
        }
        .withCustomBackButton(showBackButton: true)
    }
    
    private func connectWebSocket() {
        print("🔌 RideGiver - Connecting WebSocket")
        webSocketManager.onStatusUpdate = handleWebSocketStatus
        if let userId = TokenManager.shared.getDecodedAccessToken()?.userId {
            print("🔌 Connecting WebSocket - RideID: \(rideId), UserID: \(userId)")
            webSocketManager.connect(rideId: rideId, userId: userId)
            
            // Get initial status after delay
            Task {
                try? await Task.sleep(nanoseconds: 20_000_000) // 0.02 seconds
                webSocketManager.fetchCurrentRideStatus(rideId: rideId)
            }
        }
    }
    
    private func updateRideStatusUI(_ rideStatus: RideStatus) {
        print("🔄 RideGiver - Updating UI for status: \(rideStatus)")
        switch rideStatus {
        case .started:
            if rideType == .pick {
                stageReturnedAtActivity()
            } else {
                stageStarted()
            }
            
        case .riderArrived:
            stageStarted()
            stageArrivedAtHome()
            
        case .pickedUp:
            if rideType == .pick {
                stageReturnedAtActivity()
                stagePickedFromActivity()
            } else {
                stageStarted()
                stageArrivedAtHome()
                stagePickedFromHome()
            }
            
        case .arrivedAtActivity:
            if rideType == .pick {
                stageReturnedAtActivity()
            } else {
                stageStarted()
                stageArrivedAtHome()
                stagePickedFromHome()
                stageDroppedAtActivity()
            }
            
        case .activityOngoing:
            if rideType == .pick {
                stageReturnedAtActivity()
            } else {
                stageStarted()
                stageArrivedAtHome()
                stagePickedFromHome()
                stageDroppedAtActivity()
            }
            
        case .returnedActivity:
            stageStarted()
            stageArrivedAtHome()
            stagePickedFromHome()
            stageDroppedAtActivity()
            stageReachedActivity()
            stageReturnedAtActivity()
            
        case .pickedUpFromActivity:
            stageStarted()
            stageArrivedAtHome()
            stagePickedFromHome()
            stageDroppedAtActivity()
            stageReturnedAtActivity()
            stagePickedFromActivity()
            
        case .returnedHome:
            stageStarted()
            stageArrivedAtHome()
            stagePickedFromHome()
            stageDroppedAtActivity()
            stageReturnedAtActivity()
            stagePickedFromActivity()
            stageReachedHome()
            
        case .completed:
            stageStarted()
            stageArrivedAtHome()
            stagePickedFromHome()
            stageDroppedAtActivity()
            stageReturnedAtActivity()
            stagePickedFromActivity()
            stageDroppedAtHome()
            stageCompleted()
            return
            
        default:
            print("⚠️ RideGiver - Unknown status: \(rideStatus)")
        }
    }
}

#Preview {
    Group {
        RideGiverTrackingView(
            rideId: "123",
            riderName: "Ujjwal 24 pandey",
            takerId: "",
            caption: "Sonepat, Sonepat, Haryana",
            pickupAddress: "Deoli Gaon Nai Basti",
            dropoffAddress: "Sonepat, Sonepat, Haryana",
            dropoffLatitude: 0.0,
            dropoffLongitude: 0.0,
            riderImage: UIImage(named: "riderImage"),
            date: "",
            onCall: {},
            onMessage: {},
            onStartRide: {},
            isFromOngoing: false,
            rideType: .dropPick
        )
        .previewDisplayName("Light Mode")
        
        RideGiverTrackingView(
            rideId: "123",
            riderName: "Ujjwal 24 pandey",
            takerId: "",
            caption: "Sonepat, Sonepat, Haryana",
            pickupAddress: "Deoli Gaon Nai Basti",
            dropoffAddress: "Sonepat, Sonepat, Haryana",
            dropoffLatitude: 0.0,
            dropoffLongitude: 0.0,
            riderImage: UIImage(named: "riderImage"),
            date: "",
            onCall: {},
            onMessage: {},
            onStartRide: {},
            isFromOngoing: false,
            rideType: .dropPick
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
} 
