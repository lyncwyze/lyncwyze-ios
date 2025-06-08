//
//  ScheduleRideActivityListView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 18/03/25.
//

import SwiftUI
import Toasts

struct ScheduleRideActivityDetailView: View {
    @StateObject private var activityManager = ActivityManager.shared
    @StateObject private var validDaysViewModel = ScheduleRideValidDaysViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentToast) var presentToast
    @State private var selectedDay: String? = nil  // Initially no day is selected
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let child: Child

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
                    if activityManager.isLoading || validDaysViewModel.isLoading {
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
                            Button(NSLocalizedString("retry_button", comment: "")) {
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
                            Text(String(format: NSLocalizedString("no_activities_scheduled", comment: ""), selectedDay))
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                        } else {
                            ForEach(dayActivities) { activity in
                                let apiDay = AppUtility.mapDayToAPIFormat(selectedDay)
                                let isValidDay = validDaysViewModel.isDayValid(apiDay)
                                NavigationLink(
                                    destination: ScheduleRideConfirmActivity(
                                        activityId: activity.id ?? "",
                                        activityDay: apiDay,
                                        isValidDay: isValidDay
                                    )
                                ) {
                                    ActivityRow(activity: activity, selectedDay: selectedDay)
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
                validDaysViewModel.fetchValidDays()
            }
        }
        .background(Color(.systemBackground))
        .withCustomBackButton(showBackButton: true)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Set current day as selected only if no day is selected
            if selectedDay == nil {
                let calendar = Calendar.current
                let today = calendar.component(.weekday, from: Date())
                // Convert from 1-7 (Sunday-Saturday) to 0-6 (Monday-Sunday)
                let adjustedIndex = (today + 5) % 7
                selectedDay = days[adjustedIndex]
            }
            
            // Fetch activities and valid days when view appears
            if let childId = child.apiId {
                await activityManager.fetchActivities(childId: childId)
            }
            validDaysViewModel.fetchValidDays()
        }
    }
}

struct ScheduleRideActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScheduleRideActivityDetailView(
                child: Child(firstName: "John", lastName: "Doe")
            )
            .preferredColorScheme(.light)
            
            ScheduleRideActivityDetailView(
                child: Child(firstName: "John", lastName: "Doe")
            )
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    ScheduleRideActivityDetailView(
        child: Child(firstName: "John", lastName: "Doe")
    )
}

