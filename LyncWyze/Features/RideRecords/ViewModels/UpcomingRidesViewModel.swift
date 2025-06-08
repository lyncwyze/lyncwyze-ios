import Foundation
import SwiftUI

@MainActor
class UpcomingRidesViewModel: ObservableObject {
    @Published var rides: [EachRide] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    private let authResponse: AuthResponse?
    private let userId: String?
    
    init() {
        self.authResponse = getUserDefaultObject(forKey: Constants.UserDefaultsKeys.loggedInDataKey)
        self.userId = self.authResponse?.userId
    }
    
    func fetchUpcomingRides() {
        isLoading = true
        
        let parameters = [
            "pageSize": "100",
            "status": RideStatus.scheduled.rawValue
        ]
        
        NetworkManager.shared.makeRequest(
            endpoint: "/match/getRides",
            method: .GET,
            parameters: parameters
        ) { [weak self] (result: Result<PaginatedResponse<EachRide>, Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.rides = response.data
                case .failure(let error):
                    self?.error = error.localizedDescription
                    self?.showError = true
                }
            }
        }
    }
    
    func isCurrentUserRideTaker(in ride: EachRide) -> Bool {
        return ride.rideTakers.contains { $0.userId == userId }
    }
    
    func makePhoneCall(number: String?) {
        guard let number = number,
              let url = URL(string: "tel://\(number)"),
              UIApplication.shared.canOpenURL(url) else {
            error = NSLocalizedString("phone_number_missing", comment: "")
            showError = true
            return
        }
        UIApplication.shared.open(url)
    }
    
    func sendMessage(number: String?) {
        guard let number = number,
              let url = URL(string: "sms:\(number)"),
              UIApplication.shared.canOpenURL(url) else {
            error = NSLocalizedString("phone_number_missing", comment: "")
            showError = true
            return
        }
        UIApplication.shared.open(url)
    }
    
    func convertToMiles(_ meters: Int) -> String {
        let miles = Double(meters) / 1609.34
        return String(format: "%.1f miles", miles)
    }
    
    func saveRideData(ride: EachRide) {
        saveUserDefaultObject(ride, forKey: Constants.UserDefaultsKeys.rideData)
    }
    
    func getDisplayName(for ride: EachRide) -> String {
        if isCurrentUserRideTaker(in: ride) {
            let firstName = ride.userFirstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let lastName = ride.userLastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        } else {
            let firstName = ride.rideTakers[0].userFirstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let lastName = ride.rideTakers[0].userLastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        }
    }
    
    func getDisplayImage(for ride: EachRide) -> String {
        if isCurrentUserRideTaker(in: ride) {
            if let profileImageUrl = ride.userImage, !profileImageUrl.isEmpty {
                return profileImageUrl
            } else {
                return ""
            }
        } else {
            if let profileImageUrl = ride.rideTakers[0].userImage, !profileImageUrl.isEmpty {
                return profileImageUrl
            }else {
                return ""
            }
        }
    }
    
    func getSuccessRecord(for ride: EachRide) -> String {
        let completedRides = isCurrentUserRideTaker(in: ride) ? 
            ride.noOfCompletedRides : 
            ride.rideTakers[0].noOfCompletedRides
        return String(format: NSLocalizedString("successfully_completed_rides", comment: ""), completedRides)
    }
    
    func getPhoneNumber(for ride: EachRide) -> String? {
        return isCurrentUserRideTaker(in: ride) ? 
            ride.mobileNumber : 
            ride.rideTakers[0].mobileNumber
    }
} 
