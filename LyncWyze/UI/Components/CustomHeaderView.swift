import SwiftUI

/// A reusable custom header view component that provides a consistent navigation header
/// with a back button and optional theme indicator.
struct CustomHeaderView: View {
    // MARK: - Properties
    
    /// Callback closure for back button action
    var onBack: () -> Void
    
    /// Optional title for the header
    var title: String?
    
    /// Flag to show/hide theme indicator
    var showThemeIndicator: Bool
    
    // MARK: - Initialization
    
    init(
        onBack: @escaping () -> Void = { AppUtility.goBack() },
        title: String? = nil,
        showThemeIndicator: Bool = true
    ) {
        self.onBack = onBack
        self.title = title
        self.showThemeIndicator = showThemeIndicator
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 16) {
            backButton
            
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if showThemeIndicator {
                themeIndicator
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
    }
    
    // MARK: - Subviews
    
    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "arrow.left")
                .font(.title2)
                .foregroundColor(.accentColor)
                .accessibility(label: Text("Go back"))
        }
    }
    
    private var themeIndicator: some View {
        Image(systemName: "sun.max")
            .font(.title2)
            .foregroundColor(.yellow)
            .accessibility(label: Text("Theme indicator"))
    }
}

// MARK: - Preview

#Preview("Custom Header") {
    Group {
        CustomHeaderView(
            onBack: { print("Back button tapped") },
            title: "Screen Title"
        )
        
        CustomHeaderView(
            onBack: { print("Back button tapped") },
            showThemeIndicator: false
        )
    }
} 
