import SwiftUI

struct RideUserCard: View {
    // MARK: - Properties
    let personImage: String
    let imagePath: String?
    let name: String
    let successRecord: String
    let showCommunity: Bool
    let communityText: String
    let communityImage: String
    let distance: String
    let fromLocation: String
    let toLocation: String
    let showFavorite: Bool
    let onCallTapped: () -> Void
    let onMessageTapped: () -> Void
    let onImageLoaded: ((UIImage?) -> Void)?
    
    @State private var loadedImage: UIImage?
    @State private var isLoadingImage = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Init
    init(
        personImage: String = "person.circle.fill",
        imagePath: String? = nil,
        name: String,
        successRecord: String,
        showCommunity: Bool = false,
        communityText: String = NSLocalizedString("same_community", comment: ""),
        communityImage: String = "person.circle.fill",
        distance: String,
        fromLocation: String,
        toLocation: String,
        showFavorite: Bool = false,
        onCallTapped: @escaping () -> Void,
        onMessageTapped: @escaping () -> Void,
        onImageLoaded: ((UIImage?) -> Void)? = nil
    ) {
        self.personImage = personImage
        self.imagePath = imagePath
        self.name = name
        self.successRecord = successRecord
        self.showCommunity = showCommunity
        self.communityText = communityText
        self.communityImage = communityImage
        self.distance = distance
        self.fromLocation = fromLocation
        self.toLocation = toLocation
        self.showFavorite = showFavorite
        self.onCallTapped = onCallTapped
        self.onMessageTapped = onMessageTapped
        self.onImageLoaded = onImageLoaded
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 8) {
            // Top Section: Profile, Name, and Actions
            HStack {
                // Profile Image
                ZStack {
                    if isLoadingImage {
                        ProgressView()
                            .frame(width: 60, height: 60)
                    } else if let image = loadedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: personImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .foregroundColor(.secondary)
                    }
                }
                
                // Name and Success Record
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(successRecord)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if showCommunity {
                        HStack {
                            Text(communityText)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Image(communityImage)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // Call and Message Actions
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Button(action: onCallTapped) {
                            Image(systemName: "phone.circle")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(Color.primaryButton)
                        }
                        
                        Button(action: onMessageTapped) {
                            Image(systemName: "message.circle")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(Color.primaryButton)
                        }
                    }
                    .padding(4)
                    
                    Text(NSLocalizedString("distance", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(distance)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                }
            }
            
            // Bottom Section: Location
            HStack {
                VStack(spacing: 4) {
                    // Location Icons and Line
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(Color.primaryButton)
                        Line()
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(.secondary)
                            .frame(height: 2)
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    
                    // Location Labels
                    HStack {
                        Text(fromLocation)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        Text(toLocation)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                if showFavorite {
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.yellow)
                        .padding(.leading)
                }
            }
        }
        .padding(8)
        .background(colorScheme == .light ? .white : Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color(.systemGray4).opacity(colorScheme == .light ? 0.5 : 0.2), radius: 2)
        .onAppear {
            loadImageIfNeeded()
        }
    }
    
    private func loadImageIfNeeded() {
        guard let imagePath = imagePath, loadedImage == nil else { return }
        
        isLoadingImage = true
        Task {
            do {
                let imageData = try await NetworkManager.shared.loadImageAsync(path: imagePath)
                if let image = UIImage(data: imageData) {
                    await MainActor.run {
                        self.loadedImage = image
                        self.isLoadingImage = false
                        self.onImageLoaded?(image)
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
                await MainActor.run {
                    self.isLoadingImage = false
                    self.onImageLoaded?(nil)
                }
            }
        }
    }
}

// MARK: - Line Shape
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - Preview
struct RideUserCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RideUserCard(
                name: "John Doe",
                successRecord: String(format: NSLocalizedString("successfully_completed_rides", comment: ""), 2),
                distance: "4 miles",
                fromLocation: "Your Location",
                toLocation: "Activity Location",
                onCallTapped: {},
                onMessageTapped: {}
            )
            .padding()
            .previewDisplayName("Light Mode")
            
            RideUserCard(
                name: "John Doe",
                successRecord: String(format: NSLocalizedString("successfully_completed_rides", comment: ""), 2),
                distance: "4 miles",
                fromLocation: "Your Location",
                toLocation: "Activity Location",
                onCallTapped: {},
                onMessageTapped: {}
            )
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .previewLayout(.sizeThatFits)
    }
} 
