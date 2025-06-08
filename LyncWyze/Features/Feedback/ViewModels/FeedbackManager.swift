import Foundation
import SwiftUI

// MARK: - View Model
@MainActor
class FeedbackManager: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var surveyReport: SurveyReport?
    @Published var feedbackPreReq: FeedBackPreReq?
    
    private let networkManager = NetworkManager.shared
    
    func getReview(rideId: String, fromUserId: String, forUserId: String, riderType: RiderType) async {
        isLoading = true
        
        let data = SurveyReport(
            rideId: rideId,
            reviewerId: fromUserId,
            revieweeId: forUserId,
            reviewerRole: riderType,
            ratings: [:],
            overallRating: 0.0,
            favorite: false,
            comments: nil
        )
        
        do {
            let result: Result<SurveyReport, Error> = await withCheckedContinuation { continuation in
                networkManager.makeRequest(
                    endpoint: "/match/getReview",
                    method: .POST,
                    body: try? JSONEncoder().encode(data)
                ) { (result: Result<SurveyReport, Error>) in
                    continuation.resume(returning: result)
                }
            }
            
            switch result {
            case .success(let response):
                surveyReport = response
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func submitSurvey() async {
        guard let survey = surveyReport else { return }
        isLoading = true
        
        do {
            let result: Result<SurveyReport, Error> = await withCheckedContinuation { continuation in
                networkManager.makeRequest(
                    endpoint: "/match/submitReview",
                    method: .POST,
                    body: try? JSONEncoder().encode(survey)
                ) { (result: Result<SurveyReport, Error>) in
                    continuation.resume(returning: result)
                }
            }
            
            switch result {
            case .success(let response):
                surveyReport = response
            case .failure(let error):
                showError = true
                errorMessage = error.localizedDescription
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleFavorite() {
        surveyReport?.favorite.toggle()
    }
    
    func updateRating(category: String, rating: Int) {
        surveyReport?.ratings[category] = rating
        updateOverallRating()
    }
    
    func updateComments(_ comments: String) {
        surveyReport?.comments = comments
    }
    
    private func updateOverallRating() {
        guard let survey = surveyReport, !survey.ratings.isEmpty else { return }
        let total = Double(survey.ratings.values.reduce(0, +))
        surveyReport?.overallRating = total / Double(survey.ratings.count)
    }
} 
