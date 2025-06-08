import SwiftUI

struct StartYourJourney: View {
    var hasReferralName: String
    var selectedPlaceId: String
    @StateObject private var viewModel = AddressSelectionViewModel()
    @State private var navigateToLogin = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Text(NSLocalizedString("great_news", comment: ""))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .fixedSize(horizontal: false, vertical: true)

                Image("carpool")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)

                VStack(spacing: 15) {
                    StatisticItem(icon: "person.fill", value: "60K", description: NSLocalizedString("real_time_users", comment: ""))
                    StatisticItem(icon: "mappin.and.ellipse", value: "10K", description: NSLocalizedString("carpools_scheduled", comment: ""))
                    StatisticItem(icon: "leaf.fill", value: "5K", description: NSLocalizedString("co2_saved", comment: ""))
                }
                .padding(.horizontal, 20)

                Spacer()

                NavigationLink(NSLocalizedString("start_journey", comment: ""), value: "LoginView")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("ColorSubmitButton"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.all)
            .navigationDestination(for: String.self) { value in
                if value == "LoginView" {
                    EmailSignupView()
                }
            }
        }
    }
}
