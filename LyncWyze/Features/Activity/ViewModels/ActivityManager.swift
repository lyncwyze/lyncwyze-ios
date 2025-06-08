import SwiftUI

class ActivityManager: ObservableObject {
    static let shared = ActivityManager() // Singleton instance
    
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    func fetchActivities(childId: String, pageSize: Int = 1000, offset: Int = 0, sortOrder: String = "ASC") async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        let parameters = [
            "childId": childId,
            "pageSize": "\(pageSize)",
            "offSet": "\(offset)",
            "sortOrder": sortOrder
        ]
        
        do {
            let result: PaginatedResponse<Activity> = try await withCheckedThrowingContinuation { continuation in
                networkManager.makeRequest(
                    endpoint: "/user/getActivities",
                    method: .GET,
                    parameters: parameters
                ) { (result: Result<PaginatedResponse<Activity>, Error>) in
                    continuation.resume(with: result)
                }
            }
            
            await MainActor.run {
                self.activities = result.data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func addActivity(_ activity: Activity) async throws -> Activity {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // First, if we have an image, upload it separately
        var activityWithImage = activity
//        if let image = image {
//            do {
//                let imageUrl = try await uploadActivityImage(image)
//                activityWithImage.image = imageUrl
//            } catch {
//                await MainActor.run {
//                    self.isLoading = false
//                    self.error = "Failed to upload image: \(error.localizedDescription)"
//                }
//                throw error
//            }
//        }
        
        // Convert schedule days to uppercase format
        var convertedSchedule: [String: DailySchedule] = [:]
        for (day, schedule) in activityWithImage.schedulePerDay {
            let upperDay = AppUtility.mapDayToAPIFormat(day)
            convertedSchedule[upperDay] = schedule
        }
        activityWithImage.schedulePerDay = convertedSchedule
        
        // Now send the activity data as JSON
        let headers = ["Content-Type": "application/json"]
        
        // Encode the activity to Data
        let jsonData = try JSONEncoder().encode(activityWithImage)
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.makeRequest(
                endpoint: "/user/addActivity",
                method: .POST,
                headers: headers,
                body: jsonData
            ) { [weak self] (result: Result<Activity, Error>) in
                Task { @MainActor in
                    self?.isLoading = false
                    switch result {
                    case .success(let activity):
                        self?.activities.append(activity)
                        continuation.resume(returning: activity)
                    case .failure(let error):
                        self?.error = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
//    private func mapDayToAPIFormat(_ day: String) -> String {
//        switch day {
//        case "Mon": return "MONDAY"
//        case "Tue": return "TUESDAY"
//        case "Wed": return "WEDNESDAY"
//        case "Thu": return "THURSDAY"
//        case "Fri": return "FRIDAY"
//        case "Sat": return "SATURDAY"
//        case "Sun": return "SUNDAY"
//        default: return day // Return as is if already in correct format
//        }
//    }
    
    private func uploadActivityImage(_ image: UIImage) async throws -> String {
        var formData = NetworkManager.MultipartFormData()
        formData.append(image, name: "file", fileName: "activity_image.jpg")
        
        let requestData = formData.finalize()
        let headers = ["Content-Type": formData.contentType]
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.makeRequest(
                endpoint: "/user/uploadImage",
                method: .POST,
                headers: headers,
                body: requestData
            ) { (result: Result<ImageUploadResponse, Error>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.path)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateActivity(_ activity: Activity) async throws -> Activity {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // First, if we have an image, upload it separately
        var activityWithImage = activity
//        if let image = image {
//            do {
//                let imageUrl = try await uploadActivityImage(image)
//                activityWithImage.image = imageUrl
//            } catch {
//                await MainActor.run {
//                    self.isLoading = false
//                    self.error = "Failed to upload image: \(error.localizedDescription)"
//                }
//                throw error
//            }
//        }
        
        // Convert schedule days to uppercase format
        var convertedSchedule: [String: DailySchedule] = [:]
        for (day, schedule) in activityWithImage.schedulePerDay {
            let upperDay = AppUtility.mapDayToAPIFormat(day)
            convertedSchedule[upperDay] = schedule
        }
        activityWithImage.schedulePerDay = convertedSchedule
        
        // Now send the activity data as JSON
        let headers = ["Content-Type": "application/json"]
        
        // Encode the activity to Data
        let jsonData = try JSONEncoder().encode(activityWithImage)
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.makeRequest(
                endpoint: "/user/updateActivity",
                method: .POST,
                headers: headers,
                body: jsonData
            ) { [weak self] (result: Result<Activity, Error>) in
                Task { @MainActor in
                    self?.isLoading = false
                    switch result {
                    case .success(let updatedActivity):
                        if let index = self?.activities.firstIndex(where: { $0.id == activity.id }) {
                            self?.activities[index] = updatedActivity
                        }
                        continuation.resume(returning: updatedActivity)
                    case .failure(let error):
                        self?.error = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func fetchActivityById(activityId: String) async throws -> Activity {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        let parameters = ["activityId": activityId]
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.makeRequest(
                endpoint: "/user/getActivityById",
                method: .GET,
                parameters: parameters
            ) { [weak self] (result: Result<Activity, Error>) in
                Task { @MainActor in
                    self?.isLoading = false
                    switch result {
                    case .success(let activity):
                        continuation.resume(returning: activity)
                    case .failure(let error):
                        self?.error = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func deleteActivity(activityId: String) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        let parameters = ["activityId": activityId]
        
        return try await withCheckedThrowingContinuation { continuation in
            networkManager.makeRequest(
                endpoint: "/user/deleteActivity",
                method: .DELETE,
                parameters: parameters
            ) { [weak self] (result: Result<EmptyResponse, Error>) in
                Task { @MainActor in
                    self?.isLoading = false
                    switch result {
                    case .success(_):
                        // Remove the activity from the local array
                        if let index = self?.activities.firstIndex(where: { $0.id == activityId }) {
                            self?.activities.remove(at: index)
                        }
                        continuation.resume()
                    case .failure(let error):
                        self?.error = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

// Add this structure to handle image upload response
struct ImageUploadResponse: Codable {
    let path: String
} 
