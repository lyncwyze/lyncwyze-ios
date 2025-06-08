import Foundation

struct SurveyReport: Codable, Equatable {
    let id: String?
    let rideId: String
    let reviewerId: String     // Who is rating
    let revieweeId: String     // Whom is being rated
    let reviewerRole: RiderType
    var ratings: [String: Int]
    var overallRating: Double
    var favorite: Bool
    var comments: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case rideId
        case reviewerId
        case revieweeId
        case reviewerRole
        case ratings
        case overallRating
        case favorite
        case comments
    }
    
    init(id: String? = nil,
         rideId: String,
         reviewerId: String,
         revieweeId: String,
         reviewerRole: RiderType,
         ratings: [String: Int] = [:],
         overallRating: Double = 0.0,
         favorite: Bool = false,
         comments: String? = nil) {
        self.id = id
        self.rideId = rideId
        self.reviewerId = reviewerId
        self.revieweeId = revieweeId
        self.reviewerRole = reviewerRole
        self.ratings = ratings
        self.overallRating = overallRating
        self.favorite = favorite
        self.comments = comments
    }
    
    static func == (lhs: SurveyReport, rhs: SurveyReport) -> Bool {
        lhs.id == rhs.id &&
        lhs.rideId == rhs.rideId &&
        lhs.reviewerId == rhs.reviewerId &&
        lhs.revieweeId == rhs.revieweeId &&
        lhs.reviewerRole == rhs.reviewerRole &&
        lhs.ratings == rhs.ratings &&
        lhs.overallRating == rhs.overallRating &&
        lhs.favorite == rhs.favorite &&
        lhs.comments == rhs.comments
    }
}
