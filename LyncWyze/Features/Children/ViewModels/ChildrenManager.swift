//
//  ChildrenManager.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI

class ChildrenManager: ObservableObject {
    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    private let saveKey = "SavedChildren"

    init() {
        loadChildren() // Load cached data first
        fetchChildren() // Then fetch fresh data
    }
    
    func fetchChildren() {
        isLoading = true
        error = nil
        
        let parameters = [
            "pageSize": "1000",
            "offSet": "0",
            "sortOrder": "ASC"
        ]
        
        networkManager.makeRequest(
            endpoint: "/user/getChildren",
            method: .GET,
            parameters: parameters
        ) { [weak self] (result: Result<PaginatedResponse<GetChildResponse>, Error>) in
            Task { [weak self] in
                await self?.handleFetchChildrenResponse(result)
            }
        }
    }
    
    @MainActor
    private func handleFetchChildrenResponse(_ result: Result<PaginatedResponse<GetChildResponse>, Error>) async {
        isLoading = false
        do {
            switch result {
            case .success(let response):
                children = try await withThrowingTaskGroup(of: Child.self) { group in
                    for childResponse in response.data {
                        group.addTask {
                            try await childResponse.toChild()
                        }
                    }
                    var loadedChildren: [Child] = []
                    for try await child in group {
                        loadedChildren.append(child)
                    }
                    return sortChildren(loadedChildren)
                }
                saveChildren()
            case .failure(let error):
                self.error = error.localizedDescription
                loadChildren()
            }
        } catch {
            self.error = error.localizedDescription
            loadChildren()
        }
    }

    func addChild(_ child: Child) {
        children = sortChildren(children + [child])
        saveChildren()
    }

    func updateChild(_ child: Child) {
        if let index = children.firstIndex(where: { $0.id == child.id }) {
            children[index] = child
            children = sortChildren(children)
            saveChildren()
        }
    }

    func deleteChild(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let childToDelete = children[index]
        
        guard let apiId = childToDelete.apiId else {
            // If no API ID, just remove locally
            children.remove(atOffsets: indexSet)
            saveChildren()
            return
        }
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/deleteChild",
            method: .DELETE,
            parameters: ["childId": apiId]
        ) { [weak self] (result: Result<EmptyResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self?.children.remove(atOffsets: indexSet)
                    self?.saveChildren()
                case .failure(let error):
                    print("Failed to delete child: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchChildById(childId: String, completion: @escaping (Result<Child, Error>) -> Void) {
        let parameters = ["childId": childId]
        print("childId: \(childId)")
        networkManager.makeRequest(
            endpoint: "/user/getChildById",
            method: .GET,
            parameters: parameters
        ) { (result: Result<GetChildResponse, Error>) in
            Task {
                do {
                    switch result {
                    case .success(let response):
                        let child = try await response.toChild()
                        DispatchQueue.main.async {
                            completion(.success(child))
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func updateChildWithAPI(child: Child, image: UIImage?, completion: @escaping (Result<Child, Error>) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let childRequest = SaveChildRequest(
            id: child.apiId,
            firstName: child.firstName,
            lastName: child.lastName,
            dateOfBirth: dateFormatter.string(from: child.birthDate),
            gender: child.gender.uppercased(),
            mobileNumber: child.phoneNumber,
            rideInFront: child.rideInFront,
            boosterSeatRequired: child.boosterSeatRequired
        )
        
        // Create multipart form data
        var formData = NetworkManager.MultipartFormData()
        
        // Add child data
        formData.append(childRequest, name: "child")
        
        // Add image if available
        if let image = image {
            formData.append(image, name: "file", fileName: "image.jpg")
        }
        
        // Prepare request data
        let requestData = formData.finalize()
        let headers = ["Content-Type": formData.contentType]
        
        networkManager.makeRequest(
            endpoint: "/user/updateChild",
            method: .POST,
            headers: headers,
            body: requestData
        ) { (result: Result<GetChildResponse, Error>) in
            Task { [weak self] in
                do {
                    switch result {
                    case .success(let response):
                        let updatedChild = try await response.toChild()
                        DispatchQueue.main.async {
                            if let index = self?.children.firstIndex(where: { $0.apiId == child.apiId }) {
                                self?.children[index] = updatedChild
                                self?.saveChildren()
                            }
                            completion(.success(updatedChild))
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private func sortChildren(_ children: [Child]) -> [Child] {
        return children.sorted { first, second in
            if first.firstName.lowercased() == second.firstName.lowercased() {
                return first.lastName.lowercased() < second.lastName.lowercased()
            }
            return first.firstName.lowercased() < second.firstName.lowercased()
        }
    }

    private func saveChildren() {
        if let encoded = try? JSONEncoder().encode(children) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadChildren() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = sortChildren(decoded)
        }
    }
}
