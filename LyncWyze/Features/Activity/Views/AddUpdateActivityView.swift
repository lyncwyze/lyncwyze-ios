//
//  ActivityDetailsView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI


// MARK: - Activity SubType Selection Component
struct ActivitySubTypeSelectionView: View {
    let subTypes: [String]
    @Binding var selectedSubType: String
    let isDisabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("activity_sub_type")
                    .foregroundColor(.primary)
                    .font(.headline)
                Text("*")
                    .foregroundColor(.red)
            }
            
            Menu {
                ForEach(subTypes, id: \.self) { type in
                    Button(type) {
                        selectedSubType = type
                    }
                }
            } label: {
                HStack {
                    Text(selectedSubType)
                        .foregroundColor(isDisabled ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .disabled(isDisabled)
        }
    }
}

// MARK: - Location Input Component
struct LocationInputView: View {
    @Binding var location: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("activity_location_address")
                .foregroundColor(.primary)
                .font(.headline)
            
            TextField("Location", text: $location)
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}


// MARK: - Activity Type Selection Component
struct ActivityTypeSelectionView: View {
    let activityTypes: [String]
    @Binding var selectedActivityType: String
    let isDisabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("activity_type")
                    .foregroundColor(.primary)
                    .font(.headline)
                Text("*")
                    .foregroundColor(.red)
            }
            
            Menu {
                ForEach(activityTypes, id: \.self) { type in
                    Button(type) {
                        selectedActivityType = type.uppercased()
                    }
                }
            } label: {
                HStack {
                    Text(selectedActivityType)
                        .foregroundColor(isDisabled ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .disabled(isDisabled)
        }
    }
}


// MARK: - Main Activity Details View
struct AddUpdateActivityView: View {
    @StateObject private var activityManager = ActivityManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var activityCreated: Bool
    let child: Child?
    let activityToEdit: Activity?
    let isOnboardingComplete: Bool
    @State private var navigateToAppLanding = false
    
    // State variables for form fields
    @State private var selectedActivityType: String = ""
    @State private var selectedSubType: String = ""
    @State private var location: String = ""
    @State private var showingStartTimePicker = false
    @State private var showingEndTimePicker = false
    @State private var showingRoleSelection = false
    @State private var showingPickupTimeSheet = false
    @State private var selectedDayIndex: Int?
    @State private var selectedRole: String = ""
    @State private var selectedPickupTime: String = ""
    @State private var isLoading = false
    @State private var apiError: String?
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @State private var showVehicleView: Bool = false
    @StateObject private var addressViewModel = AddressSelectionViewModel()
    
    // Time selection states
    @State private var startHour: Int = 7
    @State private var startMinute: Int = 0
    @State private var startIsAM: Bool = false
    @State private var endHour: Int = 8
    @State private var endMinute: Int = 0
    @State private var endIsAM: Bool = false
    
    @State private var timeSlots: [String: TimeSlot] = [:]
    @State private var selectedImage: UIImage?
    @State private var isTypeSubtypeDisabled = true
    @State private var selectedRideOption: RideOption?
    @State private var navigateToVehicle: Bool = false
    
    let activityTypes = ["Educational", "School", "Sports", "Other"]
    let subTypes = ["Gymnastics", "Swimming", "Football", "Basketball"]
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let pickupTimes = ["10 Min", "20 Min", "30 Min", "40 Min"]
    
    init(
        child: Child?,
        activityToEdit: Activity? = nil,
        isOnboardingComplete: Bool = true,
        activityCreated: Binding<Bool> = .constant(false)
    ) {
        self.child = child
        self.activityToEdit = activityToEdit
        self.isOnboardingComplete = isOnboardingComplete
        self._activityCreated = activityCreated
    }
    
    var body: some View {
        mainContent
            .onAppear(perform: setupInitialData)
            .alert("Error", isPresented: $showErrorAlert) {
                Button("ok_button") {
                    showErrorAlert = false
                    apiError = nil
                }
            } message: {
                if let error = apiError {
                    Text(LocalizedStringKey(error))
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("ok_button") {
                    dismiss()
                }
            } message: {
                Text("activity_saved_success")
            }
            .withCustomBackButton(showBackButton: true)
            .navigationDestination(isPresented: $navigateToVehicle) {
                VehicleDetailsView(
                    showBackButton: true,
                    isOnboardingComplete: false,
                    onDismiss: {}
                )
            }
            .fullScreenCover(isPresented: $navigateToAppLanding) {
                AppLanding()
                    .navigationBarBackButtonHidden(true)
            }
    }
    
    private var mainContent: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                    providerSelectionView
                    activityTypeSelectionView
                    activitySubTypeSelectionView
                    daySelectionGrid
                    Spacer()
                    actionButtons
                }
                .padding()
            }
            
            overlayViews
            
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(String(format: NSLocalizedString("activity_title", comment: ""), 
                 child?.firstName ?? "", 
                 child?.lastName ?? "", 
                 activityToEdit == nil ? "Add" : "Edit"))
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            if !isOnboardingComplete {
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
        .padding(.bottom, 10)
    }
    
    private var providerSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text("activity_provider")
                    .foregroundColor(.primary)
                    .font(.headline)
                Text("*")
                    .foregroundColor(.red)
            }
            
            AddressSearchView(
                checkZone: $location,
                viewModel: addressViewModel,
                isEditMode: activityToEdit != nil,
                type: activityToEdit?.type,
                subType: activityToEdit?.subType
            )
            .onChange(of: addressViewModel.selectedProvider) { newValue in
                handleProviderSelection(newValue)
            }
        }
    }
    
    private var activityTypeSelectionView: some View {
        ActivityTypeSelectionView(
            activityTypes: activityTypes,
            selectedActivityType: $selectedActivityType,
            isDisabled: isTypeSubtypeDisabled
        )
    }
    
    private var activitySubTypeSelectionView: some View {
        ActivitySubTypeSelectionView(
            subTypes: subTypes,
            selectedSubType: $selectedSubType,
            isDisabled: isTypeSubtypeDisabled
        )
    }
    
    private var daySelectionGrid: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            LazyHGrid(rows: [GridItem(.flexible())], spacing: 10) {
                ForEach(days.indices, id: \.self) { index in
                    DaySelectionCell(
                        day: days[index],
                        index: index,
                        timeSlot: timeSlots[days[index]],
                        onSelect: { selectDay(index, days[index]) },
                        onModify: { modifyTimeSlot(days[index]) }
                    )
                }
            }
        }
        .frame(height: 160)
    }
    
    private var actionButtons: some View {
        VStack {
            if activityToEdit != nil {
                Button(action: deleteActivityAction) {
                    Text("delete_activity")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                .padding(.vertical)
            }
            
            Button(action: saveOrUpdateActivity) {
                Text(
                    isOnboardingComplete ? (activityToEdit == nil ? "save_activity" : "update_activity") : "next_add_activity"
                )
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryButton)
                    .cornerRadius(8)
            }
        }
    }
    
    private var overlayViews: some View {
        ZStack {
            if showingStartTimePicker {
                overlayView {
                    CustomTimePicker(
                        isPresented: $showingStartTimePicker,
                        selectedHour: $startHour,
                        selectedMinute: $startMinute,
                        isAM: $startIsAM,
                        title: "Activity Start Time"
                    ) {
                        showingStartTimePicker = false
                        showingEndTimePicker = true
                    }
                }
            }
            
            if showingEndTimePicker {
                overlayView {
                    CustomTimePicker(
                        isPresented: $showingEndTimePicker,
                        selectedHour: $endHour,
                        selectedMinute: $endMinute,
                        isAM: $endIsAM,
                        title: "Activity End Time"
                    ) {
                        handleEndTimeSelection()
                    }
                }
            }
            
            if showingRoleSelection {
                overlayView {
                    RoleSelectionSheet(
                        isPresented: $showingRoleSelection,
                        selectedRole: $selectedRole,
                        selectedRideOption: $selectedRideOption,
                        onSelection: handleRoleSelection
                    )
                }
            }
            
            if showingPickupTimeSheet {
                overlayView {
                    PickupTimeSheet(
                        selectedTime: $selectedPickupTime,
                        isPresented: $showingPickupTimeSheet,
                        times: pickupTimes
                    )
                    .onChange(of: selectedPickupTime) { newTime in
                        if !newTime.isEmpty {
                            handlePickupTimeSelection(newTime)
                            showingPickupTimeSheet = false
                            showingRoleSelection = false
                        }
                    }
                }
            }
        }
    }
    
    private func handleProviderSelection(_ provider: Provider?) {
        if let provider = provider {
            selectedActivityType = provider.type.uppercased()
            selectedSubType = provider.subType ?? ""
            isTypeSubtypeDisabled = true
        } else {
            selectedActivityType = ""
            selectedSubType = ""
            isTypeSubtypeDisabled = true
        }
    }
    
    private func handleRoleSelection() {
        if selectedRole == "TAKER" {
            // Reset pickup time before showing pickup time sheet
            selectedPickupTime = ""
            showingPickupTimeSheet = true
        } else {
            showingRoleSelection = false
            if let selectedDay = selectedDayIndex.map({ days[$0] }) {
                timeSlots[selectedDay] = TimeSlot(
                    startHour: timeSlots[selectedDay]?.startHour ?? startHour,
                    startMinute: timeSlots[selectedDay]?.startMinute ?? startMinute,
                    startIsAM: timeSlots[selectedDay]?.startIsAM ?? startIsAM,
                    endHour: timeSlots[selectedDay]?.endHour ?? endHour,
                    endMinute: timeSlots[selectedDay]?.endMinute ?? endMinute,
                    endIsAM: timeSlots[selectedDay]?.endIsAM ?? endIsAM,
                    role: "GIVER",
                    rideOption: nil,
                    pickupTime: nil
                )
            }
        }
    }
    
    private func handlePickupTimeSelection(_ time: String) {
        if let selectedDay = selectedDayIndex.map({ days[$0] }) {
            timeSlots[selectedDay] = TimeSlot(
                startHour: timeSlots[selectedDay]?.startHour ?? startHour,
                startMinute: timeSlots[selectedDay]?.startMinute ?? startMinute,
                startIsAM: timeSlots[selectedDay]?.startIsAM ?? startIsAM,
                endHour: timeSlots[selectedDay]?.endHour ?? endHour,
                endMinute: timeSlots[selectedDay]?.endMinute ?? endMinute,
                endIsAM: timeSlots[selectedDay]?.endIsAM ?? endIsAM,
                role: "TAKER",
                rideOption: selectedRideOption,
                pickupTime: time
            )
            showingPickupTimeSheet = false
            showingRoleSelection = false
        }
    }
    
    private func setupInitialData() {
        if let activity = activityToEdit {
            selectedActivityType = activity.type
            selectedSubType = activity.subType
            location = activity.address.addressLine1 ?? ""
            
            for (day, schedule) in activity.schedulePerDay {
                let shortDay = mapAPIFormatToDay(day)
                let (startComponents, startIsAM) = parseTime(schedule.startTime)
                let (endComponents, endIsAM) = parseTime(schedule.endTime)
                
                let rideOption = getRideOption(schedule)
                let role = schedule.pickupRole == "GIVER" ? "GIVER" : "TAKER"
                
                timeSlots[shortDay] = TimeSlot(
                    startHour: startComponents.hour,
                    startMinute: startComponents.minute,
                    startIsAM: startIsAM,
                    endHour: endComponents.hour,
                    endMinute: endComponents.minute,
                    endIsAM: endIsAM,
                    role: role,
                    rideOption: rideOption,
                    pickupTime: schedule.preferredPickupTime > 0 ? "\(schedule.preferredPickupTime) Min" : nil
                )
            }
        }
    }
    
    private func deleteActivityAction() {
        guard let activityId = activityToEdit?.id else { return }
        
        Task {
            do {
                isLoading = true
                try await activityManager.deleteActivity(activityId: activityId)
                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    apiError = error.localizedDescription
                }
            }
        }
    }
    
    private func selectDay(_ index: Int, _ day: String) {
        if timeSlots[day] != nil {
            // Remove the time slot if it exists
            timeSlots.removeValue(forKey: day)
            selectedRole = ""
            selectedRideOption = nil
            selectedPickupTime = ""
        } else {
            // Check if there's a previously selected time slot to copy from
            if let existingTimeSlot = timeSlots.values.first {
                // Copy the existing time slot to the new day
                timeSlots[day] = existingTimeSlot
            } else {
                // Show time picker for new time slot
                selectedDayIndex = index
                // Reset all selection states
                selectedRole = ""
                selectedRideOption = nil
                selectedPickupTime = ""
                showingStartTimePicker = true
            }
        }
    }
    
    private func handleEndTimeSelection() {
        if let selectedDay = selectedDayIndex.map({ days[$0] }) {
            timeSlots[selectedDay] = TimeSlot(
                startHour: startHour,
                startMinute: startMinute,
                startIsAM: startIsAM,
                endHour: endHour,
                endMinute: endMinute,
                endIsAM: endIsAM,
                role: "GIVER"  // Set default role to GIVER
            )
        }
        showingEndTimePicker = false
        // Reset role selection states before showing role selection
        selectedRole = ""
        selectedRideOption = nil
        selectedPickupTime = ""
        showingRoleSelection = true
    }
    
    private func getRideOption(_ schedule: DailySchedule) -> RideOption? {
        if schedule.pickupRole == "DROP_PICK" && schedule.dropoffRole == "DROP_PICK" {
            return .bothDropAndPickup
        } else if schedule.pickupRole == "DROP" && schedule.dropoffRole == "DROP" {
            return .dropOnly
        } else if schedule.pickupRole == "PICK" && schedule.dropoffRole == "PICK" {
            return .pickupOnly
        }
        return nil
    }
    
    private func formatTime(_ hour: Int, _ minute: Int, _ isAM: Bool) -> String {
        // Convert to 24-hour format
        var hour24 = hour
        if (!isAM && hour != 12) {
            hour24 = hour + 12
        } else if (isAM && hour == 12) {
            hour24 = 0
        }
        return String(format: "%02d:%02d", hour24, minute)
    }
    
    private func saveOrUpdateActivity() {
        guard let child = child, let childId = child.apiId else {
            apiError = "child_info_missing"
            showErrorAlert = true
            return
        }
        
        guard !timeSlots.isEmpty else {
            apiError = "select_day_time_slot"
            showErrorAlert = true
            return
        }
        
        guard let selectedLocation = addressViewModel.selectedLocation else {
            apiError = "select_provider_location"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        // Create schedulePerDay dictionary
        var schedulePerDay: [String: DailySchedule] = [:]
        
        for (day, timeSlot) in timeSlots {
            let startTime = formatTime(timeSlot.startHour, timeSlot.startMinute, timeSlot.startIsAM)
            let endTime = formatTime(timeSlot.endHour, timeSlot.endMinute, timeSlot.endIsAM)
            let pickupMinutes = timeSlot.pickupTime != nil ? (Int(timeSlot.pickupTime!.replacingOccurrences(of: " Min", with: "")) ?? 20) : 0
            
            let schedule = DailySchedule(
                startTime: startTime,
                endTime: endTime,
                preferredPickupTime: pickupMinutes,
                pickupRole: getRoleForPickup(timeSlot: timeSlot),
                dropoffRole: getRoleForDropoff(timeSlot: timeSlot)
            )
            
            schedulePerDay[AppUtility.mapDayToAPIFormat(day)] = schedule
        }
        
        // Create activity location using selected provider's location
        let activityLocation = ActivityLocation(
            description: selectedLocation.description,
            placeId: selectedLocation.placeId,
            sessionToken: selectedLocation.sessionToken,
            x: addressViewModel.selectedProvider?.address.location.coordinates[0],
            y: addressViewModel.selectedProvider?.address.location.coordinates[1],
            coordinates: addressViewModel.selectedProvider?.address.location.coordinates ?? [0,0],
            type: addressViewModel.selectedProvider?.type ?? "Point"
        )
        
        // Create activity address
        let address = ActivityAddress(
            user: nil,
            userId: nil,
            addressLine1: addressViewModel.selectedProvider?.address.addressLine1,
            addressLine2: addressViewModel.selectedProvider?.address.addressLine2,
            landMark: addressViewModel.selectedProvider?.address.landMark,
            pincode: addressViewModel.selectedProvider?.address.pincode,
            state: addressViewModel.selectedProvider?.address.state,
            city: addressViewModel.selectedProvider?.address.city,
            location: activityLocation
        )
        
        // Create or update activity
        let activity = Activity(
            id: activityToEdit?.id,  // Include ID if updating
            childId: childId,
            type: selectedActivityType,
            subType: selectedSubType,
            address: address,
            image: activityToEdit?.image,  // Preserve existing image if not changed
            schedulePerDay: schedulePerDay
        )
        
        // Save or update activity
        Task {
            do {
                if let _ = activityToEdit {
                    let _ = try await activityManager.updateActivity(activity)
                } else {
                    let _ = try await activityManager.addActivity(activity)
                }
                await MainActor.run {
                    isLoading = false
                    activityCreated = true
                    if isOnboardingComplete == false {
                        if let dataCount: DataCountResponse = getUserDefaultObject(
                            forKey: Constants.UserDefaultsKeys.UserRequiredDataCount
                        ) {
                            if dataCount.vehicle < 1 {
                                navigateToVehicle = true
                            } else {
                                showSuccessAlert = true
                                dismiss()
                            }
                        } else {
                            navigateToVehicle = true
                        }
                    } else {
                        showSuccessAlert = true
//                         dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    apiError = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func parseTime(_ timeString: String) -> ((hour: Int, minute: Int), Bool) {
        let components = timeString.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return ((7, 0), true)  // Default values
        }
        
        let isAM = hour < 12
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        
        return ((hour12, minute), isAM)
    }
    
    private func mapAPIFormatToDay(_ day: String) -> String {
        switch day {
        case "MONDAY": return "Mon"
        case "TUESDAY": return "Tue"
        case "WEDNESDAY": return "Wed"
        case "THURSDAY": return "Thu"
        case "FRIDAY": return "Fri"
        case "SATURDAY": return "Sat"
        case "SUNDAY": return "Sun"
        default: return day
        }
    }
        
    private func getRoleForPickup(timeSlot: TimeSlot) -> String {
        guard let role = timeSlot.role, role == "TAKER" else { return "GIVER" }
        
        switch timeSlot.rideOption {
        case .bothDropAndPickup:
            return "DROP_PICK"
        case .dropOnly:
            return "DROP"
        case .pickupOnly:
            return "PICK"
        case .none:
            return "GIVER"
        }
    }
    
    private func getRoleForDropoff(timeSlot: TimeSlot) -> String {
        guard let role = timeSlot.role, role == "TAKER" else { return "GIVER" }
        
        switch timeSlot.rideOption {
        case .bothDropAndPickup:
            return "DROP_PICK"
        case .dropOnly:
            return "DROP"
        case .pickupOnly:
            return "PICK"
        case .none:
            return "GIVER"
        }
    }
    
    private func overlayView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showingStartTimePicker = false
                    showingEndTimePicker = false
                    showingRoleSelection = false
                    showingPickupTimeSheet = false
                }
            
            content()
        }
    }
    
    private func modifyTimeSlot(_ day: String) {
        if let timeSlot = timeSlots[day] {
            // Set the current time slot values
            startHour = timeSlot.startHour
            startMinute = timeSlot.startMinute
            startIsAM = timeSlot.startIsAM
            endHour = timeSlot.endHour
            endMinute = timeSlot.endMinute
            endIsAM = timeSlot.endIsAM
            selectedRole = timeSlot.role ?? ""
            selectedRideOption = timeSlot.rideOption
            selectedPickupTime = timeSlot.pickupTime ?? ""
            
            // Show the time picker to start modification
            selectedDayIndex = days.firstIndex(of: day)
            showingStartTimePicker = true
        }
    }
}

// MARK: - Day Selection Cell
struct DaySelectionCell: View {
    let day: String
    let index: Int
    let timeSlot: TimeSlot?
    let onSelect: () -> Void
    let onModify: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Button(action: onSelect) {
                Text(day)
                    .frame(width: 50, height: 50)
                    .padding(.vertical, 10)
                    .background(timeSlot != nil ? Color.primaryButton : Color(.systemGray6))
                    .foregroundColor(timeSlot != nil ? .white : .primary)
                    .clipShape(Circle())
            }

            if let timeSlot = timeSlot {
                Button(action: onModify) {
                    VStack(spacing: 4) {
                        Text(formatTimeString(timeSlot.startHour, timeSlot.startMinute, timeSlot.startIsAM))
                            .font(.caption)
                        Text(formatTimeString(timeSlot.endHour, timeSlot.endMinute, timeSlot.endIsAM))
                            .font(.caption)
                        Text(getRoleDisplayText(timeSlot).replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                        if let pickupTime = timeSlot.pickupTime {
                            Text(pickupTime)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(Color.primaryButton)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func formatTimeString(_ hour: Int, _ minute: Int, _ isAM: Bool) -> String {
        let hour12 = hour == 12 ? 12 : hour % 12
        let period = isAM ? "AM" : "PM"
        return String(format: "%02d:%02d %@", hour12, minute, period)
    }

    private func getRoleDisplayText(_ timeSlot: TimeSlot) -> String {
        guard let role = timeSlot.role else { return "GIVER" }

        if role == "GIVER" {
            return "GIVER"
        }

        switch timeSlot.rideOption {
        case .bothDropAndPickup:
            return "DROP_PICK"
        case .dropOnly:
            return "DROP"
        case .pickupOnly:
            return "PICK"
        case .none:
            return role
        }
    }
}

struct AddUpdateActivityView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddUpdateActivityView(child: nil, activityToEdit: nil)
                .preferredColorScheme(.light)
            
            AddUpdateActivityView(child: nil, activityToEdit: nil)
                .preferredColorScheme(.dark)
        }
    }
}
