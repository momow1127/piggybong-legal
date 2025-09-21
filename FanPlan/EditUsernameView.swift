import SwiftUI

struct EditUsernameView: View {
    @Binding var username: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showLimitWarning = false
    
    var body: some View {
        ZStack {
                PiggyGradients.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                        PiggyTextField(
                            "Enter your fandom name",
                            text: $username,
                            style: .primary,
                            size: .large
                        )
                        .onChange(of: username) { _, newValue in
                            // Show warning and limit to 30 characters
                            if newValue.count > 30 {
                                username = String(newValue.prefix(30))
                                showLimitWarning = true

                                // Hide warning after 2 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showLimitWarning = false
                                    }
                                }
                            } else {
                                showLimitWarning = false
                            }
                        }

                        // Warning message (appears when limit exceeded)
                        if showLimitWarning {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)

                                Text("Maximum 30 characters reached")
                                    .font(PiggyFont.caption2)
                                    .foregroundColor(.orange)

                                Spacer()
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Helper text with character counter
                        HStack {
                            Text("Choose a name that represents your fandom identity")
                                .font(PiggyFont.caption2)
                                .foregroundColor(.piggyTextTertiary)

                            Spacer()

                            // Character counter showing remaining
                            let remainingChars = max(0, 30 - username.count)
                            let isNearLimit = username.count >= 24  // 80% of 30
                            let isAtLimit = username.count >= 30

                            Text("\(remainingChars) characters remaining")
                                .font(PiggyFont.caption2)
                                .foregroundColor(
                                    isAtLimit ? .red :
                                    isNearLimit ? .orange :
                                    .piggyTextTertiary
                                )
                        }
                    }

                    Spacer()
                        .frame(height: PiggySpacing.md) // 16pt

                    PiggyButton(
                        title: "Save",
                        action: {
                            onSave()
                            dismiss()
                        },
                        style: .primary,
                        size: .large
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.top, PiggySpacing.xl)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.piggyTextPrimary)
                    }
                }
            }
    }
}

#Preview {
    EditUsernameView(username: .constant("Fan User"), onSave: {})
}