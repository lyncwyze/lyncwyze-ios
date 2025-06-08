//
//  AddressSelectionVM.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 06/03/25.
//

import SwiftUI

class AddressSelectionViewModel: ObservableObject {
    @Published var locations: [Location] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedLocation: Location?
    @Published var showLocationsList = false
    @Published var serviceAvailable: Bool? = nil
    @Published var isFromProvider: Bool = false
    @Published var selectedProvider: Provider?
    var sessionToken: String = ""

    private var searchTask: DispatchWorkItem?

    func searchLocations(address: String) {
        searchTask?.cancel()

        guard !address.isEmpty else {
            locations = []
            showLocationsList = false
            return
        }

        let task = DispatchWorkItem { [weak self] in
            self?.performSearch(address: address)
        }
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: task)
    }

    private func performSearch(address: String) {
        isLoading = true
        showLocationsList = false
        var params = ["address": address]
        if !sessionToken.isEmpty {
            params["sessionToken"] = sessionToken
        }
        NetworkManager.shared.makeRequest(
            endpoint: "/match/getSuggestions",
            method: HTTPMethod.GET,
            parameters: params
        ) { [weak self] (result: Result<[Location], Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.locations = response
                    self.showLocationsList = !response.isEmpty
                    self.errorMessage = nil
                    if let firstSessionToken = response.first?.sessionToken {
                        self.sessionToken = firstSessionToken
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.locations = []
                    self.showLocationsList = false
                }
            }
        }
    }

    
    func checkServiceAvailability(placeId: String) {
        isLoading = true
        NetworkManager.shared.makeRequest(
            endpoint: "/match/checkServiceAvailability",
            method: HTTPMethod.GET,
            parameters: ["placeId": placeId]
        ) { [weak self] (result: Result<Bool, Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                print(result)
                switch result {
                case .success(let isAvailable):
                    self.serviceAvailable = isAvailable
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.serviceAvailable = nil
                }
            }
        }
    }
}


