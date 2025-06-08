


// UserDefaults keys
//enum UserDefaultsKeys {
//    static let accessToken = "accessToken"
//    static let accessTokenExpTime = "accessTokenExpTime"
//    static let userId = "userId"
//    static let name = "name"
//    static let clientId = "clientId"
//    static let changePassword = "changePassword"
//}

// Main response struct with pagination
struct PageableResponse<T: Codable>: Codable {  // T needs to be Codable
    let data: [T]
    let totalCount: Int
    let pageSize: Int
    let currentPage: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

// Provider struct
//struct Provider: Hashable {
//    let id: String
//    let name: String
//    let type: String
//    let address: Address2
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//    
//    static func == (lhs: Provider, rhs: Provider) -> Bool {
//        return lhs.id == rhs.id
//    }
//
//}
//
//// Address struct with location
//struct Address2 {
//    let pincode: Int
//    let state: String
//    let city: String
//    let location: Location2
//}

struct Address2: Codable {
    let userId: String?
    let addressLine1: String
    let addressLine2: String?
    let landMark: String?
    let pincode: Int
    let state: String
    let city: String
    let location: Location2
    
    enum CodingKeys: String, CodingKey {
        case userId
        case addressLine1
        case addressLine2
        case landMark
        case pincode
        case state
        case city
        case location
    }
}

// Location struct for coordinates
struct Location2: Codable {
    let coordinates: [Double]
    let type: String
}

