import SwiftUI

struct TermsAndPrivacyView: View {
    @State private var isAccepted = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToAddChildren = false
    @State private var navigateToDashboard = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let showBackButton: Bool
    
    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }
    
    private func handleTermsResponse(_ accepted: Bool) {
        isLoading = true
        let parameters = ["acceptTermsAndPrivacyPolicy": String(accepted)]
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/acceptTermsAndPrivacyPolicy",
            method: .POST,
            parameters: parameters
        ) { (result: Result<Bool, Error>) in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let success):
                    if success {
                        // Update user data in UserDefaults
                        if var loginResponse: AuthResponse = getUserDefaultObject(
                            forKey: Constants.UserDefaultsKeys.loggedInDataKey
                        ) {
                            print("Accepted => \(accepted)")
                            loginResponse.acceptTermsAndPrivacyPolicy = accepted
                            loginResponse.profileStatus = nil
                            loginResponse.profileComplete = true
                            saveUserDefaultObject(
                                loginResponse,
                                forKey: Constants.UserDefaultsKeys.loggedInDataKey
                            );
                            
                            if let dataCount: DataCountResponse = getUserDefaultObject(
                                forKey: Constants
                                    .UserDefaultsKeys.UserRequiredDataCount
                            ){
                                if dataCount.child < 1 {
                                    DispatchQueue.main.async {
                                        self.navigateToAddChildren = true
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.navigateToDashboard = true
                                    }
                                }
                            } else {
                                // Ensure we're on the main thread when updating UI state
                                DispatchQueue.main.async {
                                    self.navigateToAddChildren = true
                                }
                            }
                            
                        } else {
                            showError = true
                            errorMessage = "Failed to update user data"
                        }
                    } else {
                        showError = true
                        errorMessage = "Error in accepting! Please try later."
                    }
                case .failure(let error):
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    var body: some View {
            VStack(spacing: 0) {
                // Title
                Text(NSLocalizedString("accept_terms_privacy", comment: ""))
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                
                // Scrollable Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Address Verification
                        PolicySection(
                            title: NSLocalizedString("address_verification", comment: ""),
                            description: NSLocalizedString("address_verification_desc", comment: "")
                        )
                        
                        // Car Insurance Requirement
                        PolicySection(
                            title: NSLocalizedString("car_insurance_requirement", comment: ""),
                            description: NSLocalizedString("car_insurance_requirement_desc", comment: "")
                        )
                        
                        // Driver Liability Disclaimer
                        PolicySection(
                            title: NSLocalizedString("driver_liability_disclaimer", comment: ""),
                            description: NSLocalizedString("driver_liability_disclaimer_desc", comment: "")
                        )
                        
                        // Ride Taker Liability Disclaimer
                        PolicySection(
                            title: NSLocalizedString("ride_taker_liability_disclaimer", comment: ""),
                            description: NSLocalizedString("ride_taker_liability_disclaimer_desc", comment: "")
                        )
                        
                        // Criminal History Affirmation
                        PolicySection(
                            title: NSLocalizedString("criminal_history_affirmation", comment: ""),
                            description: NSLocalizedString("criminal_history_affirmation_desc", comment: "")
                        )
                        
                        // Accuracy of Information Statement
                        PolicySection(
                            title: NSLocalizedString("accuracy_of_information_statement", comment: ""),
                            description: NSLocalizedString("accuracy_of_information_statement_desc", comment: "")
                        )
                    }
                    .padding()
                }
                
                // Bottom Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        handleTermsResponse(false)
                    }) {
                        Text(NSLocalizedString("decline", comment: ""))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray2), lineWidth: 1)
                            )
                    }
                    .disabled(isLoading)
                    
                    
                    Button(action: {
                        handleTermsResponse(true)
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.primaryButton)
                                .cornerRadius(8)
                                .disabled(isLoading)

                        } else {
                            Text(NSLocalizedString("accept", comment: ""))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.primaryButton)
                                .cornerRadius(8)
                                .disabled(isLoading)

                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationBarBackButtonHidden(!showBackButton)
            .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: $showError) {
                Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $navigateToAddChildren) {
                AddChildInfoView(
                    childrenManager: ChildrenManager(),
                    isOnboardingComplete: false,
                    showBackButton: true)
            }
            .fullScreenCover(
                isPresented: $navigateToDashboard
            ){
                DashboardView()
            }
            .withCustomBackButton(showBackButton: showBackButton)
        }
}

// Helper view for policy sections
struct PolicySection: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 20))
                .foregroundColor(.primary)
            
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
}

struct TermsAndPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TermsAndPrivacyView()
                .preferredColorScheme(.light)
            
            TermsAndPrivacyView()
                .preferredColorScheme(.dark)
        }
    }
} 
