//
//  CustomToggle.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI

struct CustomToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
                .font(.system(.body))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.primaryButton)
        }
    }
}
