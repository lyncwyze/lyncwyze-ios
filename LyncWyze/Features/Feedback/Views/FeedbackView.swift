import SwiftUI

// Import models and manager from the same module
struct FeedbackView: View {
    @StateObject private var viewModel = FeedbackManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var comments: String = ""
    @State private var isInitialLoading = true
    
    let rideId: String
    let fromUserId: String
    let forUserId: String
    let forUserName: String
    let riderType: RiderType
    let date: String
    
    private let starSize: CGFloat = 22
    private let starSpacing: CGFloat = 12
    
    func formatDateString(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX") // Ensures correct parsing
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM yyyy"
        outputFormatter.locale = Locale.current
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString // fallback if parsing fails
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        Text(String(format: NSLocalizedString("please_rate_your_experience", comment: ""), "\(forUserName) \(date.isEmpty ? "" : "on") \(formatDateString(date))"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if let survey = viewModel.surveyReport {
                            // Rating Categories
                            VStack(alignment: .leading, spacing: 8) {
                                VStack(spacing: 16) {
                                    ForEach(Array(survey.ratings.keys).sorted(), id: \.self) { category in
                                        FeedbackCategoryView(
                                            category: category,
                                            rating: Binding(
                                                get: { Double(survey.ratings[category] ?? 0) },
                                                set: { viewModel.updateRating(category: category, rating: Int($0)) }
                                            )
                                        )
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // Overall Rating
                            HStack(alignment: .center, spacing: 16) {
                                Text(NSLocalizedString("overall_rating", comment: ""))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: starSpacing) {
                                    ForEach(1...5, id: \.self) { index in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: starSize))
                                            .foregroundColor(index <= Int(survey.overallRating.rounded()) ? .yellow : Color(.systemGray4))
                                            .scaleEffect(index <= Int(survey.overallRating.rounded()) ? 1.1 : 0.9)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                            
                            // Comments TextField
                            VStack(alignment: .leading, spacing: 8) {
                                Text(NSLocalizedString("additional_comments", comment: ""))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                ZStack(alignment: .topLeading) {
                                    if comments.isEmpty {
                                        Text(NSLocalizedString("share_experience_placeholder", comment: ""))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                    }
                                    
                                    TextEditor(text: $comments)
                                        .frame(minHeight: 60)
                                        .padding(8)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                        .onChange(of: comments) { newValue in
                                            viewModel.updateComments(newValue)
                                        }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Favorite Button
                            Button(action: {
                                viewModel.toggleFavorite()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.surveyReport?.favorite == true ? "heart.fill" : "heart")
                                        .font(.system(size: 20))
                                        .foregroundColor(viewModel.surveyReport?.favorite == true ? .red : (colorScheme == .dark ? .white : .black))
                                    Text(viewModel.surveyReport?.favorite == true ? NSLocalizedString("unfavorite", comment: "") : NSLocalizedString("favorite", comment: ""))
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                            
                            // Submit Button
                            Button(action: {
                                Task {
                                    await viewModel.submitSurvey()
                                    dismiss()
                                }
                            }) {
                                Text(NSLocalizedString("submit", comment: ""))
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.primaryButton)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .opacity(isInitialLoading || viewModel.isLoading ? 0 : 1)
            
            // Single loading view for both initial and submit states
            if isInitialLoading || viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text(isInitialLoading ? "Loading feedback..." : "Submitting feedback...")
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: $viewModel.showError) {
            Button(NSLocalizedString("ok_button", comment: ""), role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.getReview(
                rideId: rideId,
                fromUserId: fromUserId,
                forUserId: forUserId,
                riderType: riderType
            )
            isInitialLoading = false
        }
        .onReceive(viewModel.$surveyReport) { newSurvey in
            if let survey = newSurvey {
                comments = survey.comments ?? ""
            }
        }
        .withCustomBackButton(showBackButton: true)
    }
}

struct FeedbackCategoryView: View {
    let category: String
    @Binding var rating: Double
    @Environment(\.colorScheme) private var colorScheme
    
    private let starSize: CGFloat = 22
    private let starSpacing: CGFloat = 12
    
    var body: some View {
        HStack {
            Text(NSLocalizedString(category, comment: "Feedback category") != category ? 
                 NSLocalizedString(category, comment: "Feedback category") :
                 category.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: starSpacing) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: starSize))
                        .foregroundColor(index <= Int(rating) ? .yellow : Color(.systemGray4))
                        .scaleEffect(index <= Int(rating) ? 1.0 : 0.8)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                if rating == Double(index) {
                                    rating = 0
                                } else {
                                    rating = Double(index)
                                }
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    Group {
        FeedbackView(
            rideId: "test",
            fromUserId: "user1",
            forUserId: "user2",
            forUserName: "John Doe",
            riderType: .taker,
            date: ""
        )
        .previewDisplayName("Light Mode")
        
        FeedbackView(
            rideId: "test",
            fromUserId: "user1",
            forUserId: "user2",
            forUserName: "John Doe",
            riderType: .taker,
            date: ""
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
} 
