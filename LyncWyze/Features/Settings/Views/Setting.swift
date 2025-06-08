import SwiftUI

// Environment key for root navigation
private struct RootPresentationModeKey: EnvironmentKey {
    static let defaultValue: Binding<RootPresentationMode> = .constant(RootPresentationMode())
}

extension EnvironmentValues {
    var rootPresentationMode: Binding<RootPresentationMode> {
        get { self[RootPresentationModeKey.self] }
        set { self[RootPresentationModeKey.self] = newValue }
    }
}

struct RootPresentationMode {
    var isPresented: Bool = false
}

struct SettingsView: View {
    @Environment(\.rootPresentationMode) private var rootPresentationMode
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogoutAlert = false
    @State private var navigateToAppLanding = false
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
//        NavigationView {
            List {
                // Account Section
                Section(header: Text(NSLocalizedString("account_section", comment: "")).textCase(.uppercase)) {
                    NavigationLink(destination: ProfileView()) {
                        SettingsRow(icon: "person.crop.circle.fill",
                                  iconColor: .blue,
                                  title: NSLocalizedString("profile", comment: ""))
                    }
                    
                    NavigationLink(
                        destination: Text(NSLocalizedString("payment_methods", comment: ""))
                            .withCustomBackButton(showBackButton: true)
                    ) {
                        SettingsRow(icon: "creditcard.fill",
                                  iconColor: .purple,
                                  title: NSLocalizedString("payment_methods", comment: ""))
                    }
                }
                
                // Preferences Section
//                Section(header: Text(NSLocalizedString("preferences_section", comment: "")).textCase(.uppercase)) {
//                    Toggle(isOn: $notificationsEnabled) {
//                        SettingsRow(icon: "bell.fill",
//                                  iconColor: .orange,
//                                  title: NSLocalizedString("notifications", comment: ""))
//                    }
//                    
//                    Toggle(isOn: $darkModeEnabled) {
//                        SettingsRow(icon: "moon.fill",
//                                  iconColor: .indigo,
//                                  title: NSLocalizedString("dark_mode", comment: ""))
//                    }
//                }
                
                // Support Section
                Section(header: Text(NSLocalizedString("support_section", comment: "")).textCase(.uppercase)) {
                    NavigationLink(destination: Text(NSLocalizedString("help_center", comment: ""))
                        .withCustomBackButton(showBackButton: true)
                    ) {
                        SettingsRow(icon: "questionmark.circle.fill",
                                  iconColor: .green,
                                  title: NSLocalizedString("help_center", comment: ""))
                    }
                    
                    NavigationLink(destination: FAQView()) {
                        SettingsRow(icon: "book.fill",
                                  iconColor: .orange,
                                  title: NSLocalizedString("faqs", comment: ""))
                    }
                    
                    NavigationLink(destination: Text(NSLocalizedString("contact_support", comment: ""))
                        .withCustomBackButton(showBackButton: true)) {
                        SettingsRow(icon: "message.fill",
                                  iconColor: .blue,
                                  title: NSLocalizedString("contact_support", comment: ""))
                    }
                }
                
                // About Section
                Section(header: Text(NSLocalizedString("about_section", comment: "")).textCase(.uppercase)) {
                    NavigationLink(
                        destination: WebViewHandler(
                            navigationTitle: NSLocalizedString("privacy_policy", comment: ""),
                            urlString: Constants.URLStrings.privacyPolicy
                        )
                        .withCustomBackButton(showBackButton: true)
) {
                        SettingsRow(icon: "hand.raised.fill",
                                  iconColor: .gray,
                                  title: NSLocalizedString("privacy_policy", comment: ""))
                    }
                    
                    NavigationLink(destination: Text(NSLocalizedString("terms_of_service", comment: ""))
                        .withCustomBackButton(showBackButton: true)) {
                        SettingsRow(icon: "doc.text.fill",
                                  iconColor: .gray,
                                  title: NSLocalizedString("terms_of_service", comment: ""))
                    }
                }
                
                // Account Deletion Section
                Section {
                    NavigationLink(
                        destination: WebViewHandler(
                            navigationTitle: NSLocalizedString("delete_account", comment: ""),
                            urlString: Constants.URLStrings.accountDeletion
                        )
                        .withCustomBackButton(showBackButton: true)
                    ) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.minus.fill")
                                .foregroundColor(.red)
                                .imageScale(.medium)
                            Text(NSLocalizedString("delete_account", comment: ""))
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                }
                
                // Logout Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                .foregroundColor(.red)
                                .imageScale(.medium)
                            Text(NSLocalizedString("logout", comment: ""))
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings_title", comment: ""))
            .listStyle(InsetGroupedListStyle())
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text(NSLocalizedString("logout_alert_title", comment: "")),
                    message: Text(NSLocalizedString("logout_alert_message", comment: "")),
                    primaryButton: .destructive(Text(NSLocalizedString("logout", comment: ""))) {
                        Task {
                            let _ = await FCMUtilities.shared.deleteFCMToken()
                            UserDefaults.standard.logout()
                            rootPresentationMode.wrappedValue.isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                navigateToAppLanding = true
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $navigateToAppLanding) {
                AppLanding()
            }
            .withCustomBackButton(showBackButton: true)
//        }
    }
}

// Helper view for consistent row styling
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .imageScale(.large)
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

// Preview provider for SwiftUI canvas
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
