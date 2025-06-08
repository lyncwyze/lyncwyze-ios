//
//  ChildListItemView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 18/03/25.
//
import SwiftUI

struct ChildListItemView: View {
    let child: Child
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            if let imageData = child.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(.systemGray3))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("child_name", comment: ""), child.firstName, child.lastName))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(child.gender)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}
