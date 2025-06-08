import Foundation

enum WeekDays: String, Codable {
    case MONDAY = "MONDAY"
    case TUESDAY = "TUESDAY"
    case WEDNESDAY = "WEDNESDAY"
    case THURSDAY = "THURSDAY"
    case FRIDAY = "FRIDAY"
    case SATURDAY = "SATURDAY"
    case SUNDAY = "SUNDAY"
}

struct EachRide: Codable, Identifiable {
    let id: String
    let activityId: String
    let activityType: String
    let activitySubType: String
    let userId: String
    let userFirstName: String?
    let userLastName: String?
    let userImage: String?
    let childId: String
    let childFirstName: String?
    let childLastName: String?
    let childImage: String?
    let mobileNumber: String?
    let dayOfWeek: WeekDays
    let date: String
    let dateTime: String
    let pickupTime: String
    let dropoffTime: String
    let noOfCompletedRides: Int
    let rating: Double
    let status: String
    let rideTakers: [RideTaker]
    let pickupAddress: ActivityAddress
    let dropoffAddress: ActivityAddress
    let vehicle: Vehicle?
    
    var fullName: String {
        [userFirstName, userLastName].compactMap { $0 }.joined(separator: " ")
    }
}

struct RideTaker: Codable {
    let activityId: String
    let activityType: String
    let activitySubType: String
    let userId: String
    let userFirstName: String?
    let userLastName: String?
    let userImage: String?
    let childId: String
    let childFirstName: String?
    let childLastName: String?
    let mobileNumber: String?
    let noOfCompletedRides: Int
    let rating: Int
    let role: RideType
    let pickupDistance: Int
    let distance: Int
    let pointsSpent: Int?
    let favorite: Bool
    let address: ActivityAddress
    let statusHistory: [String:String]  
    
    var fullName: String {
        [userFirstName, userLastName].compactMap { $0 }.joined(separator: " ")
    }
} 
