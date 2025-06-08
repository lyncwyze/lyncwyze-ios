//
//  SocialSignInButton.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//

import SwiftUI

struct SocialSignInButton: View {
    let label: String
    let image: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: image)
                    .foregroundColor(.black)
                Text(label)
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}
