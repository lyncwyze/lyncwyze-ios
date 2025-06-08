import SwiftUI

struct TermsView: View {
    @State private var isAccepted = false
        @State private var isDeclined = false
        @State private var isLoading = false
        @State private var showError = false
        @State private var errorMessage = ""
        @State private var navigateToWelcome = false
        
        func handleTermsResponse(_ accepted: Bool) {
            isLoading = true
            let parameters = ["acceptTermsAndPrivacyPolicy": String(accepted)]
            
            NetworkManager.shared.makeRequest(
                endpoint: "/user/acceptTermsAndPrivacyPolicy",
                method: HTTPMethod.POST,
                parameters: parameters
            ) { (result: Result<EmptyResponse, Error>) in
                isLoading = false
                
                switch result {
                case .success(_):
                    if accepted {
                        navigateToWelcome = true
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                    // Reset states if API call fails
                    isAccepted = false
                    isDeclined = false
                }
            }
        }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Accept Terms & Privacy Policies")
                            .font(.system(size: 28, weight: .semibold))
                            .padding(.bottom, 20)
                        
                        // Address Verification
                        SectionView(
                            title: "Address Verification",
                            content: "Address on my Drivers License is same as my parmenent address."
                        )
                        
                        // Car Insurance Requirement
                        SectionView(
                            title: "Car Insurance Requirement",
                            content: "I carry at least state-required car insurance."
                        )
                        
                        // Driver Liability Disclaimer
                        SectionView(
                            title: "Driver Liability Disclaimer",
                            content: "I understand that, when travelling as the driver, exchange is not responsible for any accidents or harm caused to my car or the passengers in the car including myself."
                        )
                        
                        // Ride Taker Liability Disclaimer
                        SectionView(
                            title: "Ride Taker Liability Disclaimer",
                            content: "I understand that, when travelling as the ride taker, exchange is not responsible for any accidents caused to me during any accident."
                        )
                        
                        // Criminal History Affirmation
                        SectionView(
                            title: "Criminal History Affirmation",
                            content: "I affirm that I have no criminal history including sex offences, DUI etc., and agree to background screening of my profile by the exchange as per their rules."
                        )
                        
                        // Accuracy of Information Statement
                        SectionView(
                            title: "Accuracy of Information Statement",
                            content: "I attest that all information provided by me in the registration process is true and accurate, at the time of registration."
                        )
                        
                        // Accept / Decline Buttons
                        HStack(spacing: 12) {
                                                   Button(action: {
                                                       isDeclined = true
                                                       isAccepted = false
                                                       handleTermsResponse(false)
                                                   }) {
                                                       Text("Decline")
                                                           .frame(maxWidth: .infinity)
                                                           .padding(.vertical, 16)
                                                           .background(isDeclined ? Color.red : Color.white)
                                                           .foregroundColor(isDeclined ? .white : .black)
                                                           .cornerRadius(8)
                                                           .overlay(
                                                               RoundedRectangle(cornerRadius: 8)
                                                                   .stroke(isDeclined ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                                           )
                                                   }
                                                   .disabled(isLoading)
                                                   
                                                   Button(action: {
                                                       isAccepted = true
                                                       isDeclined = false
                                                       handleTermsResponse(true)
                                                   }) {
                                                       Text("Accept")
                                                           .frame(maxWidth: .infinity)
                                                           .padding(.vertical, 16)
                                                           .background(isAccepted ? Color.green : Color(.systemGray5))
                                                           .foregroundColor(isAccepted ? .white : .black)
                                                           .cornerRadius(8)
                                                   }
                                                   .disabled(isLoading)
                                               }
                                               .padding(.top, 32)
                                               
                                               if isLoading {
                                                   ProgressView()
                                                       .frame(maxWidth: .infinity)
                                               }
                                           }
                                           .padding(24)
                                       }
                                       .navigationTitle("")
                                       .navigationBarTitleDisplayMode(.inline)
                                       .toolbar {
                                           ToolbarItem(placement: .navigationBarLeading) {
                                               // Empty toolbar item
                                           }
                                       }
                                       .navigationDestination(isPresented: $navigateToWelcome) {
                                           WelcomeView()
                                       }
                                       .alert("Error", isPresented: $showError) {
                                           Button("OK") { showError = false }
                                       } message: {
                                           Text(errorMessage)
                                       }
                                   }
                               } else {
                                   // Fallback on earlier versions
                               }
                           }
                       }

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Illustration
            Spacer()
            Image("carpool 1") // Make sure to add this image to your assets
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .padding(.top, 40)
            
            // Welcome Text
            Text("Welcome John to PeerEaze")
                .font(.system(size: 28, weight: .bold))
            
            Text("Great News!!")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 75/255, green: 181/255, blue: 151/255))
            
            Text("Your background verification is complete.")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Start Journey Button with Navigation
            NavigationLink(destination: DashboardView()) {
                Text("Start Your Journey")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 75/255, green: 181/255, blue: 151/255))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct SectionView: View {
    var title: String
    var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            Text(content)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .lineSpacing(2)
        }
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView()
    }
}
