struct TimeSlot {
    var startHour: Int
    var startMinute: Int
    var startIsAM: Bool
    var endHour: Int
    var endMinute: Int
    var endIsAM: Bool
    var role: String?
    var rideOption: RideOption?
    var pickupTime: String?
    
    init(
        startHour: Int = 7,
        startMinute: Int = 0,
        startIsAM: Bool = true,
        endHour: Int = 8,
        endMinute: Int = 0,
        endIsAM: Bool = true,
        role: String? = nil,
        rideOption: RideOption? = nil,
        pickupTime: String? = nil
    ) {
        self.startHour = startHour
        self.startMinute = startMinute
        self.startIsAM = startIsAM
        self.endHour = endHour
        self.endMinute = endMinute
        self.endIsAM = endIsAM
        self.role = role
        self.rideOption = rideOption
        self.pickupTime = pickupTime
    }
} 