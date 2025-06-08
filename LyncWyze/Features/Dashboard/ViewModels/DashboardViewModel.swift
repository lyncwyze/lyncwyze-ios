import Foundation
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    // Add any additional properties or methods needed for dashboard functionality
    
    func refreshDashboard() {
        isLoading = true
        // Add refresh logic if needed
        isLoading = false
    }
} 