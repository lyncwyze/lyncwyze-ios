import Foundation

struct Country: Codable, Identifiable, Hashable {
    let name: String
    let flag: String
    let code: String
    let dialCode: String
    
    var id: String { code }
    
    enum CodingKeys: String, CodingKey {
        case name
        case flag
        case code
        case dialCode = "dial_code"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
    
    static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.code == rhs.code
    }
} 