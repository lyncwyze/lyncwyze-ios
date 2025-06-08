import SwiftUI
import UIKit

// MARK: - UIViewController Extensions
extension UIViewController {
    /// Shows an alert with a title and message
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - View Extensions
extension View {
    /// Applies a shadow with custom parameters
    func customShadow(
        color: Color = .black.opacity(0.05),
        radius: CGFloat = 2,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    /// Applies the default app corner radius
    func defaultCornerRadius() -> some View {
        self.cornerRadius(10)
    }
    
    /// Applies default padding to the view
    func defaultPadding() -> some View {
        self.padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Custom Back Button
extension View {
    func withCustomBackButton(showBackButton: Bool = true) -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showBackButton {
                        BackButton()
                    }
                }
            }
    }
}

// MARK: - Supporting Views
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.primaryButton)
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(color: colorScheme == .dark ? .clear : Color.gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}
