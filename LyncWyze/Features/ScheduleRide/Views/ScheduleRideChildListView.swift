//
//  ScheduleRideChildListView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 18/03/25.
//

import SwiftUI

struct ScheduleRideChildListView: View {
    @StateObject private var childrenManager = ChildrenManager()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedChild: Child? = nil
    @State private var navigateToScheduleRideActivityList = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
                
            if childrenManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else if childrenManager.children.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("no_children_added", comment: ""))
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("add_children_message", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                VStack {
                    Text(NSLocalizedString("choose_child_message", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(childrenManager.children) { child in
                                ChildListItemView(child: child)
                                    .onTapGesture {
                                        selectedChild = child
                                        navigateToScheduleRideActivityList = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
                .refreshable {
                    await childrenManager.fetchChildren()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(NSLocalizedString("select_child_title", comment: ""))
                    .font(.title)
                    .foregroundColor(.primary)
                    .bold()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .withCustomBackButton(showBackButton: true)
        .navigationDestination(isPresented: $navigateToScheduleRideActivityList) {
            if let child = selectedChild {
                ScheduleRideActivityDetailView(child: child)
            }
        }
        .task {
            await childrenManager.fetchChildren()
        }
    }
}

struct ScheduleRideChildListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ScheduleRideChildListView()
                    .preferredColorScheme(.light)
            }
            
            NavigationView {
                ScheduleRideChildListView()
                    .preferredColorScheme(.dark)
            }
        }
    }
}

