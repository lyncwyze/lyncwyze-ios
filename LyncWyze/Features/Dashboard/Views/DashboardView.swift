//
//  DashboardView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//

import SwiftUI
import Toasts

struct DashboardView: View {
    @State private var isLoading = true
    @State private var hasHandledNavigation = false
    @State private var navigateToLandingPage: Bool = false
    @State private var navigateToCreateProfileStep1: Bool = false
    @State private var navigateToCreateHomeAddressStep2: Bool = false
    @State private var navigateToProfilePhotoVerificationStep3: Bool = false
    @State private var navigateToTermsAndPrivacyStep4: Bool = false
    @State private var showDashboard: Bool = false
    @State private var hasHandledInitialNavigation = false
    
    // New states for navigation
    @State private var navigateToAddChild: Bool = false
    @State private var navigateToAddActivity: Bool = false
    @State private var navigateToAddVehicle: Bool = false
    @State private var navigateToAddEmergencyContact: Bool = false
    
    // Stats
    @State private var givenRides: Int = 0
    @State private var takenRides: Int = 0
    @State private var upcomingRides: Int = 0
    @State private var ongoingRides: Int = 0
    
    @Environment(\.presentToast) var presentToast
    
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showOngoingRides = false
    let shouldNavigateToOngoingRides: Bool
    
    init(shouldNavigateToOngoingRides: Bool = false) {
        self.shouldNavigateToOngoingRides = shouldNavigateToOngoingRides
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToOngoingRides"),
            object: nil,
            queue: .main
        ) { _ in
            if !hasHandledInitialNavigation {
                showOngoingRides = true
            }
        }
    }
    
    private func cleanupNotificationObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("NavigateToOngoingRides"),
            object: nil
        )
    }
    
    private func fetchOnboarding() async {
        guard !hasHandledNavigation else { return }
        
        if let response: AuthResponse = getUserDefaultObject(forKey: Constants.UserDefaultsKeys.loggedInDataKey) {
            print(response)
            if(!response.profileComplete && response.profileStatus != nil){
                DispatchQueue.main.async {
                    self.hasHandledNavigation = true
                    if(response.profileStatus == ProfileStatus.profile){
                        print("Navigate to step 1")
                        self.navigateToCreateProfileStep1 = true
                    } else if(response.profileStatus == ProfileStatus.background) {
                        print("Navigate to step 2")
                        self.navigateToCreateHomeAddressStep2 = true
                    } else if(response.profileStatus == ProfileStatus.photo){
                        print("Navigate to step 3")
                        self.navigateToProfilePhotoVerificationStep3 = true
                    } else if(response.profileStatus == ProfileStatus.policy){
                        print("Navigate to step 4")
                        self.navigateToTermsAndPrivacyStep4 = true
                    }
                    self.isLoading = false
                }
            } else if(!response.acceptTermsAndPrivacyPolicy){
                DispatchQueue.main.async {
                    self.hasHandledNavigation = true
                    print("Navigate to step 4")
                    Task {
                        do {
                            NetworkManager.shared.makeRequest(
                                endpoint: "/user/getCount",
                                method: .GET
                            ){ (result: Result<DataCountResponse, Error>) in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let response):
                                        self.isLoading = false
                                        self.givenRides = response.givenRides
                                        self.takenRides = response.takenRides
                                        self.upcomingRides = response.upcomingRides
                                        self.ongoingRides = response.ongoingRides
                                        
                                        saveUserDefaultObject(response,
                                            forKey: Constants
                                                .UserDefaultsKeys.UserRequiredDataCount)
                                        
                                    case .failure(let error):
                                        self.isLoading = false
                                        let toast = ToastValue(message: "Error: \(error.localizedDescription)")
                                        presentToast(toast)
                                        self.showDashboard = true
                                        
                                    }
                                }

                            }
                            
                        }
                    }

                    self.navigateToTermsAndPrivacyStep4 = true
                    self.isLoading = false
                }
            } else {
                // for other activity fill up after onboarding
                print("onboarding done")
                self.hasHandledNavigation = true
                
                Task {
                    do {
                        NetworkManager.shared.makeRequest(
                            endpoint: "/user/getCount",
                            method: .GET
                        ){ (result: Result<DataCountResponse, Error>) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let response):
                                    self.isLoading = false
                                    self.givenRides = response.givenRides
                                    self.takenRides = response.takenRides
                                    self.upcomingRides = response.upcomingRides
                                    self.ongoingRides = response.ongoingRides
                                    
                                    saveUserDefaultObject(response,
                                        forKey: Constants
                                            .UserDefaultsKeys.UserRequiredDataCount)

                                    
                                    if response.child < 1 {
//                                        self.showDashboard = true
                                        self.navigateToAddChild = true
                                        let toast = ToastValue(message: "Please add a child to explore")
                                        presentToast(toast)
                                    }
                                    else if response.activity < 1 {
//                                        self.showDashboard = true
                                        self.navigateToAddActivity = true
                                        let toast = ToastValue(message: "Please choose a child and add an activity")
                                        presentToast(toast)
                                    }
                                    else if response.vehicle < 1 {
//                                        self.showDashboard = true
                                        self.navigateToAddVehicle = true
                                        let toast = ToastValue(message: "Please add a vehicle")
                                        presentToast(toast)
                                    } else if response.emergencyContact < 1 {
//                                        self.showDashboard = true
	
                                        self.navigateToAddEmergencyContact = true
                                        let toast = ToastValue(message: "Please add an emergency contact")
                                        presentToast(toast)
                                    } else {
                                        self.showDashboard = true
                                    }
                                    
                                case .failure(let error):
                                    self.isLoading = false
                                    let toast = ToastValue(message: "Error: \(error.localizedDescription)")
                                    presentToast(toast)
                                    self.showDashboard = true
                                    
                                }
                            }

                        }
                        
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.hasHandledNavigation = true
                print("No login data found in UserDefaults")
                self.navigateToLandingPage = true
                self.isLoading = false
                // Fix It before push
//                self.navigateToLandingPage = false
//                self.isLoading = false
//                self.showDashboard = true

            }
        }
    }
    
    private func refreshDashboardData() {
        Task {
            NetworkManager.shared.makeRequest(
                endpoint: "/user/getCount",
                method: .GET
            ){ (result: Result<DataCountResponse, Error>) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.isLoading = false
                        self.givenRides = response.givenRides
                        self.takenRides = response.takenRides
                        self.upcomingRides = response.upcomingRides
                        self.ongoingRides = response.ongoingRides
                        saveUserDefaultObject(response,
                            forKey: Constants
                                .UserDefaultsKeys.UserRequiredDataCount)
                        
                        if response.child < 1 {
                            self.navigateToAddChild = true
                            let toast = ToastValue(message: "Please add a child to explore")
                            presentToast(toast)
                        } else if response.activity < 1 {
                            self.navigateToAddActivity = true
                            let toast = ToastValue(message: "Please choose a child and add an activity")
                            presentToast(toast)
                        }
                        else if response.vehicle < 1 {
                            self.navigateToAddVehicle = true
                            let toast = ToastValue(message: "Please add a vehicle")
                            presentToast(toast)
                        } else if response.emergencyContact < 1 {
                            self.navigateToAddEmergencyContact = true
                            let toast = ToastValue(message: "Please add an emergency contact")
                            presentToast(toast)
                        } else {
                            self.showDashboard = true
                        }
                        
                    case .failure(let error):
                        self.isLoading = false
                        let toast = ToastValue(message: "Error: \(error.localizedDescription)")
                        presentToast(toast)
                        self.showDashboard = true
                    }
                }
            }
        }
    }
    
    fileprivate func RideDashboardCard(assetsImage: String, value: String, title: String) -> some View {
        return VStack(spacing: 8) {
            Image(assetsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
            HStack {
                Text(value)
                    .font(.system(size: 24))
                    .foregroundColor(Color.primaryButton)
                    .bold()
                Text(title)
                    .font(.system(size: 14))
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primaryButton.opacity(0.1))
                .shadow(color: Color.primaryButton, radius: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryButton, lineWidth: 1)
        )

//        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading || !showDashboard {
                    DashboardLoadingView()
                } else if showDashboard {
                    DashboardContentView(
                        givenRides: givenRides,
                        takenRides: takenRides,
                        upcomingRides: upcomingRides,
                        ongoingRides: ongoingRides,
                        refreshDashboardData: refreshDashboardData
                    )
                }
                
                NavigationLink(
                    destination: OngoingRidesView(),
                    isActive: $showOngoingRides
                ) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetchOnboarding()
            }
            .onAppear {
                setupNotificationObserver()
                if showDashboard {
                    refreshDashboardData()
                }
                
                if shouldNavigateToOngoingRides && !hasHandledInitialNavigation {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOngoingRides = true
                        hasHandledInitialNavigation = true
                    }
                }
            }
            .onChange(of: showOngoingRides) { newValue in
                if !newValue {
                    // Reset navigation flag when returning from OngoingRidesView
                    hasHandledInitialNavigation = true
                }
            }
            .onDisappear {
                cleanupNotificationObserver()
            }
            
            .navigationDestination(isPresented: $navigateToLandingPage) {
                AppLanding()
                    .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: $navigateToCreateProfileStep1) {
                CreateProfileView(showBackButton: false)
                    .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: $navigateToCreateHomeAddressStep2) {
                CreateHomeAddressView(showBackButton: false)
                    .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: $navigateToProfilePhotoVerificationStep3) {
                ProfilePhotoVerification_Step3(showBackButton: false)
                    .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: $navigateToTermsAndPrivacyStep4) {
                TermsAndPrivacyView(showBackButton: false)
                    .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: $navigateToAddChild) {
                AddChildInfoView(
                    childrenManager: ChildrenManager(),
                    isOnboardingComplete: false,
                    showBackButton: false,
                    shouldUpdate: .constant(false),
                    onDismiss: {
                        refreshDashboardData()
                    }
                )
            }
            .navigationDestination(isPresented: $navigateToAddVehicle) {
                VehicleDetailsView(
                    showBackButton: false,
                    isOnboardingComplete: false,
                    onDismiss: {
                        refreshDashboardData()
                    }
                )
            }
            .navigationDestination(isPresented: $navigateToAddEmergencyContact) {
                HandleEmergencyContactView(
                    contactsManager: EmergencyContactsManager(),
                    contact: nil,
                    showBackButton: false,
                    isOnboardingComplete: false,
                    onDismiss: {
                        refreshDashboardData()
                    }
                )
            }
            .navigationDestination(isPresented: $navigateToAddActivity) {
                ActivityChildListView(
                    showBackButton: false,
                    isOnboardingComplete: false,
                    onDismiss: {
                        refreshDashboardData()
                    }
                )
            }
        }
//        .navigationBarHidden(true)
//        .navigationBarBackButtonHidden(true)
//        .navigationBarTitleDisplayMode(.inline)
    }
}

// Add these new view components before the DashboardView struct
struct DashboardLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Text(NSLocalizedString("loading_text", comment: ""))
                .foregroundColor(.gray)
                .padding(.top)
        }
    }
}

struct DashboardContentView: View {
    var givenRides: Int
    var takenRides: Int
    var upcomingRides: Int
    var ongoingRides: Int
    var refreshDashboardData: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Settings Button
                HStack {
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "line.3.horizontal.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        // Add Children
                        NavigationLink(
                            destination: ChildrenView()
                        ) {
                            DashboardCard(
                                assetsImage: "check",
                                title: NSLocalizedString("my_children", comment: ""),
                                backgroundColor: Color(.systemBackground)
                            )
                        }
                        // Add Activity
                        NavigationLink(destination: ActivityChildListView(
                            isOnboardingComplete: true,
                            onDismiss: {
                                refreshDashboardData()
                            }
                        )) {
                            DashboardCard(
                                assetsImage: (colorScheme == .dark) ? "Image-white" : "Image",
                                title: NSLocalizedString("all_activities", comment: ""),
                                backgroundColor: Color(.systemBackground)
                            )
                        }
                        // Vehicle Details
                        NavigationLink(destination: VehicleDetailsSummaryView(vehicleManager: VehicleManager())) {
                            DashboardCard(
                                assetsImage: "car 1",
                                title: NSLocalizedString("my_vehicles", comment: ""),
                                backgroundColor: Color(.systemBackground)
                            )
                        }
                    }
                    
                    NavigationLink(
                        destination: ScheduleRideChildListView()
                    ){
                        HStack {
                            Image("Vector")
                                .resizable()
                                .frame(width: 34, height: 34)
                            
                            Text(NSLocalizedString("schedule_a_ride", comment: ""))
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
                        )
                    }
                    
                    NavigationLink(destination: OngoingRidesView()){
                        HStack {
                            Image("ontheway")
                                .resizable()
                                .frame(width: 34, height: 34)
                            HStack{
                                Text("\(ongoingRides)")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.primaryButton)
                                    .bold()
                                Text(NSLocalizedString("in_progress_ride", comment: ""))
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
                        )
                    }
                    
                    // Rides Details
                    HStack {
                        NavigationLink(destination: RidesGivenView()){
                            RideDashboardCard(
                                assetsImage: "rides_given",
                                value: "\(givenRides)",
                                title: NSLocalizedString("ride_given", comment: "")
                            )
                        }
                        NavigationLink(destination: RidesTakenView()) {
                            RideDashboardCard(
                                assetsImage: "rides_taken",
                                value: "\(takenRides)",
                                title: NSLocalizedString("ride_taken", comment: "")
                            )
                        }
                        NavigationLink(destination: UpcomingRidesView()) {
                            RideDashboardCard(
                                assetsImage: "upcoming",
                                value: "\(upcomingRides)",
                                title: NSLocalizedString("upcoming_rides", comment: "")
                            )
                        }
                    }
                    
                    // Emergency Contacts
                    NavigationLink(destination: EmergencyContactsView()){
                        HStack {
                            Image(systemName: "phone.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("emergency_contacts", comment: ""))
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(.top)
        }
        .background(Color(.systemGray6))
    }
}

// Add StatCard view for displaying statistics
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Keep the DashboardCard struct as is since it's still being used
struct DashboardCard: View {
    let systemImage: String?
    let assetsImage: String?
    let title: String
    let value: String?
    let unit: String?
    let backgroundColor: Color
    @Environment(\.colorScheme) private var colorScheme

    init(
        systemImage: String? = nil,
        assetsImage: String? = nil,
        title: String,
        value: String? = nil,
        unit: String? = nil,
        backgroundColor: Color = Color(.systemBackground)
    ) {
        self.systemImage = systemImage
        self.assetsImage = assetsImage
        self.title = title
        self.value = value
        self.unit = unit
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color.primaryButton)
            } else {
                if let assetsImage = assetsImage {
                    Image(assetsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color.primaryButton)
                }
            }

            if let value = value {
                Text(value)
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                if let unit = unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
        )
    }
}

// Add this before the DashboardView struct
struct RideDashboardCard: View {
    let assetsImage: String
    let value: String
    let title: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 60, height: 60)

                Image(assetsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
            }

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24))
                    .foregroundColor(Color.primaryButton)
                    .bold()

                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 80, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primaryButton.opacity(colorScheme == .dark ? 0.2 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryButton.opacity(colorScheme == .dark ? 0.8 : 0.9), lineWidth: 1)
        )
    }
}

struct Children_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
