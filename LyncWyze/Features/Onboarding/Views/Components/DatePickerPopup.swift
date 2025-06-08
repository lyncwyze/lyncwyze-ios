//
//  DatePickerPopup.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 09/03/25.
//
import SwiftUI

struct DatePickerPopup: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text(NSLocalizedString("expiration_date", comment: ""))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text(NSLocalizedString("apply", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 76/255, green: 179/255, blue: 149/255))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
    }
}
