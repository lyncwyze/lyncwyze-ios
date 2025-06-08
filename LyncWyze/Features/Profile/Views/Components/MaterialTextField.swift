import SwiftUI

struct MaterialTextField: View {
    let placeholder: String
    @Binding var text: String
    var error: String?
    var textAlignment: TextAlignment = .leading
    var fontSize: CGFloat = 16
    var isBold: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $text)
                .textFieldStyle(MaterialTextFieldStyle())
                .font(.system(size: fontSize, weight: isBold ? .bold : .regular))
                .multilineTextAlignment(textAlignment)
                .submitLabel(.done)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            if let error = error, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }
}

struct MaterialTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(.primary)
            .tint(Color.primaryButton)
    }
}

struct MaterialTextField_Previews: PreviewProvider {
    @State static var text1 = ""
    @State static var text2 = ""
    
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                MaterialTextField(
                    placeholder: "Test Field",
                    text: .init(
                        get: { text1 },
                        set: { text1 = $0 }
                    ),
                    error: nil
                )
                MaterialTextField(
                    placeholder: "With Error",
                    text: .init(
                        get: { text2 },
                        set: { text2 = $0 }
                    ),
                    error: "This is an error"
                )
            }
            .padding()
            .previewDisplayName("Light Mode")
            
            VStack(spacing: 20) {
                MaterialTextField(
                    placeholder: "Test Field",
                    text: .init(
                        get: { text1 },
                        set: { text1 = $0 }
                    ),
                    error: nil
                )
                MaterialTextField(
                    placeholder: "With Error",
                    text: .init(
                        get: { text2 },
                        set: { text2 = $0 }
                    ),
                    error: "This is an error"
                )
            }
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
} 