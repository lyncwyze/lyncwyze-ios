import Foundation
import SwiftUI

@MainActor
class RideTrackingViewModel: ObservableObject {
    @Published var rideTrack: RideTrack?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    @Published var statusHistory: [String: String] = [:]
    
    // UI State
    @Published var startStageActive = false
    @Published var pickupStageActive = false
    @Published var dropoffStageActive = false
    @Published var returnStartStageActive = false
    @Published var returnPickupStageActive = false
    @Published var returnDropoffStageActive = false
    
    private let rideId: String
    private let isFromOngoing: Bool
    
    init(rideId: String, isFromOngoing: Bool = false) {
        self.rideId = rideId
        self.isFromOngoing = isFromOngoing
        
        // Fetch ride data on init if from ongoing
        if isFromOngoing {
            Task {
                await getRideData()
            }
        }
    }
    
    func getRideData() async {
        do {
            isLoading = true
            let track: RideTrack = try await withCheckedThrowingContinuation { continuation in
                NetworkManager.shared.makeRequest(
                    endpoint: "/match/get/\(rideId)",
                    method: .GET
                ) { (result: Result<RideTrack, Error>) in
                    continuation.resume(with: result)
                }
            }
            
            self.rideTrack = track
            print("🔄 Current status: \(track.status.rawValue)")
            print("Next Status: \(track.nextStatus ?? "No next status")")
            
            // Get status history from first ride taker if available
            if let firstRideTaker = track.rideTakers.first {
                self.statusHistory = firstRideTaker.statusHistory
                print("📅 Status history updated: \(self.statusHistory)")
            }
            
            // Update WebSocket manager status
            let webSocketManager = RideGiverWebSocketManager.shared
            webSocketManager.currentStatus = track.status
            
            // Convert nextStatus string to WebSocketEvents if available
            if let nextStatusStr = track.nextStatus {
                let nextStatus: WebSocketEvents = {
                    switch nextStatusStr {
                    case "RIDE_START":
                        return .rideStart
                    case "RIDER_ARRIVED":
                        return .riderArrived
                    case "PICKED_UP":
                        return .pickedUp
                    case "ARRIVED_AT_ACTIVITY":
                        return .arrivedAtActivity
                    case "RETURNED_ACTIVITY":
                        return .returnedActivity
                    case "PICKED_UP_FROM_ACTIVITY":
                        return .pickedUpFromActivity
                    case "RETURNED_HOME":
                        return .returnedHome
                    case "COMPLETED":
                        return .completed
                    default:
                        print("⚠️ Unknown next status: \(nextStatusStr)")
                        return .rideStart
                    }
                }()
                webSocketManager.nextStatus = nextStatus
            }
            
            self.isLoading = false
            
        } catch {
            handleError(error)
        }
    }
    
    func updateRideStatus(_ status: RideStatus) {
        if var track = rideTrack {
            track.status = status
            self.rideTrack = track
            updateUIState(for: status)
            objectWillChange.send()
        }
    }
    
    private func updateUIState(for status: RideStatus) {
        switch status {
        case .started:
            startStageActive = true
            
        case .riderArrived:
            startStageActive = true
            
        case .pickedUp:
            startStageActive = true
            pickupStageActive = true
            
        case .arrivedAtActivity:
            startStageActive = true
            pickupStageActive = true
            dropoffStageActive = true
            
        case .activityOngoing:
            startStageActive = true
            pickupStageActive = true
            dropoffStageActive = true
            
        case .returnedActivity:
            startStageActive = true
            pickupStageActive = true
            dropoffStageActive = true
            returnStartStageActive = true
            
        case .pickedUpFromActivity:
            startStageActive = true
            pickupStageActive = true
            dropoffStageActive = true
            returnStartStageActive = true
            returnPickupStageActive = true
            
        case .returnedHome:
            startStageActive = true
            pickupStageActive = true
            dropoffStageActive = true
            returnStartStageActive = true
            returnPickupStageActive = true
//            returnDropoffStageActive = true
            
        case .completed:
            startStageActive = true
            pickupStageActive = true
            dropoffStageActive = true
            returnStartStageActive = true
            returnPickupStageActive = true
            returnDropoffStageActive = true
            
        default:
            break
        }
    }
    
    func updateRideTrack(_ track: RideTrack) {
        self.rideTrack = track
        objectWillChange.send()
    }
    
    private func handleError(_ error: Error) {
        isLoading = false
        if let networkError = error as? NetworkError {
            switch networkError {
            case .apiError(let message):
                if message.contains("7007") || message.contains("Ride location does not exists") {
                    self.error = "Unable to get ride details. Please make sure location services are enabled."
                } else {
                    self.error = message
                }
            case .invalidResponse:
                self.error = "Server returned an invalid response. Please try again."
            case .noData:
                self.error = "No data received from server. Please try again."
            case .decodingError(let decodingError):
                self.error = "Error processing data: \(decodingError.localizedDescription)"
            case .invalidURL:
                self.error = "Invalid URL configuration. Please contact support."
            case .encodingError:
                self.error = "Error preparing request data. Please try again."
            }
        } else {
            self.error = error.localizedDescription
        }
        showError = true
    }
} 
