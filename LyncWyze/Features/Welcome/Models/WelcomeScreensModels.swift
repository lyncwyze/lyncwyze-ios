//
//  Location.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 06/03/25.
//

struct LocationResponse: Codable {
    let locations: [Location]
}

struct NotifyUserResponse: Codable {
    let success: Bool
}

struct Location: Codable, Equatable {
    let sessionToken: String?
    let description: String?
    let placeId: String?
    let x: Double?
    let y: Double?
    let coordinates: [Double]?
    let type: String?
}


struct ServiceAvailabilityResponse: Codable {
    let serviceAvailable: Bool
}

// Make Address2 conform to Codable
//struct Address2: Codable {
//    // Add properties that match your backend response
//    let street: String?
//    let city: String?
//    let state: String?
//    let zipCode: String?
//    let country: String?
//}

// Updated Model for the request body
struct NotifyUserRequest: Codable {
    let id: String
    let name: String
    let email: String
    let mobileNumber: String?
    let newsletterSubscription: Bool
}
