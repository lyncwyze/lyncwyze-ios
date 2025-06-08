//
//  PasswordRequirementView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 09/03/25.
//
import SwiftUI

struct PasswordRequirementView: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: isValid ? "checkmark" : "xmark")
                .foregroundColor(isValid ? .green : .red)
            Text(text)
                .foregroundColor(isValid ? .green : .red)
        }
    }
}
