import Foundation
import SwiftUI

@MainActor
class ScheduleRideValidDaysViewModel: ObservableObject {
    @Published private(set) var validDays: [String] = []
    @Published private(set) var isLoading = false
    @Published var showError = false
    @Published private(set) var errorMessage = ""
    
    func fetchValidDays() {
        isLoading = true
        
        NetworkManager.shared.makeRequest(
            endpoint: "/match/validDays",
            method: .GET
        ) { [weak self] (result: Result<[String], Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let days):
                    self?.validDays = days
                case .failure(let error):
                    self?.showError = true
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func isDayValid(_ day: String) -> Bool {
        return validDays.contains(day)
    }
} 
