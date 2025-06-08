//
//  OnboardingModels.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 09/03/25.
//


struct CreateProfileRequest: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let mobileNumber: String
    let password: String
    let confirmPassword: String
}

struct CreateProfileRequestFromEmail: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let confirmPassword: String
}

struct CreateProfileRequestFromMobile: Codable {
    let firstName: String
    let lastName: String
    let mobileNumber: String
    let password: String
    let confirmPassword: String
}

struct ApiResponse<T: Codable>: Codable {
    let data: T?
    let status: String?
    let message: String?
    let error: String?
    let error_description: String?
    let errorInformation: ErrorInformation?
    
    struct ErrorInformation: Codable {
        let errorCode: String?
        let errorDescription: String?
    }
}

struct CreateProfileResponse: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let password: String?
    let confirmPassword: String?
    let ssnLast4: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.email = try container.decode(String.self, forKey: .email)
        self.password = try? container.decode(String.self, forKey: .password) // Default to empty string
        self.confirmPassword = try? container.decode(String.self, forKey: .confirmPassword) // Default to empty string
        self.ssnLast4 = try? container.decode(String.self, forKey: .ssnLast4) // Default to "N/A"
    }
}


struct GeoLocation: Codable {
    let x: Double
    let y: Double
    let coordinates: [Double]
    let type: String

}

struct Address: Codable {
    let addressLine1: String
    let addressLine2: String?
    let landMark: String?
    let pincode: Int?
    let state: String?
    let city: String?
    let location: GeoLocation?
}

struct BackgroundVerificationRequest: Codable {
    let ssn: String
    let licenseNumber: String
    let licenseState: String
    let licenseExpiredDate: String
    let address: Address
}
