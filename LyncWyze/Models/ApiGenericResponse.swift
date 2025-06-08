struct DataCountResponse: Codable {
    let activity: Int
    let child: Int
    let emergencyContact: Int
    let vehicle: Int
    let ongoingRides: Int
    let givenRides: Int
    let takenRides: Int
    let upcomingRides: Int
    let profile: Int?
} 

// Model for the response
struct EmptyResponse: Codable {}

// Paginated Response
struct PaginatedResponse<T: Codable>: Codable {
    var data: [T]
    let totalCount: Int
    let pageSize: Int
    let currentPage: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool
}