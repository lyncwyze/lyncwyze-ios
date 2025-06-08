import SwiftUI
import AVFoundation

struct ProfilePhotoView: View {
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var showOptions = false
    @State private var capturedImage: UIImage?
    @State private var navigateToTerms = false
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @StateObject private var userState = UserState.shared
    
    private func uploadProfileImage() {
        guard let image = capturedImage,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let userId = userState.userId else {
            showError = true
            errorMessage = "No image selected or user ID not found"
            return
        }
        
        let parameters = ["userId": userId]
        

        NetworkManager.shared.makeRequest(
            endpoint: "/user/addProfileImage",
            method: .POST,
            body: imageData,
            parameters: parameters
        ) { (result: Result<String, Error>) in
            DispatchQueue.main.async {
                isUploading = false
                
                switch result {
                case .success:
                    // Navigate to terms view on successful upload
                    navigateToTerms = true
                case .failure(let error):
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Take your profile photo")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your profile photo helps people recognize you.")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    InstructionRow(number: 1, text: "Face the camera directly with your eyes and mouth clearly visible")
                    InstructionRow(number: 2, text: "Make sure the photo is well lit, free of glare, and in focus")
                    InstructionRow(number: 3, text: "No photos of a photo, filters, or alterations")
                }
                .padding(.horizontal)
                
                // Image preview
                ZStack {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 200)
                    }
                    
                    Button("ZOOM") {
                        // Handle zoom action
                    }
                    .foregroundColor(.gray)
                    .position(x: 170, y: 170)
                }
                
                Text("Our team will verify that your photo is of a live person, taken in real-time and we will use the photo to check for duplication across other accounts.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                VStack(spacing: 12) {
                    Button(action: {
                        showOptions = true
                    }) {
                        Text("Take Photo")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: TermsView().navigationBarHidden(true), isActive: $navigateToTerms) {
                        Button(action: {
                            // If there's no need for upload, just navigate
                            navigateToTerms = true
                            
                            // If you still want to keep the upload functionality:
                            // isUploading = true
                            // uploadProfileImage()
                        }) {
                            Text(isUploading ? "Uploading..." : "Continue")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(capturedImage != nil ? Color.green : Color.gray)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(capturedImage == nil || isUploading)
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $capturedImage)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $capturedImage, sourceType: .photoLibrary)
            }
            .confirmationDialog("Choose Photo Option", isPresented: $showOptions, titleVisibility: .visible) {
                Button("Take Photo") {
                    showCamera = true
                }
                Button("Choose from Library") {
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .foregroundColor(.gray)
            Text(text)
                .foregroundColor(.gray)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
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
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
//            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
//            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
struct ProfilePhotoView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePhotoView()
    }
}
