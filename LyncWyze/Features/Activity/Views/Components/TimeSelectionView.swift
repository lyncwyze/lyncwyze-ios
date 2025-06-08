//
//  TimeSelectionView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//

import SwiftUI

struct TimeSelectionView: View {
    let days: [String]
    @Binding var timeSlots: [String: TimeSlot]
    @Binding var selectedDayIndex: Int?
    @Binding var selectedRole: String
    @Binding var selectedRideOption: RideOption?
    @Binding var selectedPickupTime: String
    let onDayTap: (String, Bool) -> Void
    
    private func formatStartTime(_ timeSlot: TimeSlot) -> String {
        let hour12 = timeSlot.startHour == 12 ? 12 : timeSlot.startHour % 12
        let period = timeSlot.startIsAM ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, timeSlot.startMinute, period)
    }
    
    private func formatEndTime(_ timeSlot: TimeSlot) -> String {
        let hour12 = timeSlot.endHour == 12 ? 12 : timeSlot.endHour % 12
        let period = timeSlot.endIsAM ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, timeSlot.endMinute, period)
    }
    
    private func getRoleDisplayText() -> String {
        if selectedRole == "GIVER" {
            return "Ride Giver"
        } else if let option = selectedRideOption {
            return option.rawValue
        }
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Time")
                .foregroundColor(.black)
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 8) {
                        // Day Button
                        Button(action: {
                            let hasExistingTimeSlot = timeSlots[day] != nil
                            selectedDayIndex = hasExistingTimeSlot ? nil : days.firstIndex(of: day)
                            onDayTap(day, hasExistingTimeSlot)
                        }) {
                            Text(day)
                                .font(.system(size: 14))
                                .foregroundColor(timeSlots[day] != nil ? .white : .black)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(
                                            timeSlots[day] != nil ? Color.primaryButton : Color(
                                                .systemGray6
                                            )
                                        )
                                )
                        }
                        
                        // Time and Additional Info
                        if let timeSlot = timeSlots[day] {
                            VStack(spacing: 4) {
                                // Start Time
                                Text(formatStartTime(timeSlot))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                // End Time
                                Text(formatEndTime(timeSlot))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                // Role and Option
                                if !selectedRole.isEmpty {
                                    Text(getRoleDisplayText())
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .multilineTextAlignment(.center)
                                }
                                
                                // Pickup Time (only for TAKER role)
                                if selectedRole == "TAKER" && !selectedPickupTime.isEmpty {
                                    Text(selectedPickupTime)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                            }
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 76/255, green: 187/255, blue: 155/255))
                            .frame(width: 45)  // Slightly wider to ensure text fits
                        }
                    }
                }
            }
            .padding(.top, 8)  // Add some space between title and content
        }
    }
}

struct DayTimeSelection {
    var isSelected: Bool = false
    var selectedTime: String = ""
}

struct DayButton: View {
    let day: String
    let isSelected: Bool
    var accentColor: Color = .green
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? accentColor : Color.gray.opacity(0.2))
                )
        }
    }
}
