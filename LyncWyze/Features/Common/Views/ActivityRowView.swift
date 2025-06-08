//
//  ActivityRowView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 18/03/25.
//
import SwiftUI

struct ActivityRow: View {
    let activity: Activity
    let selectedDay: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            // Activity icon or image
            if let imageUrl = activity.image {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .clipShape(Circle())
            } else {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(activity.subType.capitalized)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                if let schedule = activity.schedulePerDay[AppUtility.mapDayToAPIFormat(selectedDay)] {
                    Text("\(schedule.startTime.components(separatedBy: ":").prefix(2).joined(separator: ":"))-\(schedule.endTime.components(separatedBy: ":").prefix(2).joined(separator: ":"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let schedule = activity.schedulePerDay[AppUtility.mapDayToAPIFormat(selectedDay)] {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Pickup Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(schedule.preferredPickupTime) min before")
                        .foregroundColor(Color.primaryButton)
                    Text(
                        schedule.pickupRole
                            .replacingOccurrences(
                                of: "_",
                                with: " "
                            ).capitalized
                    )
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
