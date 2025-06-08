//
//  CustomTextFieldStyle.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 09/03/25.
//
import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(red: 247/255, green: 248/255, blue: 249/255))
            .cornerRadius(8)
    }
}
