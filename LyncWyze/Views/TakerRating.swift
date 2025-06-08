import SwiftUI

struct RatingView: View {
    @State private var overallRating: Int = 0
    @State private var friendlinessRating: Int = 0
    @State private var drivingRating: Int = 0
    @State private var communicationRating: Int = 0
    @State private var pickupRating: Int = 0
    @State private var kidFriendlinessRating: Int = 0
    @State private var cleanVehicleRating: Int = 0
    @State private var reviewText: String = ""
    @State private var isFavorite: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("How was your ride with Akshay?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Text("The rating will be based on the following criteria:")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                VStack(alignment: .center) {
                    HStack(spacing: 20) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= overallRating ? "star.fill" : "star")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.orange)
                                .onTapGesture {
                                    overallRating = star
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)

                // Individual Rating Categories
                VStack(alignment: .center, spacing: 30) {
                    RatingCategoryView(title: "Friendliness", rating: $friendlinessRating)
                    RatingCategoryView(title: "Responsible Driving", rating: $drivingRating)
                    RatingCategoryView(title: "Communication", rating: $communicationRating)
                    RatingCategoryView(title: "On-Time Pickup and Drop-off", rating: $pickupRating)
                    RatingCategoryView(title: "Kid Companion Friendliness", rating: $kidFriendlinessRating)
                    RatingCategoryView(title: "Clean Vehicle", rating: $cleanVehicleRating)
                }
                .frame(maxWidth: .infinity)

                // Review Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Write a Review")
                        .font(.headline)
                        .fontWeight(.bold)
                    TextEditor(text: $reviewText)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                }

                // Favorite Button (Repositioned)
                HStack {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                    Text("Favorite")
                        .foregroundColor(.gray)
                }
                .onTapGesture {
                    isFavorite.toggle()
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)

                // Submit Button
                Button(action: {
                    submitReview()
                }) {
                    Text("Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    func submitReview() {
        // Submit review logic
        print("Overall Rating: \(overallRating)")
        print("Friendliness: \(friendlinessRating)")
        print("Responsible Driving: \(drivingRating)")
        print("Communication: \(communicationRating)")
        print("On-Time Pickup: \(pickupRating)")
        print("Kid Friendliness: \(kidFriendlinessRating)")
        print("Clean Vehicle: \(cleanVehicleRating)")
        print("Review: \(reviewText)")
        print("Favorite: \(isFavorite)")
    }
}

struct RatingCategoryView: View {
    let title: String
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            HStack(spacing: 20) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            rating = star
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RatingView()
    }
}
