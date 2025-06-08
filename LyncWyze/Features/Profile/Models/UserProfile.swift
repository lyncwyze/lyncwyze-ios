import Foundation

struct UserProfile: Codable {
    let id: String
    let firstName: String
    let middleName: String?
    let lastName: String
    let image: String?
    let email: String
    let mobileNumber: String?
    let imei: String?
    let dateOfBirth: String?
    let gender: String?
    let active: Bool?
    let locked: Bool?
    let forcePasswordChange: Bool?
    let pwdExpiryDate: String?
    let lastSuccessfulLogin: String?
    let lockedTill: Int64?
    let failedLoginAttempt: Int?
    let expiryNotifyCount: Int?
    let forgetPwdToken: String?
    let activatePwdToken: String?
    let status: String?
    let oldPassword: String?
    let password: String?
    let confirmPassword: String?
    let addresses: [Address]
    let ssnLast4: String?
    let community: String?
    let consentForBackgroundCheck: Bool?
    let backgroundCheck: BackgroundCheck?
    let membership: Membership?
    let referralCode: String?
    let child: [Child]?
    let vehicles: [Vehicle]?
    let rideRole: String?
    let pointsBalance: Int?
    let comment: String?
    let createdBy: String?
    let createdDate: String
    let modifiedBy: String?
    let modifiedDate: String
    
    // Computed property for full name
    var fullName: String {
        if let middle = middleName {
            return "\(firstName) \(middle) \(lastName)"
        }
        return "\(firstName) \(lastName)"
    }
    
    // CodingKeys to handle API field name mismatches
    private enum CodingKeys: String, CodingKey {
        case id, firstName, middleName, lastName, image, email
        case mobileNumber, imei
        case dateOfBirth = "dateOfBirth" // Try alternative field name
        case gender, active, locked, forcePasswordChange
        case pwdExpiryDate, lastSuccessfulLogin, lockedTill
        case failedLoginAttempt, expiryNotifyCount
        case forgetPwdToken, activatePwdToken, status
        case oldPassword, password, confirmPassword
        case addresses, ssnLast4, community
        case consentForBackgroundCheck
        case backgroundCheck, membership
        case referralCode, child, vehicles
        case rideRole, pointsBalance, comment
        case createdBy, createdDate
        case modifiedBy, modifiedDate
    }
}

struct BackgroundCheck: Codable {
    let ssn: String
    let licenseNumber: String?
    let licenseState: String?
    let licenseExpiredDate: String
    let status: String
    let initiatedDate: String
    let completedDate: String
}

struct Membership: Codable {
    let status: String
    let startDate: String
    let expiryDate: String
    let renewalCost: Int
    let trial: Bool
}
