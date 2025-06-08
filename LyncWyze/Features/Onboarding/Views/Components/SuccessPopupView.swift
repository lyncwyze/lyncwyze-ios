//
//  SuccessPopupView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 09/03/25.
//
import SwiftUI

struct SuccessPopupView: View {
    @Binding var isPresented: Bool
    @Binding var navigateToVerification: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color(red: 76/255, green: 179/255, blue: 149/255))
                            .clipShape(Circle())
                    }
                }
                
                ZStack {
                    Circle()
                        .stroke(Color(red: 76/255, green: 179/255, blue: 149/255), lineWidth: 3)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(red: 76/255, green: 179/255, blue: 149/255))
                }
                
                Text(NSLocalizedString("profile_created_success", comment: ""))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("proceed_to_verification", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    isPresented = false
                    navigateToVerification = true
                }) {
                    Text(NSLocalizedString("proceed", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 76/255, green: 179/255, blue: 149/255))
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 40)
        }
    }
}
