import Foundation

struct FeedBackPreReq: Codable {
    let rideId: String
    let fromUserId: String
    let fromUserName: String
    let forUserId: String
    let forUserName: String
    let date: String
    let riderType: RiderType
    
    enum CodingKeys: String, CodingKey {
        case rideId
        case fromUserId
        case fromUserName
        case forUserId
        case forUserName
        case date
        case riderType
    }
} 
