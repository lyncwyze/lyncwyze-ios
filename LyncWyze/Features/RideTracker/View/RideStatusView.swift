import SwiftUI

struct RideStatusView: View {
    let rideType: RideType
    let status: RideStatus
    
    private var statusProgress: RideStatusProgress {
        RideStatusProgress(from: status)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if rideType != .pick {
                dropOffStatusView
            }
            
            if rideType != .drop {
                pickupStatusView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var dropOffStatusView: some View {
        VStack(spacing: 16) {
            StatusStep(
                isCompleted: statusProgress >= .started,
                title: "Started",
                subtitle: "Ride has started"
            )
            
            StatusStep(
                isCompleted: statusProgress >= .pickedUp,
                title: "Picked Up",
                subtitle: "Rider picked up from home"
            )
            
            StatusStep(
                isCompleted: statusProgress >= .arrivedAtActivity,
                title: "Dropped Off",
                subtitle: "Dropped at activity location"
            )
        }
    }
    
    private var pickupStatusView: some View {
        VStack(spacing: 16) {
            StatusStep(
                isCompleted: statusProgress >= .returnedActivity,
                title: "Started Return",
                subtitle: "Started return journey"
            )
            
            StatusStep(
                isCompleted: statusProgress >= .pickedUpFromActivity,
                title: "Picked Up",
                subtitle: "Picked up from activity"
            )
            
            StatusStep(
                isCompleted: statusProgress >= .returnedHome,
                title: "Dropped Off",
                subtitle: "Dropped at home"
            )
        }
    }
}

struct StatusStep: View {
    let isCompleted: Bool
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
} 