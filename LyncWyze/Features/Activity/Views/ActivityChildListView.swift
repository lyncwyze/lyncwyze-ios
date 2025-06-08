import SwiftUI

struct ActivityChildListView: View {
    @StateObject private var childrenManager = ChildrenManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedChild: Child? = nil
    @State private var navigateToActivityList = false
    @State private var navigateToAddActivity = false
    @State private var activityCreated = false
    @State private var navigateToAppLanding = false
    let showBackButton: Bool
    var onDismiss: (() -> Void)?
    let isOnboardingComplete: Bool
    
    init(
        showBackButton: Bool = true,
        isOnboardingComplete: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        self.showBackButton = showBackButton
        self.isOnboardingComplete = isOnboardingComplete
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if childrenManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else if childrenManager.children.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.secondary)
                    
                    Text("no_children_added")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("add_children_message")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                VStack {
                    HStack {
                        Text("choose_child_message")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
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
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(childrenManager.children) { child in
                                ChildListItemView(child: child)
                                    .onTapGesture {
                                        selectedChild = child
                                        if isOnboardingComplete {
                                            navigateToActivityList = true
                                        } else {
                                            navigateToAddActivity = true
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
                .refreshable {
                    await childrenManager.fetchChildren()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isOnboardingComplete {
                    Text("select_child_title")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.leading, 16)
                } else {
                    Text("select_child_title")
                        .font(.title)
                        .foregroundColor(.primary)
                        .bold()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .withCustomBackButton(showBackButton: showBackButton)
        .navigationDestination(isPresented: $navigateToActivityList) {
            if let child = selectedChild {
                ActivityDetailView(child: child)
            }
        }
        .navigationDestination(isPresented: $navigateToAddActivity) {
            if let child = selectedChild {
                AddUpdateActivityView(
                    child: child,
                    isOnboardingComplete: false,
                    activityCreated: $activityCreated
                )
                .onDisappear {
                    if let dataCount: DataCountResponse = getUserDefaultObject(
                        forKey: Constants.UserDefaultsKeys.UserRequiredDataCount
                    ) {
                        if activityCreated && dataCount.vehicle > 0 {
                            onDismiss?()
                            dismiss()
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToAppLanding) {
            AppLanding()
                .navigationBarBackButtonHidden(true)
        }
        .task {
            await childrenManager.fetchChildren()
        }
    }
}


struct ActivityChildListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivityChildListView()
                .preferredColorScheme(.light)
            
            ActivityChildListView()
                .preferredColorScheme(.dark)
        }
    }
} 
