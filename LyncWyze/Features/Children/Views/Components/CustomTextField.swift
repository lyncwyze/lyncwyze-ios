//
//  CustomTextField.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}
