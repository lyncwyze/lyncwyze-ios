//
//  EmailSignInView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 07/03/25.
//
import SwiftUI

struct EmailSignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToDashboard = false
    @StateObject private var toastState = ToastState.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private func loginUser() {
        guard !email.isEmpty && !password.isEmpty else {
            alertMessage = NSLocalizedString("please_enter_email_password", comment: "")
            showAlert = true
            return
        }
        
        isLoading = true
        
        AuthenticationService.shared.login(
            identifier: email,
            password: password,
            authType: .email
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    // Clear input fields
                    email = ""
                    password = ""
                    // Navigate to dashboard
                    navigateToDashboard = true
                    
                case .failure(let error):
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            alertMessage = message
                        case .invalidURL:
                            alertMessage = NSLocalizedString("invalid_url", comment: "")
                        case .invalidResponse:
                            alertMessage = NSLocalizedString("invalid_response", comment: "")
                        case .noData:
                            alertMessage = NSLocalizedString("no_data", comment: "")
                        case .decodingError(let decodingError):
                            alertMessage = String(format: NSLocalizedString("error_processing_response", comment: ""), decodingError.localizedDescription)
                            print("🔍 Decoding Error Details: \(decodingError)")
                        case .encodingError:
                            alertMessage = NSLocalizedString("error_processing_encode", comment: "")
                        }
                    } else {
                        alertMessage = NSLocalizedString("unknown_error", comment: "")
                    }
                    showAlert = true
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(NSLocalizedString("sign_in_with_email", comment: ""))
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.bottom, 8)
           
            Text(NSLocalizedString("sign_in_with_registered_email", comment: ""))
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
           
            // Email Field
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(NSLocalizedString("email", comment: ""))
                        .font(.caption)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                }
                HStack(spacing: 8) {
                    TextField(NSLocalizedString("email", comment: ""), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                        .disabled(isLoading)
                }
            }
           
            // Password Field
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(NSLocalizedString("password", comment: ""))
                        .font(.caption)
                        .foregroundColor(.primary)
                    Text("*")
                        .foregroundColor(.red)
                }
                HStack {
                    if isPasswordVisible {
                        TextField(NSLocalizedString("password", comment: ""), text: $password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .foregroundColor(.primary)
                    } else {
                        SecureField(NSLocalizedString("password", comment: ""), text: $password)
                            .textContentType(.password)
                            .foregroundColor(.primary)
                    }
                    
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.bottom, 24)
                .disabled(isLoading)
            }
           
            // Continue Button
            Button {
                loginUser()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(NSLocalizedString("sign_in", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.primaryButton)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
            
            // Or Divider
            HStack {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
                
                Text(NSLocalizedString("or", comment: ""))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
            }
            .padding(.vertical, 24)
            
            // Sign in with Number Button
            NavigationLink(destination: PhoneSigninView()) {
                HStack {
                    Image(systemName: "iphone")
                        .foregroundColor(.primary)
                    Text(NSLocalizedString("sign_in_with_number", comment: ""))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .disabled(isLoading)
       
            Spacer()
            
            // Create Account Link
            HStack {
                Spacer()
                NavigationLink(destination: EmailSignupView()) {
                    HStack {
                        Text(NSLocalizedString("dont_have_account", comment: ""))
                            .foregroundColor(.secondary)
                        Text(NSLocalizedString("lets_create", comment: ""))
                            .foregroundColor(Color.primaryButton)
                    }
                    .padding(.vertical, 8)
                }
                Spacer()
            }
            .padding(.bottom, 16)
            .disabled(isLoading)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .withCustomBackButton()
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(NSLocalizedString("error", comment: "")),
                message: Text(alertMessage),
                dismissButton: .default(Text(NSLocalizedString("ok", comment: "")))
            )
        }
        .fullScreenCover(isPresented: $navigateToDashboard) {
            DashboardView()
        }
        .overlay(
            Group {
                if toastState.isShowing {
                    VStack {
                        Spacer()
                        Text(toastState.message)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: toastState.isShowing)
                }
            }
        )
        .onAppear {
            // Listen for unauthorized access notifications
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("UnauthorizedAccess"),
                object: nil,
                queue: .main) { _ in
                    navigateToDashboard = false
            }
        }
    }
}

struct EmailSignInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmailSignInView()
                .preferredColorScheme(.light)
            
            EmailSignInView()
                .preferredColorScheme(.dark)
        }
    }
}
