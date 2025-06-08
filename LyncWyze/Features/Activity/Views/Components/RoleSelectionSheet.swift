import SwiftUI

enum RideOption: String, CaseIterable {
    case bothDropAndPickup = "Drop and Pickup both"
    case dropOnly = "Drop only"
    case pickupOnly = "Pickup only"
}

struct SelectionButtonStyle: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.primaryButton.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.primaryButton : Color.clear, lineWidth: 1)
            )
    }
}

struct RoleSelectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedRole: String
    @Binding var selectedRideOption: RideOption?
    let onSelection: () -> Void
    
    @State private var tempRole: String = ""
    @State private var tempOption: RideOption?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Select Role")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
            
            // Main Options
            VStack(alignment: .leading, spacing: 16) {
                // Ride Giver Option
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tempRole = tempRole == "GIVER" ? "" : "GIVER"
                        tempOption = nil
                    }
                }) {
                    HStack {
                        Text("Ride Giver")
                            .foregroundColor(.primary)
                        Spacer()
                        if tempRole == "GIVER" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.primaryButton)
                                .imageScale(.large)
                        }
                    }
                    .modifier(SelectionButtonStyle(isSelected: tempRole == "GIVER"))
                }
                
                // Ride Taker Option
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        tempRole = tempRole == "TAKER" ? "" : "TAKER"
                        tempOption = nil
                    }
                }) {
                    HStack {
                        Text("Ride Taker")
                            .foregroundColor(.primary)
                        Spacer()
                        if tempRole == "TAKER" {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.primaryButton)
                                .imageScale(.large)
                        }
                    }
                    .modifier(SelectionButtonStyle(isSelected: tempRole == "TAKER"))
                }
            }
            .padding(.horizontal)
            
            // Sub Options for selected role
            if tempRole == "TAKER" {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Ride Type")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(RideOption.allCases, id: \.self) { option in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    tempOption = tempOption == option ? nil : option
                                }
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if tempOption == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.primaryButton)
                                            .imageScale(.large)
                                    }
                                }
                                .modifier(SelectionButtonStyle(isSelected: tempOption == option))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
                        
            // Apply Button
            Button(action: {
                withAnimation {
                    selectedRole = tempRole
                    selectedRideOption = tempOption
                    if tempRole == "GIVER" {
                        isPresented = false
                    } else if tempRole == "TAKER" && tempOption != nil {
                        onSelection()
                        isPresented = false
                    }
                    // Clear selections after applying
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        tempRole = ""
                        tempOption = nil
                    }
                }
            }) {
                Text("Apply")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(buttonEnabled ? Color.primaryButton : Color.gray.opacity(0.5))
                    )
            }
            .disabled(!buttonEnabled)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .padding()
        .onAppear {
            // Initialize with current selection
            tempRole = selectedRole
            tempOption = selectedRideOption
        }
    }
    
    private var buttonEnabled: Bool {
        tempRole == "GIVER" || (tempRole == "TAKER" && tempOption != nil)
    }
}

// Preview provider
struct RoleSelectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
            RoleSelectionSheet(
                isPresented: .constant(true),
                selectedRole: .constant(""),
                selectedRideOption: .constant(nil),
                onSelection: {}
            )
        }
    }
} 
