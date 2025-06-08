import SwiftUI
import PhotosUI

struct ProfilePhotoVerification_Step3: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isCameraPresented = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingImageSourceDialog = false
    @State private var isPhotoSelected = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToTermsPolicyStep4 = false
    @State private var navigateToAppLanding = false
    @StateObject private var userState = UserState.shared
    let showBackButton: Bool
    
    init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }
    
    private func uploadProfileImage() {
        guard let image = selectedImage,
              let imageData = compressImage(image, maxSizeInMB: 0.5) else {
            showError = true
            errorMessage = "Please select an image under 2MB"
            return
        }
        
        isLoading = true
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var requestData = Data()
        
        // Add image data
        requestData.append("--\(boundary)\r\n".data(using: .utf8)!)
        requestData.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        requestData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        requestData.append(imageData)
        requestData.append("\r\n".data(using: .utf8)!)
        requestData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        NetworkManager.shared.makeRequest(
            endpoint: "/user/addProfileImage",
            method: .POST,
            headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)"],
            body: requestData
        ) { (result: Result<Data, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let data):
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("✅ Profile image uploaded successfully")
                        print("📥 Response: \(responseString)")
                        
                        // Update profile status
                        if var loginResponse: AuthResponse? = getUserDefaultObject(
                            forKey: Constants.UserDefaultsKeys.loggedInDataKey
                        ) {
                            loginResponse?.profileStatus = ProfileStatus.policy
                            saveUserDefaultObject(
                                loginResponse,
                                forKey: Constants.UserDefaultsKeys.loggedInDataKey
                            )
                            self.navigateToTermsPolicyStep4 = true
                        }
                    } else {
                        self.showError = true
                        self.errorMessage = "Failed to process server response"
                    }
                    
                case .failure(let error):
                    self.showError = true
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    var body: some View {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title with Logout Button
                        HStack {
                            Text(NSLocalizedString("take_profile_photo", comment: ""))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                logout()
                                navigateToAppLanding = true
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                        }

                        // Subtitle
                        Text(NSLocalizedString("profile_photo_help", comment: ""))
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        // Guidelines
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("photo_guideline_1", comment: ""))
                            Text(NSLocalizedString("photo_guideline_2", comment: ""))
                            Text(NSLocalizedString("photo_guideline_3", comment: ""))
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 14)
                        
                        // Profile Image Container
                        HStack {
                            Spacer()
                            // Profile Image
                            ZStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 195, height: 195)
                                        .clipShape(Circle())
                                } else {
                                    Image("UserImage")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 195, height: 195)
                                }
                                
                                // Camera Button
                                Button(action: {
                                    showingImageSourceDialog = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                                .offset(x: 70, y: 70)
                            }
                            .frame(width: 195, height: 195)
                            .onTapGesture {
                                showingImageSourceDialog = true
                            }
                            Spacer()
                        }
                        .padding(.vertical, 24)
                        
                        // Verification Message
                        Text(NSLocalizedString("photo_verification_message", comment: ""))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        // Continue Button
                        Button(action: {
                            uploadProfileImage()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(isPhotoSelected ? Color.primaryButton : Color.gray)
                                    .cornerRadius(8)
                                    .disabled(!isPhotoSelected || isLoading)
                                    .padding(.top, 16)

                            } else {
                                Text(NSLocalizedString("next_accept_policies", comment: ""))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(isPhotoSelected ? Color.primaryButton : Color.gray)
                                    .cornerRadius(8)
                                    .disabled(!isPhotoSelected || isLoading)
                                    .padding(.top, 16)

                            }
                        }
                    }
                    .padding()
                }
            }
            .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: $showError) {
                Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .navigationDestination(isPresented: $navigateToTermsPolicyStep4) {
                TermsAndPrivacyView(showBackButton: true)
            }
            .fullScreenCover(isPresented: $navigateToAppLanding) {
                AppLanding()
                    .navigationBarBackButtonHidden(true)
            }
            .withCustomBackButton(showBackButton: showBackButton)
            .confirmationDialog(NSLocalizedString("choose_image_source", comment: ""), isPresented: $showingImageSourceDialog) {
                Button(NSLocalizedString("camera", comment: "")) {
                    sourceType = .camera
                    isCameraPresented = true
                }
                Button(NSLocalizedString("photo_library", comment: "")) {
                    sourceType = .photoLibrary
                    isImagePickerPresented = true
                }
                Button(NSLocalizedString("cancel_button", comment: ""), role: .cancel) {}
            }
            .sheet(isPresented: $isImagePickerPresented) {
                PhotoImagePicker(image: $selectedImage, sourceType: sourceType, isPhotoSelected: $isPhotoSelected)
            }
            .sheet(isPresented: $isCameraPresented) {
                PhotoImagePicker(image: $selectedImage, sourceType: sourceType, isPhotoSelected: $isPhotoSelected)
            }
            .onChange(of: selectedImage) { newImage in
                isPhotoSelected = newImage != nil
            }
    }
}

// PhotoImagePicker struct for handling camera and photo library
struct PhotoImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Binding var isPhotoSelected: Bool
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoImagePicker
        
        init(_ parent: PhotoImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.isPhotoSelected = true
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.image = nil
            parent.isPhotoSelected = false
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ProfilePhotoVerification_Step3(showBackButton: false)
}
