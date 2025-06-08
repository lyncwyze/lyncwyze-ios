import Foundation
import SwiftUI

@MainActor
class RidesGivenViewModel: ObservableObject {
    @Published var rides: [EachRide] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    private let authResponse: AuthResponse?
    
    init() {
        self.authResponse = getUserDefaultObject(forKey: Constants.UserDefaultsKeys.loggedInDataKey)
    }
    
    func fetchRidesGiven() {
        isLoading = true
        
        let parameters = [
            "pageSize": "100",
            "status": RideStatus.completed.rawValue,
            "role": RiderType.giver.rawValue
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
    
    func convertToMiles(_ meters: Int) -> String {
        let miles = Double(meters) / 1609.34
        return String(format: "%.1f miles", miles)
    }
    
    func saveFeedbackData(for ride: EachRide) {
        let feedbackData = FeedBackPreReq(
            rideId: ride.id,
            fromUserId: ride.userId,
            fromUserName: ride.fullName,
            forUserId: ride.rideTakers[0].userId,
            forUserName: ride.rideTakers[0].fullName,
            date: ride.date,
            riderType: .giver
        )
        saveUserDefaultObject(feedbackData, forKey: Constants.UserDefaultsKeys.feedBackRequired)
    }
}
