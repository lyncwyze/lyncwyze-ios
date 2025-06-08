import Foundation
import SwiftUI

enum AppEnvironment {
    case development
    case production
    
    // Get current environment from environment variables
    static var current: AppEnvironment {
        guard let envFlag = ProcessInfo.processInfo.environment["USE_GEOCODE_API"]?.lowercased() else {
            return .development
        }
        return envFlag == "true" ? .development : .production
    }
}

struct APIEndpoints {
    static func getServiceCheckEndpoint() -> String {
        switch AppEnvironment.current {
        case .development:
            return "/match/getGeoCode"
        case .production:
            return "/match/checkServiceAvailability"
        }
    }
}
