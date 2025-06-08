//
//  UserStateVM.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//
import SwiftUI

class UserState: ObservableObject {
    static let shared = UserState()
    @Published var userId: String?

    private init() {}

    func setUserData(userId: String) {
        self.userId = userId
    }
    
    func getUserId() -> String? {
        return userId
    }
    
    func clearUserData() {
        userId = nil
    }
}
