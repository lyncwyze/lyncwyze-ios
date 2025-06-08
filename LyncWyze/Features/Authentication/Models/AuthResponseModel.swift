enum ProfileStatus: String, Codable {
    case profile = "PROFILE"
    case background = "BACKGROUND"
    case photo = "PHOTO"
    case policy = "POLICY"
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String
    var profileComplete: Bool
    let clientId: String
    let name: String
    let fullName: String?
    let emailId: String?
    var profileStatus: ProfileStatus?
    var acceptTermsAndPrivacyPolicy: Bool
    let userId: String
    let changePassword: Bool
    let jti: String
}
