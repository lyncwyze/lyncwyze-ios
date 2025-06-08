import Foundation

enum RideStatus: String, Codable {
    case scheduled = "SCHEDULED"
    case started = "STARTED"
    case riderArrived = "RIDER_ARRIVED"
    case pickedUp = "PICKED_UP"
    case arrivedAtActivity = "ARRIVED_AT_ACTIVITY"
    case activityOngoing = "ACTIVITY_ONGOING"
    case returnedActivity = "RETURNED_ACTIVITY"
    case pickedUpFromActivity = "PICKED_UP_FROM_ACTIVITY"
    case returnedHome = "RETURNED_HOME"
    case completed = "COMPLETED"
    case canceled = "CANCELED"
    case ongoing = "ONGOING"
    
    var displayName: String {
        return self.rawValue
    }
    
    static func fromString(_ value: String) -> RideStatus? {
        return RideStatus(rawValue: value.uppercased())
    }
}

enum RideType: String, Codable {
    case drop = "DROP"
    case pick = "PICK"
    case dropPick = "DROP_PICK"
    
    var displayName: String {
        return self.rawValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).uppercased()
        
        // Default to .dropPick for "GIVER" or any other unrecognized value
        if let type = RideType(rawValue: value) {
            self = type
        } else {
            self = .dropPick
        }
    }
    
    static func fromString(_ value: String) -> RideType? {
        let type = RideType(rawValue: value.uppercased())
        return type ?? .drop // Default to .dropPick if string doesn't match
    }
}

enum RiderType: String, Codable {
    case giver = "GIVER"
    case taker = "TAKER"
    
    var displayName: String {
        return self.rawValue
    }
    
    static func fromString(_ value: String) -> RiderType? {
        return RiderType(rawValue: value.uppercased())
    }
} 
