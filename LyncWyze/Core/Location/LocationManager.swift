import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    private let locationManager = CLLocationManager()
    private var locationUpdateHandler: ((Result<[Double], Error>) -> Void)?
    private var singleLocationContinuation: CheckedContinuation<[Double], Error>?
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location when device moves by 10 meters
        
        // Only enable background updates if background location capability is added
        if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String],
           backgroundModes.contains("location") {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        }
        
        // Request location authorization if not determined
        if locationManager.authorizationStatus == .notDetermined {
            requestLocationPermission()
        }
    }
    
    func requestLocationPermission() {
        // First, request "when in use" permission
        locationManager.requestWhenInUseAuthorization()
        
        // After getting "when in use", request "always" permission if needed for background updates
        if locationManager.authorizationStatus == .authorizedWhenInUse,
           let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String],
           backgroundModes.contains("location") {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func startUpdatingLocation(completion: @escaping (Result<[Double], Error>) -> Void) {
        locationUpdateHandler = completion
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            requestLocationPermission()
        case .denied, .restricted:
            let error = NSError(
                domain: "LocationManager",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Location access denied. Please enable location services in Settings.",
                    NSLocalizedRecoverySuggestionErrorKey: "Go to Settings > Privacy > Location Services to enable location access."
                ]
            )
            completion(.failure(error))
        @unknown default:
            let error = NSError(
                domain: "LocationManager",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Unknown location authorization status"]
            )
            completion(.failure(error))
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationUpdateHandler = nil
        singleLocationContinuation = nil
    }
    
    private func cleanupSingleLocationRequest() {
        locationManager.stopUpdatingLocation()
        singleLocationContinuation = nil
    }
    
    func getCurrentCoordinates() async throws -> [Double] {
        // If we already have a recent location, use it
        if let location = currentLocation,
           Date().timeIntervalSince(location.timestamp) < 10 { // Location is less than 10 seconds old
            return [location.coordinate.latitude, location.coordinate.longitude]
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Store the continuation for later use
            singleLocationContinuation = continuation
            
            // Check current authorization status first
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
                
            case .notDetermined:
                requestLocationPermission()
                locationManager.startUpdatingLocation()
                
            case .denied, .restricted:
                let error = NSError(
                    domain: "LocationManager",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Location access denied. Please enable location services in Settings.",
                        NSLocalizedRecoverySuggestionErrorKey: "Go to Settings > Privacy > Location Services to enable location access."
                    ]
                )
                continuation.resume(throwing: error)
                cleanupSingleLocationRequest()
                
            @unknown default:
                let error = NSError(
                    domain: "LocationManager",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Unknown location authorization status"]
                )
                continuation.resume(throwing: error)
                cleanupSingleLocationRequest()
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        let coordinates = [location.coordinate.latitude, location.coordinate.longitude]
        
        // Handle single location request
        if let continuation = singleLocationContinuation {
            continuation.resume(returning: coordinates)
            cleanupSingleLocationRequest()
            return
        }
        
        // Handle continuous location updates
        locationUpdateHandler?(.success(coordinates))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        
        // Handle single location request
        if let continuation = singleLocationContinuation {
            continuation.resume(throwing: error)
            cleanupSingleLocationRequest()
            return
        }
        
        // Handle continuous location updates
        locationUpdateHandler?(.failure(error))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Start updating location if we have a handler waiting
            if locationUpdateHandler != nil || singleLocationContinuation != nil {
                locationManager.startUpdatingLocation()
            }
        case .denied, .restricted:
            let error = NSError(
                domain: "LocationManager",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Location access denied. Please enable location services in Settings.",
                    NSLocalizedRecoverySuggestionErrorKey: "Go to Settings > Privacy > Location Services to enable location access."
                ]
            )
            
            // Handle single location request
            if let continuation = singleLocationContinuation {
                continuation.resume(throwing: error)
                cleanupSingleLocationRequest()
            }
            
            // Handle continuous location updates
            locationUpdateHandler?(.failure(error))
        default:
            break
        }
    }
} 