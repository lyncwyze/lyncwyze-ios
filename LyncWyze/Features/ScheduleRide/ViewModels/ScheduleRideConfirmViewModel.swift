//
//  Untitled.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 22/04/25.
//
import SwiftUI

@MainActor
class ScheduleRideConfirmViewModel: ObservableObject {
    @Published private(set) var activityDetail: Activity?
    @Published private(set) var probability: String = ""
    @Published private(set) var isLoading = false
    @Published var showError = false
    @Published private(set) var errorMessage = ""
    @Published var showToast = false
    @Published var shouldDismiss = false
    @Published private(set) var manualRoleType: String? = nil
    
    var probabilityColor: Color {
        switch probability {
            case "LOW":
                return .red
            case "MEDIUM":
                return .orange
            case "HIGH":
                return .green
            default:
                print("probability==>\(probability)")
                return .primary
        }
    }
    
    func getActivity(activityId: String) {
        isLoading = true
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/getActivityById",
            method: .GET,
            parameters: ["activityId": activityId]
        ) { [weak self] (result: Result<Activity, Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let activity):
                    self?.activityDetail = activity
                case .failure(let error):
                    self?.showError = true
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getProbability(activityId: String, dayOfWeek: String) {
        NetworkManager.shared.makeRequest(
            endpoint: "/match/getProbability",
            method: .GET,
            parameters: [
                "activityId": activityId,
                "dayOfWeek": dayOfWeek
            ]
        ) { [weak self] (result: Result<Data, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let probabilityString = String(data: data, encoding: .utf8) {
                        self?.probability = probabilityString
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "\"", with: "")
                    }
                case .failure(let error):
                    self?.showError = true
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func scheduleRide(activityId: String, dayOfWeek: String) {
        isLoading = true
        
        var parameters: [String: String] = [
            "activityId": activityId,
            "dayOfWeek": dayOfWeek
        ]

        if let role = manualRoleType {
            parameters["role"] = role
        }
        
        NetworkManager.shared.makeRequest(
            endpoint: "/match/rideSchedule",
            method: .GET,
            parameters: parameters
        ) { [weak self] (result: Result<Data, Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(_):
                    self?.showToast = true
                    NotificationCenter.default.post(name: NSNotification.Name("RideScheduled"), object: nil)
                    // Dismiss after showing toast
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.shouldDismiss = true
                    }
                case .failure(let error):
                    self?.showError = true
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateManualRoleType(_ roleType: String) {
        manualRoleType = roleType
    }
}
