//
//  ScheduleRideConfirmActivity.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 18/03/25.
//

import SwiftUI

struct ScheduleRideConfirmActivity: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = ScheduleRideConfirmViewModel()
    @State private var showRoleTypeDialog = false
    @State private var showRideTakerOptions = false
    @State private var selectedMainOption: String? = nil
    
    let activityId: String
    let activityDay: String
    let isValidDay: Bool
    
    private func getDisplayText(for roleType: String) -> String {
        switch roleType {
        case "GIVER":
            return "Ride Giver"
        case "DROP_PICK":
            return "Drop & Pick"
        case "DROP":
            return "Drop Only"
        case "PICK":
            return "Pick Only"
        default:
            return ""
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                
            VStack(alignment: .leading, spacing: 0) {
                // Activity Type Header
                Text(viewModel.activityDetail?.type ?? "")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                // Time Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image("Image 1")
                            .resizable()
                            .frame(width: 44, height: 44)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activityDay.capitalized)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.primaryButton)
                            
                            if let schedule = viewModel.activityDetail?.schedulePerDay[activityDay] {
                                Text("\(schedule.startTime.prefix(5)) - \(schedule.endTime.prefix(5))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color.primaryButton)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                
                // Pickup Time Section
                VStack(spacing: 8) {
                    if let schedule = viewModel.activityDetail?.schedulePerDay[activityDay] {
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(.systemGray3))
                            
                            Text("\(schedule.preferredPickupTime) min early")
                                .frame(width: 180)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(.systemGray3))
                        }
                        .padding(.horizontal)
                    }
                    Text(
                        viewModel.activityDetail?
                            .schedulePerDay[activityDay]?.pickupRole
                            .replacingOccurrences(of: "_", with: " ").capitalized ?? ""
                    )
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                
                // Location Section
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                    
                    if let address = viewModel.activityDetail?.address {
                        let addressComponents = [
                            address.addressLine1,
                            address.addressLine2,
                            address.city,
                            address.state,
                            address.pincode.map { $0 > 0 ? String($0) : "" }
                        ].compactMap { $0 }.filter { !$0.isEmpty }
                        
                        Text(addressComponents.joined(separator: ", "))
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal)
                
                if isValidDay {
                    // Probability Section
                    if !viewModel.probability.isEmpty {
                        VStack(spacing: 12) {
                            if viewModel.probability.uppercased() == "LOW" {
                                HStack {
                                    Text("Edit Role Type: ")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primaryButton)
                                    if let roleType = viewModel.manualRoleType {
                                        Text(getDisplayText(for: roleType))
                                            .font(.system(size: 18))
                                            .foregroundColor(.primaryButton)
                                            .onTapGesture {
                                                showRoleTypeDialog = true
                                            }
                                    } else {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.primaryButton)
                                            .font(.system(size: 24))
                                            .onTapGesture {
                                                showRoleTypeDialog = true
                                            }
                                    }
                                }
                            }

                            Text(
                                String(
                                    format: NSLocalizedString(
                                        "probability_message",
                                        comment: ""
                                    ),
                                    viewModel.probability.capitalized
                                )
                            )
                        }
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.probabilityColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if isValidDay {
                        Button(action: { viewModel.scheduleRide(activityId: activityId, dayOfWeek: activityDay) }) {
                            Text(NSLocalizedString("confirm_time_button", comment: ""))
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primaryButton)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Text(NSLocalizedString("cancel_button", comment: ""))
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colorScheme == .dark ? Color(.systemBackground) : .white)
                            .foregroundColor(.red)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            
            // Role Type Dialog Overlay
            if showRoleTypeDialog {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showRoleTypeDialog = false
                    }
                
                VStack(spacing: 0) {
                    Text("Select Role Type")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.vertical, 20)
                    
                    Divider()
                        .background(Color(.systemGray3))
                    
                    Button(action: {
                        selectedMainOption = "GIVER"
                        viewModel.updateManualRoleType("GIVER")
                        showRoleTypeDialog = false
                    }) {
                        HStack {
                            Text("Ride Giver")
                                .font(.system(size: 18))
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedMainOption == "GIVER" && viewModel.manualRoleType == "GIVER" ? Color.primaryButton : Color.clear)
                        .foregroundColor(selectedMainOption == "GIVER" && viewModel.manualRoleType == "GIVER" ? .white : .primary)
                        .contentShape(Rectangle())
                    }
                    
                    Divider()
                        .background(Color(.systemGray3))
                    
                    Button(action: {
                        if selectedMainOption == "TAKER" {
                            selectedMainOption = nil
                        } else {
                            selectedMainOption = "TAKER"
                        }
                    }) {
                        HStack {
                            Text("Ride Taker")
                                .font(.system(size: 18))
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedMainOption == "TAKER" ? Color.primaryButton : Color.clear)
                        .foregroundColor(selectedMainOption == "TAKER" ? .white : .primary)
                        .contentShape(Rectangle())
                    }
                    
                    if selectedMainOption == "TAKER" {
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color(.systemGray3))
                            Button(action: {
                                viewModel.updateManualRoleType("DROP_PICK")
                                showRoleTypeDialog = false
                            }) {
                                HStack {
                                    Text("Pick & Drop")
                                        .font(.system(size: 16))
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(viewModel.manualRoleType == "DROP_PICK" ? Color.primaryButton : Color.clear)
                                .foregroundColor(viewModel.manualRoleType == "DROP_PICK" ? .white : .primary)
                                .contentShape(Rectangle())
                            }
                            
                            Divider()
                                .background(Color(.systemGray3))
                            Button(action: {
                                viewModel.updateManualRoleType("DROP")
                                showRoleTypeDialog = false
                            }) {
                                HStack {
                                    Text("Drop Only")
                                        .font(.system(size: 16))
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(viewModel.manualRoleType == "DROP" ? Color.primaryButton : Color.clear)
                                .foregroundColor(viewModel.manualRoleType == "DROP" ? .white : .primary)
                                .contentShape(Rectangle())
                            }
                            
                            Divider()
                                .background(Color(.systemGray3))
                            Button(action: {
                                viewModel.updateManualRoleType("PICK")
                                showRoleTypeDialog = false
                            }) {
                                HStack {
                                    Text("Pick Only")
                                        .font(.system(size: 16))
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                .background(viewModel.manualRoleType == "PICK" ? Color.primaryButton : Color.clear)
                                .foregroundColor(viewModel.manualRoleType == "PICK" ? .white : .primary)
                                .contentShape(Rectangle())
                            }
                        }
                        .background(Color(.systemGray6).opacity(0.5))
                    }
                    
                    Divider()
                        .background(Color(.systemGray3))
                    
                    Button(action: {
                        showRoleTypeDialog = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
            }
            
            // Toast Message
            if viewModel.showToast {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("schedule_added_message", comment: ""))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: viewModel.showToast)
            }
        }
        .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: $viewModel.showError) {
            Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.getActivity(activityId: activityId)
            if isValidDay {
                viewModel.getProbability(activityId: activityId, dayOfWeek: activityDay)
            }
        }
        .onChange(of: viewModel.shouldDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .withCustomBackButton(showBackButton: true)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ScheduleRideConfirmActivity_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScheduleRideConfirmActivity(
                activityId: "",
                activityDay: "TUESDAY",
                isValidDay: true
            )
            .preferredColorScheme(.light)
            
            ScheduleRideConfirmActivity(
                activityId: "",
                activityDay: "TUESDAY",
                isValidDay: true
            )
            .preferredColorScheme(.dark)
        }
    }
}
