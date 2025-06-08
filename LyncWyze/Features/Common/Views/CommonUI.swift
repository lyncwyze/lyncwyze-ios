//
//  CommonUI.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 13/03/25.
//
import SwiftUI

struct CustomTextFieldWithIcon: View {
    let placeholder: String
    let text: Binding<String>
    let icon: String
    var isError: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isError ? .red : .gray)
                .frame(width: 24)
            
            TextField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 8)
        }
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isError ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
