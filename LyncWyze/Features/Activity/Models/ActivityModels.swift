//
//  ActivityModels.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI

// struct Activity: Identifiable {
//     let id = UUID()
//     let type: String
//     let name: String
//     let startTime: String
//     let endTime: String
//     let pickupTime: String
//     let icon: String
// }


struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}

struct CustomTimePicker: View {
    @Binding var isPresented: Bool
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    let title: String
    var onApply: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    let hours = Array(1...12)
    let minutes = Array(0...59)
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top)
            
            HStack(spacing: 0) {
                Picker("Hours", selection: $selectedHour) {
                    ForEach(hours, id: \.self) { hour in
                        Text("\(hour)")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 80)
                .clipped()
                
                Picker("Minutes", selection: $selectedMinute) {
                    ForEach(minutes, id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 80)
                .clipped()
                
                Picker("AM/PM", selection: $isAM) {
                    Text("AM")
                        .foregroundColor(.primary)
                        .tag(true)
                    Text("PM")
                        .foregroundColor(.primary)
                        .tag(false)
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 80)
                .clipped()
            }
            .padding(.vertical)
            
            Button(action: {
                onApply()
            }) {
                Text("Apply")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryButton)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding()
    }
}

// Add preview for testing dark mode
struct CustomTimePicker_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomTimePicker(
                isPresented: .constant(true),
                selectedHour: .constant(7),
                selectedMinute: .constant(30),
                isAM: .constant(true),
                title: "Select Time",
                onApply: {}
            )
            .preferredColorScheme(.light)
            .background(Color.black.opacity(0.3))
            
            CustomTimePicker(
                isPresented: .constant(true),
                selectedHour: .constant(7),
                selectedMinute: .constant(30),
                isAM: .constant(true),
                title: "Select Time",
                onApply: {}
            )
            .preferredColorScheme(.dark)
            .background(Color.black.opacity(0.3))
        }
    }
}

struct ActivityResponse: Codable {
    let activityId: String?
}

struct ActivityDetailsViewModel {
    var selectedActivityType: String = "School"
    var selectedSubType: String = "Gymnastics"
}
