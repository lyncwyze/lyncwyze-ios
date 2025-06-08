import SwiftUI

struct RidesGivenView: View {
    @StateObject private var viewModel = RidesGivenViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFeedback = false
    @State private var selectedFeedbackData: FeedBackPreReq?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.rides.isEmpty {
                EmptyStateView()
            } else {
                RideListView(
                    rides: viewModel.rides,
                    viewModel: viewModel,
                    showFeedback: $showFeedback,
                    selectedFeedbackData: $selectedFeedbackData
                )
            }
        }
        .navigationTitle(NSLocalizedString("rides_given_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchRidesGiven()
        }
        .alert(viewModel.error ?? NSLocalizedString("error_alert_title", comment: ""), isPresented: $viewModel.showError) {
            Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) {
                viewModel.error = nil
            }
        }
        .withCustomBackButton(showBackButton: true)
        .navigationDestination(isPresented: $showFeedback) {
            if let feedbackData = selectedFeedbackData {
                FeedbackView(
                    rideId: feedbackData.rideId,
                    fromUserId: feedbackData.fromUserId,
                    forUserId: feedbackData.forUserId,
                    forUserName: feedbackData.fromUserName,
                    riderType: feedbackData.riderType,
                    date: feedbackData.date
                )
            }
        }
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.circle")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.secondary)
            Text(NSLocalizedString("no_rides_found", comment: ""))
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Ride List View
private struct RideListView: View {
    let rides: [EachRide]
    let viewModel: RidesGivenViewModel
    @Binding var showFeedback: Bool
    @Binding var selectedFeedbackData: FeedBackPreReq?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(rides) { ride in
                    RideCardView(ride: ride, viewModel: viewModel) {
                        selectedFeedbackData = createFeedbackData(from: ride)
                        showFeedback = true
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.fetchRidesGiven()
        }
    }
    
    private func createFeedbackData(from ride: EachRide) -> FeedBackPreReq {
        FeedBackPreReq(
            rideId: ride.id,
            fromUserId: ride.userId,
            fromUserName: "\(ride.userFirstName ?? "") \(ride.userLastName ?? "")",
            forUserId: ride.rideTakers[0].userId,
            forUserName: "\(ride.rideTakers[0].userFirstName ?? "") \(ride.rideTakers[0].userLastName ?? "")",
            date: ride.date,
            riderType: .giver
        )
    }
}

// MARK: - Ride Card View
private struct RideCardView: View {
    let ride: EachRide
    let viewModel: RidesGivenViewModel
    let onTap: () -> Void
    
    var body: some View {
        RideUserCard(
            personImage: "person.circle.fill",
            imagePath: ride.rideTakers[0].userImage,
            name: ride.rideTakers[0].fullName,
            successRecord: String(format: NSLocalizedString("successfully_completed_rides", comment: ""), ride.noOfCompletedRides),
            distance: viewModel.convertToMiles(ride.rideTakers[0].distance),
            fromLocation: ride.pickupAddress.addressLine1 ?? "--",
            toLocation: ride.dropoffAddress.addressLine1 ?? "--",
            showFavorite: ride.rideTakers[0].favorite,
            onCallTapped: {
                viewModel.makePhoneCall(number: ride.mobileNumber)
            },
            onMessageTapped: {
                viewModel.sendMessage(number: ride.mobileNumber)
            }
        )
        .padding(.horizontal)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Preview
struct RidesGivenView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                RidesGivenView()
            }
            .previewDisplayName("Light Mode")
            
            NavigationView {
                RidesGivenView()
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
} 
