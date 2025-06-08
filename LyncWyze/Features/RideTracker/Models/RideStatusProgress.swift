import Foundation

enum RideStatusProgress: Int, Comparable {
    case scheduled = 0
    case started = 1
    case riderArrived = 2
    case pickedUp = 3
    case arrivedAtActivity = 4
    case activityOngoing = 5
    case returnedActivity = 6
    case pickedUpFromActivity = 7
    case returnedHome = 8
    case completed = 9
    case canceled = 10
    case ongoing = 11
    
    init(from status: RideStatus) {
        switch status {
        case .scheduled: self = .scheduled
        case .started: self = .started
        case .riderArrived: self = .riderArrived
        case .pickedUp: self = .pickedUp
        case .arrivedAtActivity: self = .arrivedAtActivity
        case .activityOngoing: self = .activityOngoing
        case .returnedActivity: self = .returnedActivity
        case .pickedUpFromActivity: self = .pickedUpFromActivity
        case .returnedHome: self = .returnedHome
        case .completed: self = .completed
        case .canceled: self = .canceled
        case .ongoing: self = .ongoing
        }
    }
    
    static func < (lhs: RideStatusProgress, rhs: RideStatusProgress) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
} 