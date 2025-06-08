//
//  Utilities.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 13/03/25.
//
import SwiftUI

func validatePhoneNumber(_ phone: String) -> Bool {
    let phoneRegex = "^[0-9]{7,}$"
    let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
    return phonePredicate.evaluate(with: phone)
}


func validateEmail(_ email: String) -> Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    return emailPredicate.evaluate(with: email)
}
