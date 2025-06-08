import SwiftUI

struct ActivityDetailView: View {
    @StateObject private var activityManager = ActivityManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDay: String? = nil  // Initially no day is selected
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let child: Child
    
    private func getCurrentDayAbbreviation() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: Date())
    }
    
    var addActivityButton: some View {
        NavigationLink(
            destination: AddUpdateActivityView(child: child)
        ) {
            HStack {
                Image(systemName: "plus.circle")
                Text("add_more_activity")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primaryButton)
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(String(format: NSLocalizedString("activity_details_title", comment: ""), child.firstName, child.lastName))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Days of week
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(days, id: \.self) { day in
                        VStack {
                            Text(day)
                                .foregroundColor(selectedDay == day ? .white : .primary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(selectedDay == day ? Color.primaryButton : Color(.systemGray6))
                                )
                                .onTapGesture {
                                    selectedDay = day
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 15) {
                    if activityManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                    } else if let error = activityManager.error {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task {
                                    await activityManager.fetchActivities(childId: child.apiId ?? "")
                                }
                            }
                            .foregroundColor(Color.primaryButton)
                        }
                        .padding()
                    } else if let selectedDay = selectedDay {
                        let dayActivities = activityManager.activities.filter { activity in
                            activity.schedulePerDay[AppUtility.mapDayToAPIFormat(selectedDay)] != nil
                        }
                        
                        if dayActivities.isEmpty {
                            Text(String(format: NSLocalizedString("no_activities_scheduled_for_day", comment: ""), selectedDay))
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                        } else {
                            ForEach(dayActivities) { activity in
                                NavigationLink(
                                    destination: AddUpdateActivityView(
                                        child: child,
                                        activityToEdit: activity
                                    )
                                ) {
                                    ActivityRow(activity: activity, selectedDay: selectedDay)
                                }
                            }
                        }
                    } else {
                        let allActivities = activityManager.activities
                        if allActivities.isEmpty {
                            Text("no_activities_scheduled")
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                        } else {
                            ForEach(allActivities) { activity in
                                NavigationLink(destination: AddUpdateActivityView(child: child, activityToEdit: activity)) {
                                    VStack(spacing: 5) {
                                        ForEach(Array(activity.schedulePerDay.keys.sorted()), id: \.self) { day in
                                            if let schedule = activity.schedulePerDay[day] {
                                                ActivityRow(activity: activity, selectedDay: AppUtility.mapAPIFormatToDay(day))
                                                    .padding(.bottom, 5)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                if let childId = child.apiId {
                    await activityManager.fetchActivities(childId: childId)
                }
            }
            
            addActivityButton
                .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .withCustomBackButton(showBackButton: true)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Set current day as selected day
            selectedDay = getCurrentDayAbbreviation()
            
            // Fetch activities when view appears
            if let childId = child.apiId {
                await activityManager.fetchActivities(childId: childId)
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
//        default: return ""
//        }
//    }
//    
//    private func mapAPIFormatToDay(_ day: String) -> String {
//        switch day {
//        case "MONDAY": return "Mon"
//        case "TUESDAY": return "Tue"
//        case "WEDNESDAY": return "Wed"
//        case "THURSDAY": return "Thu"
//        case "FRIDAY": return "Fri"
//        case "SATURDAY": return "Sat"
//        case "SUNDAY": return "Sun"
//        default: return ""
//        }
//    }
}

struct ActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActivityDetailView(child: Child(firstName: "John", lastName: "Doe"))
                .preferredColorScheme(.light)
            
            ActivityDetailView(child: Child(firstName: "John", lastName: "Doe"))
                .preferredColorScheme(.dark)
        }
    }
}

