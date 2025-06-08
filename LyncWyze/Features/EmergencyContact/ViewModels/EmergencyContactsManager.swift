//
//  EmergencyContactsManager.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//

import SwiftUI

class EmergencyContactsManager: ObservableObject {
    @Published var contacts: [EmergencyContact] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var currentPage = 1
    private var hasNextPage = false
    private let pageSize = 10
    
    func fetchContacts(refresh: Bool = false) {
        if refresh {
            currentPage = 1
            contacts = []
        }
        
        isLoading = true
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/getEmergencyContacts",
            method: .GET,
            parameters: [
                "pageSize": String(pageSize),
                "offSet": String((currentPage - 1) * pageSize),
                "sortOrder": "DESC"
            ]
        ) { (result: Result<PaginatedResponse<EmergencyContact>, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    if refresh {
                        self.contacts = response.data
                    } else {
                        self.contacts.append(contentsOf: response.data)
                    }
                    self.hasNextPage = response.hasNext
                    self.currentPage += 1
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func loadMoreIfNeeded(currentItem contact: EmergencyContact) {
        guard !isLoading else { return }
        
        let thresholdIndex = contacts.index(contacts.endIndex, offsetBy: -3)
        if contacts.firstIndex(where: { $0.id == contact.id }) == thresholdIndex {
            if hasNextPage {
                fetchContacts()
            }
        }
    }
    
    func getContactById(_ id: String, completion: @escaping (Result<EmergencyContact, Error>) -> Void) {
        NetworkManager.shared.makeRequest(
            endpoint: "/user/getEmergencyContactById",
            method: .GET,
            parameters: ["emergencyContactId": id]
        ) { (result: Result<EmergencyContact, Error>) in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func updateContact(_ contact: EmergencyContact) {
        isLoading = true
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/updateEmergencyContact",
            method: .POST,
            body: try? JSONEncoder().encode(contact),
            parameters: ["userId": contact.userId ?? ""]
        ) { (result: Result<EmergencyContact, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let updatedContact):
                    if let index = self.contacts.firstIndex(where: { $0.id == contact.id }) {
                        self.contacts[index] = updatedContact
                    }
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func deleteContact(id: String) {
        isLoading = true
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/deleteEmergencyContact",
            method: .DELETE,
            parameters: ["emergencyContactId": id]
        ) { (result: Result<Bool, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let success):
                    if success {
                        self.contacts.removeAll { $0.id == id }
                    }
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func addContact(_ contact: EmergencyContact) {
        isLoading = true
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/addEmergencyContact",
            method: .POST,
            body: try? JSONEncoder().encode(contact)
        ) { (result: Result<EmergencyContact, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let newContact):
                    self.contacts.insert(newContact, at: 0)
                case .failure(let error):
                    self.error = error.localizedDescription
                }
            }
        }
    }
}
