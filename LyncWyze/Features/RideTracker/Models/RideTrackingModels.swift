import Foundation


struct RouteLocation: Codable {
    let takerId: String?
    let location: Location
    let dateTime: String
}

// MARK: - Ride Track
struct RideTrack: Codable {
    let rideId: String
    let startLocation: Location
    let endLocation: Location
    let dateTime: String?
    let routeLocations: [RouteLocation]
    let pickupLocations: [RouteLocation]
    var status: RideStatus
    let nextStatus: String?
    let rideTakers: [RideTaker]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rideId = try container.decode(String.self, forKey: .rideId)
        startLocation = try container.decode(Location.self, forKey: .startLocation)
        endLocation = try container.decode(Location.self, forKey: .endLocation)
        dateTime = try? container.decodeIfPresent(String.self, forKey: .dateTime)
        routeLocations = try container.decodeIfPresent([RouteLocation].self, forKey: .routeLocations) ?? []
        pickupLocations = try container.decodeIfPresent([RouteLocation].self, forKey: .pickupLocations) ?? []
        status = try container.decode(RideStatus.self, forKey: .status)
        nextStatus = try container.decodeIfPresent(String.self, forKey: .nextStatus)
        rideTakers = try container.decodeIfPresent([RideTaker].self, forKey: .rideTakers) ?? []
    }
} 
