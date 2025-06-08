//
//  ProfileServiceVM.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 09/03/25.
//
import SwiftUI

class ProfileService {
    func createProfileFromEmail(
        request: CreateProfileRequestFromEmail,
        completion: @escaping (Result<CreateProfileResponse, Error>) -> Void
    ) {
     
        
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let jsonData = try jsonEncoder.encode(request)
            
            NetworkManager.shared.makeRequest(
                endpoint: "/user/createProfile",
                method: .POST,
                body: jsonData
            ) { (result: Result<CreateProfileResponse, Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profileResponse):
                        print("✅ Profile Creation Successful!")
                        completion(.success(profileResponse))
                        
                    case .failure(let error):
                        print("❌ Profile Creation Failed:")
                        if let networkError = error as? NetworkError {
                            print("Network Error: \(networkError.localizedDescription)")
                            completion(.failure(networkError))
                        } else {
                            print("Other Error: \(error.localizedDescription)")
                            completion(.failure(NetworkError.apiError(error.localizedDescription)))
                        }
                    }
                }
            }
        } catch {
            print("❌ Request Encoding Error:")
            print(error.localizedDescription)
            completion(.failure(NetworkError.apiError("Failed to encode request: \(error.localizedDescription)")))
        }
    }
    
    func createProfileFromMobile(
        request: CreateProfileRequestFromMobile,
        completion: @escaping (Result<CreateProfileResponse, Error>) -> Void
    ) {
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let jsonData = try jsonEncoder.encode(request)
            
            NetworkManager.shared.makeRequest(
                endpoint: "/user/createProfile",
                method: .POST,
                body: jsonData
            ) { (result: Result<CreateProfileResponse, Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profileResponse):
                        print("✅ Profile Creation Successful!")
                        completion(.success(profileResponse))
                        
                    case .failure(let error):
                        print("❌ Profile Creation Failed:")
                        if let networkError = error as? NetworkError {
                            print("Network Error: \(networkError.localizedDescription)")
                            completion(.failure(networkError))
                        } else {
                            print("Other Error: \(error.localizedDescription)")
                            completion(.failure(NetworkError.apiError(error.localizedDescription)))
                        }
                    }
                }
            }
        } catch {
            print("❌ Request Encoding Error:")
            print(error.localizedDescription)
            completion(.failure(NetworkError.apiError("Failed to encode request: \(error.localizedDescription)")))
        }
    }

}
