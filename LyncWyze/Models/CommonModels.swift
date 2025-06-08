// Make Provider conform to Codable with proper CodingKeys if needed
struct Provider: Hashable, Codable {
    let id: String
    let name: String
    let type: String
    let subType: String
    let address: Address2
    
    // CodingKeys in case your JSON keys are different
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case subType
        case address
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Provider, rhs: Provider) -> Bool {
        return lhs.id == rhs.id
    }
}