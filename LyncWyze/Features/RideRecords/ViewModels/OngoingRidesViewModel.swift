import Foundation
import SwiftUI

@MainActor
class OngoingRidesViewModel: ObservableObject {
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
    
    func fetchOngoingRides() {
        isLoading = true
        
        let parameters = [
            "pageSize": "100",
            "status": "ONGOING"
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
    
    func isCurrentUserRideTaker(in ride: EachRide) -> Bool {
        guard let userId = userId else { return false }
        return ride.rideTakers.contains { $0.userId == userId }
    }
    
    func convertToMiles(_ meters: Int) -> String {
        let miles = Double(meters) / 1609.34
        return String(format: "%.1f miles", miles)
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
}
