import SwiftUI

struct FeedbackView: View {
    @StateObject private var feedbackService = FeedbackService.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: FeedbackType = .bug
    @State private var subject = ""
    @State private var message = ""
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            Form {
                    // Feedback Type Selection
                    Section("What's on your mind?") {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(Color(red: 255/255, green: 192/255, blue: 203/255))
                                    .frame(width: 30)

                                Text(type.title)

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(red: 255/255, green: 192/255, blue: 203/255))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedType = type
                            }
                        }
                    }

                    // Subject
                    Section("Subject") {
                        TextField("Brief description...", text: $subject)
                            .textFieldStyle(.plain)
                    }

                    // Message
                    Section("Details") {
                        TextEditor(text: $message)
                            .frame(minHeight: 100)
                            .placeholder(when: message.isEmpty) {
                                Text("Tell us more...")
                                    .foregroundColor(.gray)
                            }
                    }

                    // Quick Templates
                    if selectedType == .bug {
                        Section("Quick Info (Optional)") {
                            Button("Add Steps to Reproduce") {
                                message += "\n\nSteps to reproduce:\n1. \n2. \n3. "
                            }

                            Button("Add Expected vs Actual") {
                                message += "\n\nExpected: \nActual: "
                            }
                        }
                    }

                    // Submit Button
                    Section {
                        Button(action: submitFeedback) {
                            HStack {
                                if feedbackService.isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text("Send Feedback")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                        }
                        .listRowBackground(Color(red: 255/255, green: 192/255, blue: 203/255))
                        .disabled(subject.isEmpty || message.isEmpty || feedbackService.isSubmitting)
                    }
                }
                .navigationTitle("Feedback")
                .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Thank You! 🎉", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your feedback helps make PiggyBong better for everyone!")
            }
        }
    }

    private func submitFeedback() {
        Task {
            do {
                try await feedbackService.submitFeedback(
                    type: selectedType,
                    subject: subject,
                    message: message,
                    screenName: "FeedbackView"
                )

                await MainActor.run {
                    showingSuccess = true
                }
            } catch {
                print("Error submitting feedback: \(error)")
                // Show error alert
            }
        }
    }
}

// Helper extension for placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}