import SwiftUI

struct ProfileView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var profileImage: UIImage?
    @State private var isImageLoading = false
    @State private var showEditProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image Section
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 120, height: 120)
                    
                    if isImageLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    } else if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.secondary)
                            .frame(width: 120, height: 120)
                    }
                }
                .padding(.top, 20)
                
                if let profile = profileManager.userProfile {
                    // Name Section
                    HStack(alignment: .center, spacing: 8) {
                        Text(profile.firstName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(profile.lastName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    
                    // Basic Info Section
                    VStack(spacing: 16) {
                        InfoRow(title: NSLocalizedString("user_id", comment: ""), value: profile.id)
                        InfoRow(title: NSLocalizedString("email", comment: ""), value: profile.email)
                        InfoRow(title: NSLocalizedString("created_date", comment: ""), value: profileManager.formatDateTime(profile.createdDate))
                        InfoRow(title: NSLocalizedString("modified_date", comment: ""), value: profileManager.formatDateTime(profile.modifiedDate))
                        InfoRow(title: NSLocalizedString("mobile_number", comment: ""), value: profile.mobileNumber ?? "")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Divider
                    Divider()
                        .background(Color(.systemGray3))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    // Address Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("address", comment: ""))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        if let address = profile.addresses.first {
                            VStack(spacing: 16) {
                                InfoRow(title: NSLocalizedString("address_line_1", comment: ""), value: address.addressLine1)
                                if let line2 = address.addressLine2 {
                                    InfoRow(title: NSLocalizedString("address_line_2", comment: ""), value: line2)
                                }
                                if let city = address.city {
                                    InfoRow(title: NSLocalizedString("city", comment: ""), value: city)
                                }
                                if let state = address.state {
                                    InfoRow(title: NSLocalizedString("state", comment: ""), value: state)
                                }
                                if let landmark = address.landMark {
                                    InfoRow(title: NSLocalizedString("landmark", comment: ""), value: landmark)
                                }
                                if let pincode = address.pincode {
                                    InfoRow(title: NSLocalizedString("zip_code", comment: ""), value: String(pincode))
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(.systemGray4).opacity(0.3), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Edit Button
                    NavigationLink(destination: ProfileEditView(profile: profile)) {
                        Text(NSLocalizedString("edit_profile", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(NSLocalizedString("profile_title", comment: ""))
        .task {
            await fetchProfile()
        }
        .refreshable {
            await fetchProfile()
        }
        .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: $showError) {
            Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .withCustomBackButton(showBackButton: true)
    }
    
    private func fetchProfile() async {
        isLoading = true
        profileImage = nil // Reset image when fetching new profile
        await profileManager.fetchUserProfile()
        
        if let error = profileManager.error {
            errorMessage = error
            showError = true
            isLoading = false
            return
        }
        
        // Load profile image if available
        if let imagePath = profileManager.userProfile?.image {
            isImageLoading = true
            do {
                let imageData = try await profileManager.loadProfileImage(path: imagePath)
                if let image = UIImage(data: imageData) {
                    profileImage = image
                }
            } catch {
                print("Failed to load profile image: \(error)")
            }
            isImageLoading = false
        }
        
        isLoading = false
    }
}

// Helper view for consistent info row styling
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(width: 150, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ProfileView()
                    .preferredColorScheme(.light)
            }
            
            NavigationView {
                ProfileView()
                    .preferredColorScheme(.dark)
            }
        }
    }
} 
