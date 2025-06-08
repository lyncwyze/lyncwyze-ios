//
//  EmergencyContact.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI

struct EmergencyContact: Identifiable, Codable, Equatable {
    let id: String?
    var firstName: String
    var lastName: String
    var mobileNumber: String
    var userId: String
    var email: String?

    init(id: String? = nil, firstName: String = "", lastName: String = "",
         mobileNumber: String = "", email: String? = nil, userId: String = "") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.mobileNumber = mobileNumber
        self.email = email
        self.userId = userId
    }
    
    // Implement Equatable
    static func == (lhs: EmergencyContact, rhs: EmergencyContact) -> Bool {
        return lhs.id == rhs.id &&
               lhs.userId == rhs.userId &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.mobileNumber == rhs.mobileNumber &&
               lhs.email == rhs.email
    }
}

struct EmergencyContactRequest: Codable {
    let childId: String
    let firstName: String
    let lastName: String
    let mobileNumber: String
    let email: String
}

// struct PaginatedResponse<T: Codable>: Codable {
//     var data: [T]
//     let totalCount: Int
//     let pageSize: Int
//     let currentPage: Int
//     let totalPages: Int
//     let hasNext: Bool
//     let hasPrevious: Bool
// }

// struct EmptyResponse: Codable {}
