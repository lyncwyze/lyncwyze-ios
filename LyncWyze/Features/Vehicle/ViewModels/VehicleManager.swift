import Foundation
import SwiftUI

@MainActor
class VehicleManager: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Get All Vehicles
    func getVehicles() async {
        isLoading = true
        error = nil
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/getVehicles",
            method: .GET
        ) { [weak self] (result: Result<PaginatedResponse<Vehicle>, Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.vehicles = response.data
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Get Vehicle By ID
    func getVehicleById(vehicleId: String) async -> Vehicle? {
        isLoading = true
        error = nil
        
        return await withCheckedContinuation { continuation in
            NetworkManager.shared.makeRequest(
                endpoint: "/user/getVehicleById",
                method: .GET,
                parameters: ["vehicleId": vehicleId]
            ) { [weak self] (result: Result<Vehicle, Error>) in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let vehicle):
                        continuation.resume(returning: vehicle)
                    case .failure(let error):
                        self.error = error.localizedDescription
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Add Vehicle
    func addVehicle(_ vehicle: Vehicle) async -> Bool {
        isLoading = true
        error = nil
        
        return await withCheckedContinuation { continuation in
            guard let jsonData = try? JSONEncoder().encode(vehicle) else {
                self.error = "Failed to encode vehicle data"
                continuation.resume(returning: false)
                return
            }
            
            NetworkManager.shared.makeRequest(
                endpoint: "/user/addVehicle",
                method: .POST,
                body: jsonData
            ) { [weak self] (result: Result<Vehicle, Error>) in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let newVehicle):
                        self.vehicles.append(newVehicle)
                        continuation.resume(returning: true)
                    case .failure(let error):
                        self.error = error.localizedDescription
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Update Vehicle
    func updateVehicle(_ vehicle: Vehicle) async -> Bool {
        isLoading = true
        error = nil
        
        return await withCheckedContinuation { continuation in
            guard let jsonData = try? JSONEncoder().encode(vehicle) else {
                self.error = "Failed to encode vehicle data"
                continuation.resume(returning: false)
                return
            }
            
            NetworkManager.shared.makeRequest(
                endpoint: "/user/updateVehicle",
                method: .POST,
                body: jsonData
            ) { [weak self] (result: Result<Vehicle, Error>) in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let updatedVehicle):
                        if let index = self.vehicles.firstIndex(where: { $0.id == updatedVehicle.id }) {
                            self.vehicles[index] = updatedVehicle
                        }
                        continuation.resume(returning: true)
                    case .failure(let error):
                        self.error = error.localizedDescription
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Vehicle
    func deleteVehicle(vehicleId: String) async -> Bool {
        isLoading = true
        error = nil
        
        return await withCheckedContinuation { continuation in
            NetworkManager.shared.makeRequest(
                endpoint: "/user/deleteVehicle",
                method: .DELETE,
                parameters: ["vehicleId": vehicleId]
            ) { [weak self] (result: Result<Bool, Error>) in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let success):
                        if success {
                            self.vehicles.removeAll { $0.id == vehicleId }
                        }
                        continuation.resume(returning: success)
                    case .failure(let error):
                        self.error = error.localizedDescription
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
} 