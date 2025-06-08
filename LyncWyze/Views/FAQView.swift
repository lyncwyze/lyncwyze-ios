import SwiftUI

struct FAQSection: Identifiable {
    let id = UUID()
    let title: String
    let questions: [FAQ]
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FAQView: View {
    @State private var selectedSection: UUID?
    @State private var selectedQuestion: UUID?
    
    let sections = [
        FAQSection(title: "About LyncWyze", questions: [
            FAQ(question: "What is LyncWyze?",
                answer: "LyncWyze is a specialized ride-sharing platform designed to provide safe and reliable transportation for children and families. We focus on connecting parents with trusted drivers for school runs, after-school activities, and other child-related transportation needs."),
            FAQ(question: "Who can use LyncWyze?",
                answer: "LyncWyze is available for:\n• Parents and legal guardians\n• Children (accompanied by authorized adults)\n• Verified and background-checked drivers\n• Schools and educational institutions\n• After-school activity providers")
        ]),
        
        FAQSection(title: "Vehicle Related", questions: [
            FAQ(question: "What types of vehicles are used?",
                answer: "All vehicles must meet our strict safety standards:\n• Not older than 7 years\n• Regular safety inspections\n• Proper child safety seats when required\n• Clean and well-maintained\n• Full insurance coverage"),
            FAQ(question: "Are child safety seats provided?",
                answer: "Yes, drivers can provide appropriate child safety seats upon request. Parents can also provide their own seats for consistent use.")
        ]),
        
        FAQSection(title: "Child Safety", questions: [
            FAQ(question: "How do you ensure child safety?",
                answer: "We prioritize safety through:\n• Comprehensive background checks\n• Real-time ride tracking\n• Driver verification\n• Emergency contact system\n• Zero-tolerance safety policy"),
            FAQ(question: "Can I track my child's ride?",
                answer: "Yes, our app provides real-time tracking, ride status updates, and direct communication with drivers during the ride.")
        ]),
        
        FAQSection(title: "Ride Related", questions: [
            FAQ(question: "How do I schedule a ride?",
                answer: "You can schedule rides through the app:\n• One-time rides\n• Recurring rides (e.g., school pickup)\n• Advanced booking up to 2 weeks\n• Emergency same-day booking"),
            FAQ(question: "What's your cancellation policy?",
                answer: "Rides can be cancelled:\n• Free cancellation up to 12 hours before\n• Partial fee within 12-2 hours\n• Full fee for last-minute cancellations")
        ]),
        
        FAQSection(title: "Activities", questions: [
            FAQ(question: "What activities do you support?",
                answer: "We provide transportation for:\n• School pickup/drop-off\n• Sports practices\n• Music lessons\n• Medical appointments\n• Other extracurricular activities"),
            FAQ(question: "Can I set up regular activity schedules?",
                answer: "Yes, you can set up recurring rides for regular activities with our schedule management feature.")
        ])
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sections) { section in
                    FAQSectionView(
                        section: section,
                        isExpanded: selectedSection == section.id,
                        selectedQuestion: $selectedQuestion,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if selectedSection == section.id {
                                    selectedSection = nil
                                    selectedQuestion = nil
                                } else {
                                    selectedSection = section.id
                                    selectedQuestion = nil
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle("FAQs")
        .background(Color(.systemGroupedBackground))
        .withCustomBackButton(showBackButton: true)
    }
}

struct FAQSectionView: View {
    let section: FAQSection
    let isExpanded: Bool
    @Binding var selectedQuestion: UUID?
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
            
            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(section.questions) { faq in
                        FAQQuestionView(
                            faq: faq,
                            isExpanded: selectedQuestion == faq.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if selectedQuestion == faq.id {
                                        selectedQuestion = nil
                                    } else {
                                        selectedQuestion = faq.id
                                    }
                                }
                            }
                        )
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.top, 1)
            }
        }
    }
}

struct FAQQuestionView: View {
    let faq: FAQ
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(faq.question)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "minus.circle.fill" : "plus.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.medium)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            
            if isExpanded {
                Text(faq.answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
}

struct FAQView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FAQView()
        }
    }
} 
