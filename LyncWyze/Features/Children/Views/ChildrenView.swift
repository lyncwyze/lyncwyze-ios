//
//  ChildrenView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 10/03/25.
//
import SwiftUI

struct ChildrenView: View {
    @StateObject private var childrenManager = ChildrenManager()
    @State private var showAddChild = false
    @State private var showingEditSheet = false
    @State private var selectedChild: Child?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("review_update_children", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            if childrenManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxHeight: .infinity)
            } else if let error = childrenManager.error {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.largeTitle)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button(NSLocalizedString("retry", comment: "")) {
                        childrenManager.fetchChildren()
                    }
                    .foregroundColor(Color.primaryButton)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else if childrenManager.children.isEmpty {
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .stroke(Color.primaryButton, lineWidth: 2)
                            .frame(width: 50, height: 50)
                        Text("!")
                            .foregroundColor(Color.primaryButton)
                            .font(.title2)
                    }
                    Text(NSLocalizedString("no_child_added", comment: ""))
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(childrenManager.children) { child in
                        Button(action: {
                            selectedChild = child
                            showingEditSheet = true
                        }) {
                            ChildRowView(
                                child: child,
                                childrenManager: childrenManager
                            )
                        }
                        .listRowBackground(Color(.systemGray6))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete(perform: childrenManager.deleteChild)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    childrenManager.fetchChildren()
                }
                .navigationDestination(isPresented: $showingEditSheet) {
                    if let selectedChild = selectedChild {
                        EditChildView(child: selectedChild, childrenManager: childrenManager, isPresented: $showingEditSheet)
                    }
                }
            }

            VStack(spacing: 12) {
                NavigationLink(
                    destination: AddChildInfoView(
                        childrenManager: childrenManager,
                        showBackButton: true
                    )
                ) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text(NSLocalizedString("add_children", comment: ""))
                    }
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

//                Button(action: {}) {
//                    Text("Continue")
//                        .fontWeight(.medium)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 12)
//                        .background(Color.mint)
//                        .cornerRadius(8)
//                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(NSLocalizedString("children", comment: ""))
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
            }
        }
        .withCustomBackButton()
    }
}

struct ChildrenView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChildrenView()
                .preferredColorScheme(.light)
            
            ChildrenView()
                .preferredColorScheme(.dark)
        }
    }
}
