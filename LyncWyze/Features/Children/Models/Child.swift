//
//  ChildrenModels.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI

struct Child: Identifiable, Codable {
    var id: UUID
    var apiId: String? // Store the original API ID
    var firstName: String
    var lastName: String
    var birthDate: Date
    var gender: String
    var phoneNumber: String
    var imageData: Data?
    var rideInFront: Bool
    var boosterSeatRequired: Bool
    
    init(id: UUID = UUID(), apiId: String? = nil, firstName: String = "", lastName: String = "",
         birthDate: Date = Date(), gender: String = "", phoneNumber: String = "",
         imageData: Data? = nil, rideInFront: Bool = false, boosterSeatRequired: Bool = false) {
        self.id = id
        self.apiId = apiId
        self.firstName = firstName
        self.lastName = lastName
        self.birthDate = birthDate
        self.gender = gender.capitalized
        self.phoneNumber = phoneNumber
        self.imageData = imageData
        self.rideInFront = rideInFront
        self.boosterSeatRequired = boosterSeatRequired
    }
}

struct SaveChildRequest: Codable {
    let id: String?
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let gender: String
    let mobileNumber: String
    let rideInFront: Bool
    let boosterSeatRequired: Bool
}

struct SaveChildResponse: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String
    let gender: String
    let userId: String
    let rideInFront: Bool
    let boosterSeatRequired: Bool
    let imageUrl: String?
}

struct GetChildResponse: Codable {
    var id: String
    var firstName: String
    var lastName: String
    var dateOfBirth: String
    var gender: String
    var mobileNumber: String?
    var rideInFront: Bool
    var boosterSeatRequired: Bool
    var image: String?
    
    func toChild() async throws -> Child {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let birthDate = dateFormatter.date(from: dateOfBirth) ?? Date()
        
        print("Image ==> \(image ?? "No Image")")
        var imageData: Data? = nil
        if let imagePath = image {
            do {
                imageData = try await NetworkManager.shared.loadImageAsync(path: imagePath)
            } catch {
                print("Failed to load image: \(error)")
            }
        }
        
        return Child(
            id: UUID(),
            apiId: id,
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
            gender: gender,
            phoneNumber: mobileNumber ?? "",
            imageData: imageData,
            rideInFront: rideInFront,
            boosterSeatRequired: boosterSeatRequired
        )
    }
}
