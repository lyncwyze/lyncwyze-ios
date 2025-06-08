//
//  PickupTimeSheet.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI

struct PickupTimeSheet: View {
    @Binding var selectedTime: String
    @Binding var isPresented: Bool
    let times: [String]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Text("preferred_pickup_time")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top, 20)
            
            VStack(spacing: 16) {
                ForEach(times, id: \.self) { time in
                    Button(action: {
                        selectedTime = time
                    }) {
                        HStack {
                            Text(time)
                                .foregroundColor(.primary)
                                .font(.body)
                            Spacer()
                            if selectedTime == time {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.primaryButton)
                            } else {
                                Circle()
                                    .strokeBorder(Color(.systemGray3), lineWidth: 1)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(selectedTime == time ? Color(.systemGray6) : Color.clear)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 10)
            
            Button(action: {
                isPresented = false
            }) {
                Text("apply")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.primaryButton)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .frame(width: UIScreen.main.bounds.width - 40)
    }
}

struct PickupTimeSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                PickupTimeSheet(
                    selectedTime: .constant("10 Min"),
                    isPresented: .constant(true),
                    times: ["10 Min", "20 Min", "30 Min", "40 Min"]
                )
            }
            .preferredColorScheme(.light)
            
            ZStack {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                PickupTimeSheet(
                    selectedTime: .constant("10 Min"),
                    isPresented: .constant(true),
                    times: ["10 Min", "20 Min", "30 Min", "40 Min"]
                )
            }
            .preferredColorScheme(.dark)
        }
    }
}
