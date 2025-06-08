//
//  OTPTextField.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//

import SwiftUI

struct OTPTextField: View {
    @Binding var text: String
    var isFocused: Bool
    var onCommit: () -> Void

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 70, height: 70)
            .background(
                Circle()
                    .fill(text.isEmpty ? Color(.systemGray6) : Color(red: 76/255, green: 187/255, blue: 149/255))
            )
            .foregroundColor(.white)
            .font(.system(size: 24, weight: .bold))
            .onChange(of: text) { newValue in
                text = newValue.filter { $0.isNumber }
                if text.count > 1 {
                    text = String(text.suffix(1))
                }
                if !text.isEmpty {
                    onCommit()
                }
            }
    }
}
