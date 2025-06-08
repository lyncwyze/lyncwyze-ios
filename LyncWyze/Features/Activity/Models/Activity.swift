import Foundation
import UIKit

struct Activity: Identifiable, Codable {
    let id: String?
    var childId: String
    var type: String
    var subType: String
    var address: ActivityAddress
    var image: String?
    var schedulePerDay: [String: DailySchedule]
    
    enum CodingKeys: String, CodingKey {
        case id
        case childId
        case type
        case subType
        case address
        case image
        case schedulePerDay
    }
    
    static func `default`() -> Activity {
        return Activity(
            id: nil,
            childId: "",
            type: "",
            subType: "",
            address: ActivityAddress.default(),
            image: nil,
            schedulePerDay: [:]
        )
    }
}

struct ActivityAddress: Codable {
    var user: String?
    var userId: String?
    var addressLine1: String?
    var addressLine2: String?
    var landMark: String?
    var pincode: Int?
    var state: String?
    var city: String?
    var location: ActivityLocation
    
    enum CodingKeys: String, CodingKey {
        case user
        case userId
        case addressLine1
        case addressLine2
        case landMark
        case pincode
        case state
        case city
        case location
    }
    
    static func `default`() -> ActivityAddress {
        return ActivityAddress(
            user: nil,
            userId: nil,
            addressLine1: "",
            addressLine2: nil,
            landMark: nil,
            pincode: nil,
            state: nil,
            city: nil,
            location: ActivityLocation.default()
        )
    }
}

struct ActivityLocation: Codable {
    var description: String?
    var placeId: String?
    var sessionToken: String?
    var x: Double?
    var y: Double?
    var coordinates: [Double]
    var type: String
    
    enum CodingKeys: String, CodingKey {
        case description
        case placeId
        case sessionToken
        case x
        case y
        case coordinates
        case type
    }
    
    static func `default`() -> ActivityLocation {
        return ActivityLocation(
            description: nil,
            placeId: nil,
            sessionToken: nil,
            x: nil,
            y: nil,
            coordinates: [0.0, 0.0],
            type: "Point"
        )
    }
}

struct DailySchedule: Codable {
    var startTime: String
    var endTime: String
    var preferredPickupTime: Int
    var pickupRole: String
    var dropoffRole: String
    
    enum CodingKeys: String, CodingKey {
        case startTime
        case endTime
        case preferredPickupTime
        case pickupRole
        case dropoffRole
    }
    
    static func `default`() -> DailySchedule {
        return DailySchedule(
            startTime: "",
            endTime: "",
            preferredPickupTime: 0,
            pickupRole: "GIVER",
            dropoffRole: "GIVER"
        )
    }
}
