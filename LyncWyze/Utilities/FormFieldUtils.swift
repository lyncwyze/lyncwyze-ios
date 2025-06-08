import SwiftUI

/// Utility functions for form fields
struct FormFieldUtils {
    
    /// Creates a label with an optional red asterisk for mandatory fields
    /// - Parameters:
    ///   - title: The label text
    ///   - isRequired: Whether the field is mandatory (adds red asterisk)
    /// - Returns: A view containing the label with optional red asterisk
    static func createLabel(title: String, isRequired: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            if isRequired {
                Text(" *")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
        }
    }
    
    /// Creates a standard input field with label and optional red asterisk
    /// - Parameters:
    ///   - title: The label text
    ///   - text: Binding to the text field value
    ///   - placeholder: Placeholder text for the text field
    ///   - isRequired: Whether the field is mandatory (adds red asterisk)
    /// - Returns: A view containing the label and text field
    static func createInputField(title: String, text: Binding<String>, placeholder: String, isRequired: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            createLabel(title: title.replacingOccurrences(of: " *", with: ""), isRequired: isRequired)
            
            TextField(placeholder, text: text)
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    /// Creates a standard toggle with label
    /// - Parameters:
    ///   - label: The label text
    ///   - isOn: Binding to the toggle state
    /// - Returns: A view containing the toggle and label
    static func createToggle(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                .foregroundColor(isOn.wrappedValue ? Color.primaryButton : .primary)
            Text(label)
                .foregroundColor(.primary)
            Spacer()
        }
        .onTapGesture { isOn.wrappedValue.toggle() }
    }
} 