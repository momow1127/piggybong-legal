import SwiftUI

// MARK: - Email Verification View (Code-Based)
struct EmailVerificationView: View {
    let email: String
    let onVerified: () -> Void
    let onChangeEmail: () -> Void

    private let authService = AuthenticationService.shared
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @State private var verificationCode = ""
    @State private var resendCooldown = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Timer for resend cooldown
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                PiggyGradients.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Verification Icon
                    VStack(spacing: PiggySpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.piggyPrimary.opacity(0.2), Color.piggyPrimary.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "envelope.badge.checkmark")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.piggyPrimary)
                        }
                        
                        // Header
                        VStack(spacing: PiggySpacing.md) {
                            Text("Enter Verification Code")
                                .font(PiggyFont.heroTitle)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("We've sent a 6-digit code to")
                                .font(PiggyFont.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Text(email)
                                .font(PiggyFont.bodyEmphasized)
                                .foregroundColor(.piggyAccent)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, PiggySpacing.md)
                                .padding(.vertical, PiggySpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: PiggyBorderRadius.sm)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                    
                    Spacer()
                        .frame(height: 50)
                    
                    // Verification Code Input
                    VStack(spacing: PiggySpacing.md) {
                        Text("Enter the 6-digit code")
                            .font(PiggyFont.callout)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Code Input Field
                        HStack(spacing: 8) {
                            ForEach(0..<6, id: \.self) { index in
                                VerificationDigitView(
                                    digit: getDigit(at: index),
                                    isActive: index == verificationCode.count
                                )
                            }
                        }
                        .onTapGesture {
                            // Focus on the text field (hidden)
                        }
                        
                        // Hidden TextField for input
                        TextField("", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .onChange(of: verificationCode) { _, newValue in
                                // Limit to 6 digits
                                let filtered = String(newValue.prefix(6).filter { $0.isNumber })
                                if filtered != newValue {
                                    verificationCode = filtered
                                }
                                
                                // Auto-verify when 6 digits entered
                                if filtered.count == 6 {
                                    Task {
                                        await verifyCode()
                                    }
                                }
                            }
                            .opacity(0)
                            .frame(height: 0)
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                    
                    Spacer()
                        .frame(height: 50)
                    
                    // Action Buttons
                    VStack(spacing: PiggySpacing.md) {
                        // Verify Code Button (Manual)
                        Button {
                            Task {
                                await verifyCode()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Verify Code")
                                    .font(PiggyFont.bodyEmphasized)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: PiggySpacing.buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                    .fill(verificationCode.count == 6 ? AnyShapeStyle(PiggyGradients.primaryButton) : AnyShapeStyle(Color.gray))
                            )
                        }
                        .disabled(verificationCode.count != 6 || globalLoading.isVisible)
                        .padding(.horizontal, PiggySpacing.lg)
                        
                        // Resend Code Button
                        Button {
                            Task {
                                await resendVerificationCode()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                                
                                if resendCooldown > 0 {
                                    Text("Resend in \(resendCooldown)s")
                                        .font(.system(size: 14, weight: .medium))
                                } else {
                                    Text("Resend Code")
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .disabled(globalLoading.isVisible || resendCooldown > 0)
                        
                        // Change Email Button
                        Button {
                            onChangeEmail()
                        } label: {
                            Text("Use Different Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .underline()
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true) // Ensure no back button in verification flow
            .alert("Verification", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Auto-focus on the code input for better UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // This will help show the keyboard immediately
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getDigit(at index: Int) -> String {
        guard index < verificationCode.count else { return "" }
        return String(verificationCode[verificationCode.index(verificationCode.startIndex, offsetBy: index)])
    }
    
    // MARK: - Verification Actions
    private func verifyCode() async {
        guard verificationCode.count == 6 else { return }

        globalLoading.show(LoadingMessage.emailVerification, simpleMode: false, priority: .high)

        do {
            let isValid = try await authService.verifyEmailCode(email: email, code: verificationCode)

            if isValid {
                await MainActor.run {
                    globalLoading.hide()
                    timer?.invalidate()
                    onVerified()
                }
            } else {
                await MainActor.run {
                    globalLoading.hide()
                    alertMessage = "Invalid verification code. Please check your email and try again."
                    showAlert = true
                    verificationCode = ""
                }
            }
        } catch {
            await MainActor.run {
                globalLoading.hide()
                alertMessage = "Verification failed: \(error.localizedDescription)"
                showAlert = true
                verificationCode = ""
            }
        }
    }
    
    private func resendVerificationCode() async {
        globalLoading.show(LoadingMessage.emailVerification, simpleMode: true, priority: .high)

        do {
            try await authService.resendVerificationCode(email: email)

            await MainActor.run {
                globalLoading.hide()
                alertMessage = "New verification code sent! Please check your email."
                showAlert = true
                verificationCode = "" // Clear current input

                // Start cooldown
                startResendCooldown()
            }
        } catch {
            await MainActor.run {
                globalLoading.hide()
                alertMessage = "Failed to send code: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func startResendCooldown() {
        resendCooldown = 60 // 60 seconds cooldown
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
    
}

// MARK: - Verification Digit View
struct VerificationDigitView: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isActive ? 0.2 : 0.1))
                .stroke(
                    isActive ? Color.piggyPrimary : Color.white.opacity(0.3),
                    lineWidth: isActive ? 2 : 1
                )
                .frame(width: 45, height: 55)
            
            // Digit Text
            Text(digit)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            
            // Active indicator
            if isActive && digit.isEmpty {
                Rectangle()
                    .fill(Color.piggyPrimary)
                    .frame(width: 2, height: 24)
                    .opacity(0.8)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isActive
                    )
            }
        }
    }
}

#Preview {
    EmailVerificationView(
        email: "user@example.com",
        onVerified: {
            print("Email verified!")
        },
        onChangeEmail: {
            print("Change email requested")
        }
    )
    .environmentObject(GlobalLoadingManager.shared)
}