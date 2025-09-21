import SwiftUI

struct ForgotPasswordView: View {
    let onBack: () -> Void
    let onComplete: () -> Void
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        ZStack {
            // Same background as login screen
            PiggyGradients.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - matching login screen style
                VStack(spacing: PiggySpacing.lg) {
                    // Back Button - styled to match
                    HStack {
                        Button {
                            onBack()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                    .padding(.top, PiggySpacing.sm)
                    
                    // Title and description - matching login screen
                    Text("Reset Password")
                        .font(PiggyFont.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(PiggyFont.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PiggySpacing.lg)
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.top, PiggySpacing.sm)
                
                Spacer()
                    .frame(height: 40)
                
                // Form - exactly matching login screen style
                VStack(spacing: PiggySpacing.lg) {
                    VStack(spacing: PiggySpacing.md) {
                        // Email Field with Label - same as login
                        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                            HStack {
                                Text("Email")
                                    .font(PiggyFont.callout)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                            }
                            PiggyTextField(
                                "Enter your email address",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                        }
                    }
                    
                    // Reset Button - matching login screen button style
                    Button {
                        Task {
                            await handlePasswordReset()
                        }
                    } label: {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Send Reset Email")
                                .font(PiggyFont.bodyEmphasized)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: PiggySpacing.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                            .fill(PiggyGradients.primaryButton)
                    )
                    .disabled(email.isEmpty || authService.isLoading)
                    .opacity(email.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, PiggySpacing.lg)
                
                // Push footer to bottom - same as login screen
                Spacer()
                
                // Footer - matching login screen footer style
                Button {
                    onBack()
                } label: {
                    (Text("Remember your password? ")
                        .foregroundColor(Color(.systemGray)) +
                     Text("Back to Sign In")
                        .foregroundColor(.piggyAccent)
                        .underline()
                        .fontWeight(.medium))
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert(isSuccess ? "Email Sent" : "Error", isPresented: $showAlert) {
            Button("OK") {
                if isSuccess {
                    onComplete()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handlePasswordReset() async {
        // Basic email validation
        guard !email.isEmpty else {
            await MainActor.run {
                alertMessage = "Please enter your email address"
                isSuccess = false
                showAlert = true
            }
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            await MainActor.run {
                alertMessage = "Please enter a valid email address"
                isSuccess = false
                showAlert = true
            }
            return
        }
        
        do {
            try await authService.resetPassword(email: email)
            await MainActor.run {
                alertMessage = "Password reset email sent successfully! Please check your inbox and follow the instructions to reset your password."
                isSuccess = true
                showAlert = true
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to send reset email. Please try again or contact support if the problem persists."
                isSuccess = false
                showAlert = true
            }
        }
    }
}

#Preview {
    ForgotPasswordView(
        onBack: {
            print("Back tapped")
        },
        onComplete: {
            print("Reset completed")
        }
    )
}