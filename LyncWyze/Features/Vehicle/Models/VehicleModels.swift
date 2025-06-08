//
//  VehicleModels.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI

struct Vehicle: Identifiable, Codable {
    let id: String?
    var make: String
    var model: String
    var bodyStyle: String
    var bodyColor: String
    var licensePlate: String
    var alias: String?
    var year: Int
    var seatingCapacity: Int
    var primary: Bool
    
    static func `default`() -> Vehicle {
        return Vehicle(
            id: nil,
            make: "",
            model: "",
            bodyStyle: "",
            bodyColor: "",
            licensePlate: "",
            alias: "",
            year: 0,
            seatingCapacity: 0,
            primary: false
        )
    }
}

struct AddVehicleRequest: Codable {
    let make: String
    let model: String
    let bodyStyle: String
    let bodyColor: String
    let licensePlate: String
    let alias: String
    let year: Int
    let seatingCapacity: Int
    let primary: Bool
}

struct AddVehicleResponse: Codable {
    let make: String
    let model: String
    let bodyStyle: String
    let bodyColor: String
    let licensePlate: String
    let alias: String
    let year: Int
    let seatingCapacity: Int
    let primary: Bool
}

