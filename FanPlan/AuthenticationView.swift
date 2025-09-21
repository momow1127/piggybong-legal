import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - Social Authentication View (MVP)
struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingEmailAuth = false
    @State private var isSignUpMode = true  // Start with sign up by default
    let onComplete: () -> Void
    var showDashboard: Binding<Bool>? = nil  // Optional binding for direct dashboard access
    
    var body: some View {
        ZStack {
            // Match onboarding gradient background
            PiggyGradients.background
                .ignoresSafeArea()
            
            if showingEmailAuth {
                EmailAuthView(
                    isSignUpMode: $isSignUpMode,
                    onBack: { }, // Removed back functionality
                    onComplete: onComplete
                )
            } else {
                SocialAuthView(
                    isSignUpMode: $isSignUpMode,
                    onEmailAuth: { showingEmailAuth = true }, 
                    onComplete: onComplete
                )
            }
            
            // MARK: - Development Tools
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    // Auth Test Button - Disabled (AuthTestView not available)
                    Text("🔧 DEBUG AUTH")
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.7))
                        .cornerRadius(8)

                    // Skip Button - TRUE BYPASS (No Auth Service)
                    Button("🚀 DEV: SKIP TO DASHBOARD") {
                        print("🚀 EMERGENCY BYPASS: Skipping ALL authentication")

                        // Create a fake user without using any authentication service
                        let fakeUser = AuthenticationService.AuthUser(
                            id: UUID(),
                            email: "dev@test.com",
                            name: "Dev User",
                            monthlyBudget: 200,
                            createdAt: Date()
                        )

                        // Directly set the authentication state
                        authService.currentUser = fakeUser
                        authService.isAuthenticated = true

                        // Mark onboarding as completed
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

                        // Go directly to dashboard
                        if let dashboardBinding = showDashboard {
                            dashboardBinding.wrappedValue = true
                        } else {
                            self.onComplete()
                        }

                        print("🚀 EMERGENCY BYPASS: Successfully set fake auth state")
                    }
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Social Auth View
struct SocialAuthView: View {
    @Binding var isSignUpMode: Bool
    let onEmailAuth: () -> Void
    let onComplete: () -> Void
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()
    
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(spacing: 24) {
                Text(isSignUpMode ? "Join Piggy Bong" : "Welcome Back")
                    .font(PiggyFont.heroTitle)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(isSignUpMode ? "Start saving for your favorite K-pop artists" : "Sign in to continue your fan journey")
                    .font(PiggyFont.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PiggySpacing.xl)
            }
            
            Spacer()
                .frame(height: 50)
            
            // Auth Buttons
            VStack(spacing: 16) {
                // Apple Sign In (Primary) - Custom implementation to match style
                Button {
                    print("🍎 Apple Sign In button tapped at \(Date())")
                    print("🍎 Mode: \(isSignUpMode ? "Sign Up" : "Sign In")")
                    appleSignInCoordinator.startSignIn(isSignUp: isSignUpMode, termsAccepted: true) { result in
                        print("🍎 Apple Sign In coordinator callback received: \(result)")
                        Task {
                            await handleAppleSignIn(result, isSignUp: isSignUpMode, termsAccepted: true)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        // Fixed-width icon container for perfect alignment
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                        
                        Text("Continue with Apple")
                            .font(.system(size: 19, weight: .medium, design: .default))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white)
                    )
                }
                
                // Google Sign In (Secondary)
                Button {
                    print("🔐 Google Sign In button tapped at \(Date())")
                    print("🔐 Mode: \(isSignUpMode ? "Sign Up" : "Sign In")")
                    Task {
                        await handleGoogleSignIn(isSignUp: isSignUpMode, termsAccepted: true)
                    }
                } label: {
                    HStack(spacing: 8) {
                        // Fixed-width icon container for perfect alignment
                        Image("google")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .frame(width: 24, height: 24)
                        
                        Text("Continue with Google")
                            .font(.system(size: 19, weight: .medium, design: .default))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.white)
                    )
                }
                
                // Email Fallback
                Button {
                    print("📧 Email Sign In button tapped at \(Date())")
                    print("📧 Mode: \(isSignUpMode ? "Sign Up" : "Sign In")")
                    onEmailAuth()
                } label: {
                    HStack(spacing: 8) {
                        // Fixed-width icon container for perfect alignment
                        Image("mail")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                        
                        Text("Continue with Email")
                            .font(.system(size: 19, weight: .medium, design: .default))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, PiggySpacing.lg)
            
            Spacer()
                .frame(height: 24)
            
            // Terms Agreement (for both sign up and log in)
            termsAgreementSection
            
            // Push footer to bottom
            Spacer()
            
            // Footer Toggle Sign In/Up
            Button {
                isSignUpMode.toggle()
            } label: {
                if isSignUpMode {
                    HStack(spacing: 0) {
                        Text("Already have an account? ")
                            .foregroundColor(.piggyTextSecondary)
                        Text("Log in")
                            .foregroundColor(.piggyTextPrimary)
                            .underline()
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 14, weight: .medium))
                } else {
                    HStack(spacing: 0) {
                        Text("New to Piggy Bong? ")
                            .foregroundColor(.piggyTextSecondary)
                        Text("Sign up")
                            .foregroundColor(.piggyTextPrimary)
                            .underline()
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .disabled(authService.isLoading)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
    
    // MARK: - Terms Agreement Section
    private var termsAgreementSection: some View {
        VStack(spacing: 0) {
            Text("By continuing, you agree to our ")
                .foregroundColor(.piggyTextTertiary)
            + Text("Terms")
                .foregroundColor(.piggyTextPrimary)
                .underline()
            + Text(" and ")
                .foregroundColor(.piggyTextTertiary)
            + Text("Privacy Policy")
                .foregroundColor(.piggyTextPrimary)
                .underline()
            + Text(".")
                .foregroundColor(.piggyTextTertiary)
        }
        .font(Font.caption)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24)
        .onTapGesture {
            // Handle taps on the terms text
            LegalDocumentService.shared.openTermsOfService {
                showingTerms = true
            }
        }
    }
    
    // MARK: - Apple Sign In Handler
    private func handleAppleSignIn(_ result: Result<(ASAuthorization, String), Error>, isSignUp: Bool, termsAccepted: Bool) async {
        // Terms are implicitly accepted when continuing
        
        switch result {
        case .success(let (authorization, nonce)):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                print("❌ Apple Sign In: Invalid credential type")
                return
            }
            
            do {
                print("🍎 Apple Sign In: Starting authentication with nonce...")
                try await authService.signInWithApple(credential: appleIDCredential, nonce: nonce)
                print("✅ Apple Sign In: Authentication successful!")
                await MainActor.run {
                    print("🔄 Apple Sign In: Calling onComplete() to proceed to notifications...")
                    onComplete()
                }
            } catch {
                print("❌ Apple Sign In failed: \(error)")
                print("💡 Apple Sign In is not supported in iOS Simulator")
                print("💡 Please use 'Continue with Email' or test on a physical device")
                // For testing in simulator, you can use the email option instead
                await MainActor.run {
                    // Show a helpful alert for simulator users
                    #if targetEnvironment(simulator)
                    print("⚠️ Running in Simulator - Apple Sign In unavailable")
                    #endif
                }
            }
            
        case .failure(let error):
            print("❌ Apple Sign In error: \(error)")
            print("💡 Tip: Apple Sign In may not work in Simulator. Try 'Continue with Email' instead.")
        }
    }
    
    // MARK: - Google Sign In Handler
    private func handleGoogleSignIn(isSignUp: Bool, termsAccepted: Bool) async {
        print("🔐 handleGoogleSignIn started - Mode: \(isSignUp ? "Sign Up" : "Sign In")")

        do {
            print("🔐 Calling authService.signInWithGoogle()...")
            try await authService.signInWithGoogle()
            print("✅ Google Sign In: Authentication successful!")
            await MainActor.run {
                print("🔄 Google Sign In: Calling onComplete() to proceed to notifications...")
                onComplete()
            }
        } catch {
            await MainActor.run {
                print("❌ Google Sign In failed: \(error)")
                print("🔍 Google Sign In error details: \(error.localizedDescription)")

                // Show user-friendly error message instead of crashing
                if error.localizedDescription.contains("URL scheme") {
                    print("💡 URL scheme configuration issue detected")
                    print("💡 For now, please use 'Continue with Email' or the DEV skip button")
                } else if error.localizedDescription.contains("client ID") {
                    print("💡 Google client ID configuration issue detected")
                    print("💡 For now, please use 'Continue with Email' or the DEV skip button")
                } else {
                    print("💡 Google Sign In unavailable - please use 'Continue with Email'")
                }

                // Don't crash the app - just log the error
            }
        }
    }
}

// MARK: - Email Auth View (Fallback)
struct EmailAuthView: View {
    @Binding var isSignUpMode: Bool
    let onBack: () -> Void
    let onComplete: () -> Void
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject private var globalLoading: GlobalLoadingManager

    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingVerification = false
    @State private var showingEmailSent = false
    @State private var showingForgotPassword = false
    @State private var previousEmail = "" // Track the email that hit rate limit
    
    var body: some View {
        Group {
            if showingEmailSent {
                emailSentView
            } else if showingVerification {
                EmailVerificationView(
                    email: email,
                    onVerified: {
                        onComplete()
                    },
                    onChangeEmail: {
                        showingVerification = false
                        // Clear form to allow re-entry
                        email = ""
                        password = ""
                    }
                )
            } else if showingForgotPassword {
                ForgotPasswordView(
                    onBack: {
                        showingForgotPassword = false
                    },
                    onComplete: {
                        showingForgotPassword = false
                        // Show success message
                        alertMessage = "Password reset email sent! Check your inbox."
                        showAlert = true
                    }
                )
            } else {
                emailFormView
            }
        }
    }
    
    private var emailFormView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            // Header (back button intentionally hidden for cleaner auth flow)
            VStack(spacing: PiggySpacing.lg) {
                Text(isSignUpMode ? "Create Account" : "Welcome Back")
                    .font(PiggyFont.heroTitle)
                    .foregroundColor(.piggyTextPrimary)

                Text(isSignUpMode ? "Join the K-pop fan community" : "Sign in with your email")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PiggySpacing.lg)
            
            Spacer()
                .frame(height: 40)
            
            // Form
            VStack(spacing: PiggySpacing.lg) {
                VStack(spacing: PiggySpacing.md) {
                    // Email Field with Label
                    VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                        HStack {
                            Text("Email")
                                .font(PiggyFont.callout)
                                .foregroundColor(.piggyTextSecondary)
                            Spacer()
                        }
                        PiggyTextField(
                            "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                    }

                    // Info text for magic link
                    VStack(spacing: PiggySpacing.sm) {
                        Text("We'll send you a secure login link")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextSecondary)
                            .multilineTextAlignment(.center)

                        Text("Check your email and click the link to sign in")
                            .font(PiggyFont.caption)
                            .foregroundColor(.piggyTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, PiggySpacing.sm)
                }
                
                // Terms Agreement (only for sign up)
                if isSignUpMode {
                    emailTermsAgreementSection
                }
                
                // Magic Link Button
                Button {
                    Task {
                        await handleMagicLinkAuth()
                    }
                } label: {
                    Text("Send Login Link")
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(PiggyGradients.primaryButton)
                )
                // Always keep button active and handle validation in action
                
            }
            .padding(.horizontal, PiggySpacing.lg)
            
            // Push footer to bottom
            Spacer()
            
            // Footer Toggle Sign In/Up (only show for login mode)
            if !isSignUpMode {
                Button {
                    isSignUpMode.toggle()
                } label: {
                    HStack(spacing: 0) {
                        Text("New to Piggy Bong? ")
                            .foregroundColor(.piggyTextSecondary)
                        Text("Sign up")
                            .foregroundColor(.piggyTextPrimary)
                            .underline()
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("Authentication Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Email Sent Success View
    private var emailSentView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            VStack(spacing: 32) {
                // Success Icon
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.green)

                    Text("Check your inbox!")
                        .font(PiggyFont.heroTitle)
                        .foregroundColor(.piggyTextPrimary)
                }

                // Instructions
                VStack(spacing: 16) {
                    Text("We sent a login link to:")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextSecondary)
                        .multilineTextAlignment(.center)

                    Text(email)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                        .padding(.horizontal, PiggySpacing.md)
                        .padding(.vertical, PiggySpacing.sm)
                        .background(Color.piggyCardBackground)
                        .cornerRadius(PiggySpacing.sm)

                    Text("Click the link in your email to sign in securely")
                        .font(PiggyFont.body)
                        .foregroundColor(.piggyTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PiggySpacing.lg)
                }

                Spacer()
                    .frame(height: 40)

                // Action Buttons
                VStack(spacing: PiggySpacing.md) {
                    // Resend Button
                    Button {
                        Task {
                            await handleMagicLinkAuth()
                        }
                    } label: {
                        Text("Didn't receive email? Resend link")
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(Color.piggyPrimary)
                    }
                    .disabled(globalLoading.isVisible)

                    // Back Button
                    Button("Use a different email") {
                        showingEmailSent = false
                        email = ""
                        // Clear rate limit tracking when going back to change email
                        previousEmail = ""
                    }
                    .font(PiggyFont.body)
                    .foregroundColor(.white)
                }
            }
            .padding(.horizontal, PiggySpacing.lg)

            Spacer()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("Authentication Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Email Terms Agreement Section
    private var emailTermsAgreementSection: some View {
        VStack(spacing: 0) {
            Text("By continuing, you agree to our ")
                .foregroundColor(.piggyTextTertiary)
            + Text("Terms")
                .foregroundColor(.piggyTextPrimary)
                .underline()
            + Text(" and ")
                .foregroundColor(.piggyTextTertiary)
            + Text("Privacy Policy")
                .foregroundColor(.piggyTextPrimary)
                .underline()
            + Text(".")
                .foregroundColor(.piggyTextTertiary)
        }
        .font(PiggyFont.caption)
        .multilineTextAlignment(.center)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, PiggySpacing.lg)
        .onTapGesture {
            // Handle taps on the terms text
            LegalDocumentService.shared.openTermsOfService {
                showingTerms = true
            }
        }
    }

    
    private func handleMagicLinkAuth() async {
        // Basic validation before attempting magic link
        guard !email.isEmpty else {
            await MainActor.run {
                alertMessage = "Please enter your email address"
                showAlert = true
            }
            return
        }

        guard email.contains("@") && email.contains(".") else {
            await MainActor.run {
                alertMessage = "Please enter a valid email address"
                showAlert = true
            }
            return
        }

        // Check if this is the same email that hit rate limit
        guard email != previousEmail else {
            await MainActor.run {
                alertMessage = "This email is still rate limited. Please wait 48 seconds or try a different email address."
                showAlert = true
            }
            return
        }

        await MainActor.run {
            globalLoading.showAuthentication()
        }

        do {
            // Send magic link (handles both signup and signin)
            try await authService.sendMagicLink(email: email)

            await MainActor.run {
                globalLoading.hide()
                showingEmailSent = true
            }
        } catch {
            await MainActor.run {
                globalLoading.hide()
                print("📱 Magic link failed: \(error)")
                print("📱 Error description: \(error.localizedDescription)")

                // Provide user-friendly error messages
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("48 seconds") || errorDescription.contains("rate limit") {
                    previousEmail = email // Store the email that hit rate limit
                    alertMessage = "Please wait a moment before requesting another email. For security, you can only request a new link every 48 seconds."
                } else if errorDescription.contains("network") {
                    alertMessage = "Network error. Please check your connection and try again."
                } else {
                    alertMessage = "Failed to send login link: \(error.localizedDescription)"
                }
                showAlert = true
            }
        }
    }
}

// MARK: - Apple Sign In Coordinator
class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var completion: ((Result<ASAuthorization, Error>) -> Void)?
    private var currentNonce: String?
    
    func startSignIn(isSignUp: Bool, termsAccepted: Bool, completion: @escaping (Result<(ASAuthorization, String), Error>) -> Void) {
        self.completion = { result in
            switch result {
            case .success(let authorization):
                completion(.success((authorization, self.currentNonce ?? "")))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Generate and store nonce for validation
        let nonce = generateNonce()
        request.nonce = sha256(nonce)
        self.currentNonce = nonce
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion?(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
    }
    
    // MARK: - Helper Methods
    private func generateNonce(length: Int = 32) -> String {
        let charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        return String((0..<length).compactMap { _ in charset.randomElement() })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    AuthenticationView(
        onComplete: {
            print("Auth completed")
        }
    )
    .environmentObject(AuthenticationService.shared)
    .environmentObject(GlobalLoadingManager.shared)
}
