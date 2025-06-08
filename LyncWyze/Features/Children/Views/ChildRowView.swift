//
//  ChildRowView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI

struct ChildRowView: View {
    let child: Child
    @ObservedObject var childrenManager: ChildrenManager
    @State private var showingEditSheet = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
            HStack(spacing: 12) {
                if let imageData = child.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )
                } else {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.secondary)
                        )
                }

                Text(String(format: NSLocalizedString("child_name_format", comment: ""), child.firstName, child.lastName))
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
}

struct ChildRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChildRowView(
                child: Child(
                    id: UUID(),
                    firstName: "Abhi",
                    lastName: "Nag",
                    birthDate: Date(),
                    gender: "Male",
                    phoneNumber: "8797878678",
                    imageData: Data(),
                    rideInFront: false,
                    boosterSeatRequired: false
                ),
                childrenManager: ChildrenManager()
            )
            .preferredColorScheme(.light)
            
            ChildRowView(
                child: Child(
                    id: UUID(),
                    firstName: "Abhi",
                    lastName: "Nag",
                    birthDate: Date(),
                    gender: "Male",
                    phoneNumber: "8797878678",
                    imageData: Data(),
                    rideInFront: false,
                    boosterSeatRequired: false
                ),
                childrenManager: ChildrenManager()
            )
            .preferredColorScheme(.dark)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
