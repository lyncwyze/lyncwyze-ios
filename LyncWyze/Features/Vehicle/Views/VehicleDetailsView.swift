//
//  VehicleDetailsView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI

struct VehicleDetailsView: View {
    @StateObject private var vehicleManager: VehicleManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var onDismiss: (() -> Void)?
    
    @State private var make = ""
    @State private var model = ""
    @State private var bodyStyle = "Sedan"
    @State private var color = ""
    @State private var licensePlate = ""
    @State private var alias = ""
    @State private var isPrimary = false
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var seatingCapacity = 4
    @State private var navigateToSummary = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEditing: Bool
    @State private var editingVehicleId: String?
    @State private var showDeleteAlert = false
    @State private var navigateToAppLanding = false
    let showBackButton: Bool
    let isOnboardingComplete: Bool
    @State private var navigateToEmergencyContact: Bool = false
    
    // Initialize for Add Mode
    init(showBackButton: Bool = true, isOnboardingComplete: Bool = true, onDismiss: (() -> Void)? = nil) {
        _vehicleManager = StateObject(wrappedValue: VehicleManager())
        _isEditing = State(initialValue: false)
        self.showBackButton = showBackButton
        self.isOnboardingComplete = isOnboardingComplete
        self.onDismiss = onDismiss
    }
    
    // Initialize for Edit Mode
    init(vehicleManager: VehicleManager, vehicle: Vehicle) {
        _vehicleManager = StateObject(wrappedValue: vehicleManager)
        _isEditing = State(initialValue: true)
        _editingVehicleId = State(initialValue: vehicle.id)
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _bodyStyle = State(initialValue: vehicle.bodyStyle)
        _color = State(initialValue: vehicle.bodyColor)
        _licensePlate = State(initialValue: vehicle.licensePlate)
        _alias = State(initialValue: vehicle.alias ?? "")
        _isPrimary = State(initialValue: vehicle.primary)
        _year = State(initialValue: vehicle.year)
        _seatingCapacity = State(initialValue: vehicle.seatingCapacity)
        self.showBackButton = true
        self.isOnboardingComplete = true
        self.onDismiss = nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    createInputField(title: NSLocalizedString("make_label", comment: ""), text: $make, placeholder: NSLocalizedString("enter_make_placeholder", comment: ""), isRequired: true)
                    createInputField(title: NSLocalizedString("model_label", comment: ""), text: $model, placeholder: NSLocalizedString("enter_model_placeholder", comment: ""), isRequired: true)
                    createBodyStylePicker()
                    createInputField(title: NSLocalizedString("body_color_label", comment: ""), text: $color, placeholder: NSLocalizedString("enter_body_color_placeholder", comment: ""), isRequired: true)
                    createInputField(title: NSLocalizedString("license_plate_label", comment: ""), text: $licensePlate, placeholder: NSLocalizedString("enter_license_plate_placeholder", comment: ""), isRequired: true)
                    createInputField(title: NSLocalizedString("alias_label", comment: ""), text: $alias, placeholder: NSLocalizedString("enter_alias_placeholder", comment: ""))
                    createToggle(label: NSLocalizedString("primary_vehicle_toggle", comment: ""), isOn: $isPrimary)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Delete Button (only in edit mode)
                    if isEditing {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text(NSLocalizedString("delete_vehicle_button", comment: ""))
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                        .disabled(isLoading)
                    }
                    
                    // Save/Update Button
                    Button {
                        saveVehicle()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(
                                    isOnboardingComplete ? (isEditing ? NSLocalizedString("update_button", comment: "") : NSLocalizedString("save_button", comment: "")) : NSLocalizedString("next_emergency_contact", comment: "")
                                )
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryButton)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isLoading)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: $showError) {
            Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert(NSLocalizedString("delete_vehicle_alert_title", comment: ""), isPresented: $showDeleteAlert) {
            Button(NSLocalizedString("cancel_button", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("delete_button", comment: ""), role: .destructive) {
                Task {
                    if let id = editingVehicleId {
                        isLoading = true
                        let success = await vehicleManager.deleteVehicle(vehicleId: id)
                        isLoading = false
                        if success {
                            dismiss()
                        } else {
                            errorMessage = vehicleManager.error ?? NSLocalizedString("failed_to_delete_vehicle", comment: "")
                            showError = true
                        }
                    }
                }
            }
        } message: {
            Text(NSLocalizedString("delete_vehicle_alert_message", comment: ""))
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            VehicleDetailsSummaryView(vehicleManager: vehicleManager)
        }
        .navigationDestination(
            isPresented: $navigateToEmergencyContact) {
                HandleEmergencyContactView(
                    contactsManager: EmergencyContactsManager(),
                    contact: nil,
                    isOnboardingComplete: false,
                    onDismiss: {})
            }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isOnboardingComplete {
                    Text(isEditing ? NSLocalizedString("edit_vehicle_title", comment: "") : NSLocalizedString("add_vehicle_title", comment: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.leading, 16)
                } else {
                    Text(NSLocalizedString("vehicle_details_title", comment: ""))
                        .font(.title)
                        .foregroundColor(.primary)
                        .bold()
                }
            }
            
            if !isOnboardingComplete {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        logout()
                        navigateToAppLanding = true
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .withCustomBackButton(showBackButton: showBackButton)
        .fullScreenCover(isPresented: $navigateToAppLanding) {
            AppLanding()
                .navigationBarBackButtonHidden(true)
        }
        .task {
            if !isEditing {
                await vehicleManager.getVehicles()
            }
        }
    }
    
    private func saveVehicle() {
        guard !make.isEmpty, !model.isEmpty, !color.isEmpty, !licensePlate.isEmpty else {
            errorMessage = NSLocalizedString("required_fields_error", comment: "")
            showError = true
            return
        }
        
        isLoading = true
        
        let vehicle = Vehicle(
            id: editingVehicleId,
            make: make,
            model: model,
            bodyStyle: bodyStyle,
            bodyColor: color,
            licensePlate: licensePlate,
            alias: alias,
            year: year,
            seatingCapacity: seatingCapacity,
            primary: isPrimary
        )
        
        Task {
            let success = if isEditing {
                await vehicleManager.updateVehicle(vehicle)
            } else {
                await vehicleManager.addVehicle(vehicle)
            }
            
            if success {
                if isOnboardingComplete == false {
                    if let dataCount: DataCountResponse = getUserDefaultObject(
                        forKey: Constants.UserDefaultsKeys.UserRequiredDataCount
                    ) {
                        if dataCount.emergencyContact < 1 {
                            navigateToEmergencyContact = true
                        } else {
                            onDismiss?()
                            dismiss()
                            resetForm()
                        }
                    } else{
                        navigateToEmergencyContact = true
                    }
                } else {
                    onDismiss?()
                    dismiss()
                    resetForm()
                }
            } else {
                errorMessage = vehicleManager.error ?? NSLocalizedString("error_occurred", comment: "")
                showError = true
            }
            isLoading = false
        }
    }
    
    private func resetForm() {
        make = ""
        model = ""
        bodyStyle = "Sedan"
        color = ""
        licensePlate = ""
        alias = ""
        isPrimary = false
        year = Calendar.current.component(.year, from: Date())
        seatingCapacity = 4
    }
    
    private func createInputField(title: String, text: Binding<String>, placeholder: String, isRequired: Bool = false) -> some View {
        return FormFieldUtils.createInputField(title: title, text: text, placeholder: placeholder, isRequired: isRequired)
    }
    
    private func createBodyStylePicker() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FormFieldUtils.createLabel(title: NSLocalizedString("body_style_label", comment: ""), isRequired: true)
            VStack(spacing: 12) {
                ForEach(["SUV/Minivan", "Sedan", "Truck"], id: \.self) { style in
                    HStack {
                        ZStack {
                            Circle()
                                .stroke(
                                    bodyStyle
                                        .lowercased() == style
                                        .lowercased() ? Color.primaryButton : Color(.systemGray3),
                                    lineWidth: 2
                                )
                                .frame(width: 20, height: 20)
                            
                            if bodyStyle.lowercased() == style.lowercased() {
                                Circle()
                                    .fill(Color.primaryButton)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        Text(style)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .onTapGesture { bodyStyle = style }
                }
            }
        }
    }
    
    private func createToggle(label: String, isOn: Binding<Bool>) -> some View {
        return FormFieldUtils.createToggle(label: label, isOn: isOn)
    }
}

struct VehicleDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VehicleDetailsView()
                .preferredColorScheme(.light)
            
            VehicleDetailsView()
                .preferredColorScheme(.dark)
        }
    }
}
