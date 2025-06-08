//
//  VehicleDetailsSummaryView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI

struct EditVehicleSheet: View {
    @ObservedObject var vehicleManager: VehicleManager
    let vehicle: Vehicle
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var make: String
    @State private var model: String
    @State private var bodyStyle: String
    @State private var color: String
    @State private var licensePlate: String
    @State private var alias: String
    @State private var isPrimary: Bool
    @State private var year: Int
    @State private var seatingCapacity: Int
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(vehicleManager: VehicleManager, vehicle: Vehicle) {
        self.vehicleManager = vehicleManager
        self.vehicle = vehicle
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _bodyStyle = State(initialValue: vehicle.bodyStyle)
        _color = State(initialValue: vehicle.bodyColor)
        _licensePlate = State(initialValue: vehicle.licensePlate)
        _alias = State(initialValue: vehicle.alias ?? "")
        _isPrimary = State(initialValue: vehicle.primary)
        _year = State(initialValue: vehicle.year)
        _seatingCapacity = State(initialValue: vehicle.seatingCapacity)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    createInputField(title: NSLocalizedString("make_label", comment: ""), text: $make, placeholder: NSLocalizedString("enter_make_placeholder", comment: ""))
                    createInputField(title: NSLocalizedString("model_label", comment: ""), text: $model, placeholder: NSLocalizedString("enter_model_placeholder", comment: ""))
                    createBodyStylePicker()
                    createInputField(title: NSLocalizedString("body_color_label", comment: ""), text: $color, placeholder: NSLocalizedString("enter_body_color_placeholder", comment: ""))
                    createInputField(title: NSLocalizedString("license_plate_label", comment: ""), text: $licensePlate, placeholder: NSLocalizedString("enter_license_plate_placeholder", comment: ""))
                    createInputField(title: NSLocalizedString("alias_label", comment: ""), text: $alias, placeholder: NSLocalizedString("enter_alias_placeholder", comment: ""))
                    createToggle(label: NSLocalizedString("primary_vehicle_toggle", comment: ""), isOn: $isPrimary)
                    
                    // Year Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("year_label", comment: ""))
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        Picker("Year", selection: $year) {
                            ForEach((2000...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                                Text("\(year)").tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Seating Capacity
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("seating_capacity_label", comment: ""))
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        Picker("Seating Capacity", selection: $seatingCapacity) {
                            ForEach(2...8, id: \.self) { capacity in
                                Text(String(format: NSLocalizedString("seats_label", comment: ""), capacity)).tag(capacity)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button(action: updateVehicle) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Update")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primaryButton)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(isLoading)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle(NSLocalizedString("edit_vehicle_title", comment: ""))
            .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: $showError) {
                Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateVehicle() {
        guard !make.isEmpty, !model.isEmpty, !color.isEmpty, !licensePlate.isEmpty else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        isLoading = true
        
        let updatedVehicle = Vehicle(
            id: vehicle.id,
            make: make,
            model: model,
            bodyStyle: bodyStyle,
            bodyColor: color,
            licensePlate: licensePlate,
            alias: alias.isEmpty ? "\(make) \(model)" : alias,
            year: year,
            seatingCapacity: seatingCapacity,
            primary: isPrimary
        )
        
        Task {
            let success = await vehicleManager.updateVehicle(updatedVehicle)
            if success {
                dismiss()
            } else {
                errorMessage = vehicleManager.error ?? NSLocalizedString("failed_to_update_vehicle", comment: "")
                showError = true
            }
            isLoading = false
        }
    }
    
    private func createInputField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            TextField(placeholder, text: text)
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private func createBodyStylePicker() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("body_style_label", comment: ""))
                .font(.system(size: 16))
                .foregroundColor(.primary)
            VStack(spacing: 12) {
                ForEach(["SUV/Minivan", "Sedan", "Truck"], id: \.self) { style in
                    HStack {
                        Image(
                            systemName: bodyStyle
                                .lowercased() == style
                                .lowercased() ? "circle.fill" : "circle"
                        )
                        .foregroundColor(bodyStyle.lowercased() == style.lowercased() ? Color.primaryButton : .secondary)
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

struct VehicleDetailsSummaryView: View {
    @ObservedObject var vehicleManager: VehicleManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showDeleteAlert = false
    @State private var vehicleToDelete: Vehicle?
    @State private var navigateToAddVehicle = false
    
    var body: some View {
        VStack(spacing: 0) {
            if vehicleManager.isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                Spacer()
            } else if vehicleManager.vehicles.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "car")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text(NSLocalizedString("no_vehicle_added", comment: ""))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(NSLocalizedString("add_vehicle_message", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(vehicleManager.vehicles) { vehicle in
                            NavigationLink(destination: VehicleDetailsView(vehicleManager: vehicleManager, vehicle: vehicle)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "car.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 24))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(vehicle.make) \(vehicle.model)")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Text(vehicle.licensePlate)
                                                .foregroundColor(.secondary)
                                            
                                            Text("\(vehicle.bodyStyle) - \(vehicle.bodyColor)")
                                                .foregroundColor(.secondary)
                                            
                                            if vehicle.primary {
                                                Text(NSLocalizedString("primary_vehicle_label", comment: ""))
                                                    .foregroundColor(Color.primaryButton)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            
            VStack(spacing: 16) {
                NavigationLink(destination: VehicleDetailsView()) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text(NSLocalizedString("add_another_vehicle", comment: ""))
                    }
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(NSLocalizedString("vehicle_details_summary_title", comment: ""))
                    .font(.title)
                    .foregroundColor(.primary)
                    .bold()
            }
        }
        .withCustomBackButton(showBackButton: true)
        .task {
            await vehicleManager.getVehicles()
        }
    }
}

struct VehicleDetailsSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VehicleDetailsSummaryView(vehicleManager: VehicleManager())
                .preferredColorScheme(.light)
            
            VehicleDetailsSummaryView(vehicleManager: VehicleManager())
                .preferredColorScheme(.dark)
        }
    }
}
