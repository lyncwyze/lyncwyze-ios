//
//  BackgroundVerificationView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 09/03/25.
//

import SwiftUI

struct BackgroundVerificationView: View {
    @State private var ssn = ""
    @State private var licenseNumber = ""
    @State private var state = ""
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var homeAddress = ""
    @State private var navigateToPhoto = false
    @State private var isLoading = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        return formatter
    }()
    
    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private func submitBackgroundVerification() {
        isLoading = true
        
        let request = BackgroundVerificationRequest(
            ssn: ssn,
            licenseNumber: licenseNumber,
            licenseState: state,
            licenseExpiredDate: apiDateFormatter.string(from: selectedDate),
            address: Address(
                addressLine1: homeAddress,
                addressLine2: "",
                landMark: "",
                pincode: nil,
                state: "",
                city: "",
                location: GeoLocation(
                    x: 77.020608,
                    y: 29.1354856,
                    coordinates: [77.020608, 29.1354856],
                    type: "Point"
                )
            )
        )
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            NetworkManager.shared.makeRequest(
                endpoint: "/user/backgroundVerification",
                method: .POST,
                body: jsonData
            ) { (result: Result<EmptyResponse, Error>) in
                isLoading = false
                
                switch result {
                case .success:
                    navigateToPhoto = true
                case .failure(let error):
                    print("Error submitting background verification: \(error)")
                    // Handle error appropriately
                }
            }
        } catch {
            isLoading = false
            print("Error encoding request: \(error)")
            // Handle error appropriately
        }
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("background_verification_title", comment: ""))
                    .font(.title)
                    .fontWeight(.semibold)
                
                Group {
                    HStack {
                        TextField(NSLocalizedString("ssn_last_4", comment: ""), text: $ssn)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        Button(action: {
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(NSLocalizedString("driver_license_photo", comment: ""))
                        .font(.headline)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(NSLocalizedString("or", comment: ""))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 16) {
                        TextField(NSLocalizedString("license_state", comment: ""), text: $state)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        TextField(NSLocalizedString("license_number", comment: ""), text: $licenseNumber)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("expiration_date", comment: ""))
                            .foregroundColor(.gray)
                        Button(action: {
                            showDatePicker = true
                        }) {
                            TextField("", text: .constant(dateFormatter.string(from: selectedDate)))
                                .textFieldStyle(CustomTextFieldStyle())
                                .disabled(true)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("address", comment: ""))
                            .foregroundColor(.gray)
                        HStack {
                            TextField(NSLocalizedString("select_home_address", comment: ""), text: $homeAddress)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            Button(action: {
                                // Handle location selection
                            }) {
                                Image(systemName: "location.circle")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    submitBackgroundVerification()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(NSLocalizedString("continue", comment: ""))
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primaryButton)
                .cornerRadius(8)
                .disabled(isLoading)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color(red: 247/255, green: 248/255, blue: 249/255))
            
            if showDatePicker {
                DatePickerPopup(isPresented: $showDatePicker, selectedDate: $selectedDate)
            }
            
            NavigationLink(isActive: $navigateToPhoto) {
                ProfilePhotoView()
            } label: {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct BackgroundVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundVerificationView()
    }
}
