import SwiftUI

struct DeleteAccountModalContent: View {
    @Binding var isPresented: Bool
    let onDeleteConfirmed: () -> Void
    @State private var isDeleting = false

    var body: some View {
        VStack(spacing: PiggySpacing.lg) {
            // Close button in top-right corner
            HStack {
                Spacer()
                PiggyIconButton(
                    "xmark",
                    size: .medium,
                    style: .tertiary,
                    action: { isPresented = false }
                )
            }
            .padding(.top, PiggySpacing.sm)

            // Warning icon with proper styling
            Image("delete")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.budgetRed)

            // Simplified main message
            Text("Are you sure you want to delete your PiggyBong account? This will erase all your fan activity and data forever.")
                .font(PiggyFont.body)
                .foregroundColor(.piggyTextPrimary)
                .multilineTextAlignment(.center)

            // Action buttons with proper design system
            VStack(spacing: PiggySpacing.md) {
                // Delete button
                PiggyButton(
                    title: isDeleting ? "Deleting..." : "Delete My Account",
                    action: {
                        if !isDeleting {
                            isDeleting = true
                            onDeleteConfirmed()
                        }
                    },
                    style: .destructive,
                    size: .large,
                    isLoading: isDeleting
                )
                .disabled(isDeleting)

                // Cancel button
                PiggyButton(
                    title: "Cancel",
                    action: { isPresented = false },
                    style: .cancel,
                    size: .large
                )
            }
            .padding(.top, PiggySpacing.lg)
        }
    }
}

#Preview {
    DeleteAccountModalContent(
        isPresented: .constant(true),
        onDeleteConfirmed: {
            print("Delete confirmed")
        }
    )
}