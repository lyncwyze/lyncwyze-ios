//
//  EmergencyContactsView.swift
//  LyncWyze
//
//  Created by Abhijeet Nag on 11/03/25.
//
import SwiftUI

struct EmergencyContactsView: View {
    @StateObject private var contactsManager = EmergencyContactsManager()
    @State private var showingAddContact = false
    @State private var selectedContact: EmergencyContact?
    @State private var showingEditSheet = false
    
//    init() {
//        showBackButton = true
//        isOnboardingComplete = true
//    }
   
    
    var body: some View {
        ZStack {
            if contactsManager.contacts.isEmpty && !contactsManager.isLoading {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(NSLocalizedString("no_emergency_contacts", comment: ""))
                        .font(.headline)
                    Text(NSLocalizedString("add_emergency_contacts_message", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List {
                    ForEach(contactsManager.contacts) { contact in
                        EmergencyContactCard(contact: contact)
                            .onTapGesture {
                                selectedContact = contact
                                showingEditSheet = true
                            }
                            .onAppear {
                                contactsManager.loadMoreIfNeeded(currentItem: contact)
                            }
                    }
                    
                    if contactsManager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.primaryButton))
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(GroupedListStyle())
                .scrollContentBackground(.hidden) // Remove default background
                .refreshable {
                    contactsManager.fetchContacts(refresh: true)
                }
            }
            
            VStack {
                Spacer()
                Button {
                    showingAddContact = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text(NSLocalizedString("add_emergency_contact", comment: ""))
                    }
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryButton)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(NSLocalizedString("emergency_contact", comment: ""))
                    .font(.title)
                    .bold()
            }
        }
        .withCustomBackButton(showBackButton: true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingAddContact) {
                HandleEmergencyContactView(contactsManager: contactsManager)
        }
        .navigationDestination(isPresented: $showingEditSheet) {
            if let contact = selectedContact {
                    HandleEmergencyContactView(
                        contactsManager: contactsManager,
                        contact: contact
                    )
            }
        }
        .alert(NSLocalizedString("error_alert_title", comment: ""), isPresented: Binding(
            get: { contactsManager.error != nil },
            set: { if !$0 { contactsManager.error = nil } }
        )) {
            Button(NSLocalizedString("ok_button", comment: "")) {
                contactsManager.error = nil
            }
        } message: {
            if let error = contactsManager.error {
                Text(error)
            }
        }
        .onAppear {
            contactsManager.fetchContacts(refresh: true)
        }
    }
}

struct EmergencyContactCard: View {
    let contact: EmergencyContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(contact.firstName) \(contact.lastName)")
                        .font(.headline)
                    
                    Text(contact.mobileNumber)
                        .font(.subheadline)
                    
                    if let email = contact.email, !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}


#Preview {
    NavigationView {
        EmergencyContactsView()
    }
}
