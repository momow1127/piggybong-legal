import SwiftUI
import RevenueCat

struct SimplePaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @State private var promoCode = ""
    @State private var showPromoCode = false
    @State private var showVipSuccess = false
    @State private var shouldNavigateToAddIdol = false
    @State private var buttonState: ButtonState = .default
    @State private var codeButtonState: ButtonState = .default
    @State private var promoErrorMessage: String? = nil
    @State private var showPromoSuccess = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isPromoFieldFocused: Bool
    
    enum ButtonState: Equatable {
        case `default`
        case loading
        case success
        case error(String)
    }
    
    let triggerContext: PaywallTriggerContext?
    
    init(triggerContext: PaywallTriggerContext? = nil) {
        self.triggerContext = triggerContext
    }
    
    var body: some View {
        ZStack {
            // Background
            PiggyGradients.background
                .ignoresSafeArea()

            // Main content with consistent modal structure
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: PiggySpacing.lg) {
                        // Header Section (inline title)
                        paywallHeaderSection

                        // Features Section Title
                        titleSection

                        // Features Section
                        featuresSection

                        // Promo code section
                        promoCodeSection
                            .id("promoCodeSection")

                        // Pricing section
                        pricingSection
                            .id("pricingSection")

                        // Footer
                        footerSection

                        // Bottom spacing with keyboard handling
                        Spacer(minLength: keyboardHeight > 0 ? keyboardHeight + PiggySpacing.xl : PiggySpacing.xxl)
                    }
                    .padding(.top, PiggySpacing.sm)
                    .padding(.horizontal, PiggySpacing.md)
                    .padding(.bottom, PiggySpacing.xl)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping outside text fields
                    isPromoFieldFocused = false
                    hideKeyboard()
                }
                .onChange(of: isPromoFieldFocused) { _, focused in
                    if focused {
                        // Scroll to promo code section when field is focused with delay for keyboard animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo("promoCodeSection", anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: keyboardHeight) { _, height in
                    if height > 0 && isPromoFieldFocused {
                        // Ensure promo code section stays visible when keyboard appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("promoCodeSection", anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .overlay(alignment: .center) {
            if showVipSuccess {
                vipSuccessOverlay
                    .zIndex(999)
                    .onAppear {
                        print("🎉 DEBUG: VIP Success Overlay appeared!")
                    }
            }
        }
    }
    
    // MARK: - Sections

    // MARK: - Header Section (inline title)
    private var paywallHeaderSection: some View {
        HStack {
            Text("Upgrade to VIP")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)

            Spacer()

            PiggyIconButton(
                "xmark",
                size: .medium,
                style: .tertiary,
                action: { dismiss() }
            )
        }
    }

    private var titleSection: some View {
        VStack(spacing: PiggySpacing.md) {
            Text("💜 Piggy Bong VIP")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(getContextualSubtitle())
                .font(.title3)
                .foregroundColor(.piggyTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: PiggySpacing.md) {
            ForEach(simplePremiumFeatures, id: \.title) { feature in
                SimpleFeatureRow(feature: feature)
            }
        }
    }
    
    private var promoCodeSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            if !showPromoCode {
                // Collapsed state - "Have a promo code?" link
                Button("Have a promo code?") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showPromoCode = true
                        promoErrorMessage = nil
                    }
                    piggyHapticFeedback(.light)
                    
                    // Auto-focus the text field after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPromoFieldFocused = true
                    }
                }
                .foregroundColor(.piggyTextSecondary)
                .font(PiggyFont.caption)
            } else {
                // Expanded state - text field and apply button
                VStack(spacing: PiggySpacing.xs) {
                    HStack(spacing: PiggySpacing.sm) {
                        PiggyTextField(
                            "Have a promo code?",
                            text: $promoCode,
                            size: .small,
                            validation: promoErrorMessage != nil ? .error(promoErrorMessage!) : .normal
                        )
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .focused($isPromoFieldFocused)
                        .onSubmit {
                            // Apply promo code when user hits return
                            if !promoCode.isEmpty && codeButtonState != .loading {
                                applyPromoCode()
                            }
                        }
                        
                        if showPromoSuccess {
                            HStack(spacing: PiggySpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                Text("Applied!")
                                    .font(PiggyFont.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, PiggySpacing.md)
                            .frame(height: PiggyButton.PiggyButtonSize.small.height)
                            .background(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            PiggyButton(
                                title: "Apply",
                                action: applyPromoCode,
                                style: .secondary,
                                size: .small
                            )
                            .disabled(promoCode.isEmpty || globalLoading.isVisible)
                        }
                    }
                    
                    // Error message display
                    if let errorMessage = promoErrorMessage {
                        Text(errorMessage)
                            .font(PiggyFont.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(.updatesFrequently)
                            .transition(.opacity)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var pricingSection: some View {
        VStack(spacing: PiggySpacing.md) {
            // Main CTA with states
            Button(action: startFreeTrial) {
                HStack {
                    switch buttonState {
                    case .loading:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                        Text("Processing...")
                            .font(PiggyFont.bodyEmphasized)
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                        Text("Success!")
                            .font(PiggyFont.bodyEmphasized)
                    case .error:
                        Text("Try Free for 7 Days")
                            .font(PiggyFont.bodyEmphasized)
                    case .default:
                        Text("Try Free for 7 Days")
                            .font(PiggyFont.bodyEmphasized)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                        .fill(PiggyGradients.primaryButton)
                )
                .shadow(color: Color.piggyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(buttonState == .loading ? 0.98 : 1.0)
            }
            .disabled(globalLoading.isVisible || buttonState == .success)
            
            // Price info
            Text("$0.00 today, then $2.99/month")
                .font(PiggyFont.caption)
                .foregroundColor(.piggyTextSecondary)
            
            // Promo code section removed - now above pricing
            
            // Action buttons
            HStack(spacing: PiggySpacing.xxl) {
                Button(action: restorePurchases) {
                    Text("Restore Purchase")
                }
                .foregroundColor(.white)
                .font(PiggyFont.caption)
                .disabled(globalLoading.isVisible)
                
                Button("Privacy Policy") {
                    LegalDocumentService.shared.openPrivacyPolicy {
                        if let url = URL(string: LegalDocumentService.shared.getPrivacyPolicyURL()) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .foregroundColor(.piggyTextSecondary)
                .font(PiggyFont.caption)
            }
        }
    }
    
    
    private var footerSection: some View {
        VStack(spacing: PiggySpacing.sm) {
            Text("Cancel at any time")
                .font(PiggyFont.caption)
                .foregroundColor(.piggyTextTertiary)
            
            HStack(spacing: PiggySpacing.md) {
                Button(action: {
                    LegalDocumentService.shared.openTermsOfService { 
                        // Fallback: Open URL directly if service fails
                        if let url = URL(string: LegalDocumentService.shared.getTermsOfServiceURL()) {
                            UIApplication.shared.open(url)
                        }
                    }
                }) {
                    Text("Terms of Use")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                        .underline()
                }
                
                Button(action: {
                    LegalDocumentService.shared.openPrivacyPolicy {
                        // Fallback: Open URL directly if service fails  
                        if let url = URL(string: LegalDocumentService.shared.getPrivacyPolicyURL()) {
                            UIApplication.shared.open(url)
                        }
                    }
                }) {
                    Text("Privacy Policy")
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                        .underline()
                }
            }
        }
        .padding(.bottom, PiggySpacing.lg)
    }
    
    // MARK: - Success Screen
    
    private var vipSuccessOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent taps from going through
                }
            
            VStack(spacing: PiggySpacing.lg) {
                // Success Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(showVipSuccess ? 1.2 : 0.1)
                        .opacity(showVipSuccess ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showVipSuccess)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .scaleEffect(showVipSuccess ? 1.0 : 0.1)
                        .opacity(showVipSuccess ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showVipSuccess)
                }
                
                VStack(spacing: PiggySpacing.sm) {
                    Text("🎉 VIP Unlocked!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showVipSuccess ? 1.0 : 0.5)
                        .opacity(showVipSuccess ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showVipSuccess)
                    
                    Text(shouldNavigateToAddIdol ? "Now you can add up to 6 idols!" : "You're all set — enjoy your premium fan powers.")
                        .font(PiggyFont.bodyLarge)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .scaleEffect(showVipSuccess ? 1.0 : 0.8)
                        .opacity(showVipSuccess ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(0.6), value: showVipSuccess)
                }
            }
            .padding(PiggySpacing.xl)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper Functions
    
    private func getContextualSubtitle() -> String {
        guard let context = triggerContext else {
            return "Track all your favorite K-pop artists"
        }
        
        switch context {
        case .fourthArtistLimit:
            return "Track unlimited artists without limits"
        case .premiumAICoaching:
            return "Get AI-powered comeback planning"
        case .advancedGoals:
            return "Advanced goal tracking & insights"
        case .generalUpgrade:
            return "Unlock all premium features"
        case .vipTips:
            return "Get personalized VIP spending tips"
        }
    }
    
    private func startFreeTrial() {
        globalLoading.show(LoadingMessage.processingPayment, simpleMode: false, priority: .critical)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        revenueCatManager.purchaseMonthlySubscription { success, error in
            DispatchQueue.main.async {
                globalLoading.hide()

                if success {
                    buttonState = .success
                    let successImpact = UIImpactFeedbackGenerator(style: .heavy)
                    successImpact.impactOccurred()

                    // Dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                } else {
                    buttonState = .error(error?.localizedDescription ?? "Purchase failed")

                    // Reset to default after showing error
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        buttonState = .default
                    }
                }
            }
        }
    }
    
    private func restorePurchases() {
        globalLoading.show(LoadingMessage.processingPayment, simpleMode: true, priority: .high)

        revenueCatManager.restorePurchases { success, error in
            DispatchQueue.main.async {
                globalLoading.hide()

                if success {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    dismiss()
                }
            }
        }
    }
    
    private func applyPromoCode() {
        globalLoading.show(LoadingMessage.processingPayment, simpleMode: true, priority: .high)
        promoErrorMessage = nil

        piggyHapticFeedback(.light)

        // Check for judge promo code
        if promoCode.uppercased() == "PIGGYVIP25" {
            DispatchQueue.main.async {
                globalLoading.hide()

                // Grant 3 minutes of VIP access for judges
                codeButtonState = .success
                showPromoSuccess = true

                piggyHapticFeedback(.success)

                // Activate temporary VIP for 3 minutes
                revenueCatManager.activateTemporaryVIP(minutes: 3)

                // IMMEDIATELY sync SubscriptionService with new VIP status
                SubscriptionService.shared.updateSubscriptionStatus(from: revenueCatManager)

                // Show success screen first, then dismiss
                print("🎉 DEBUG: Setting showVipSuccess to true")
                piggyHapticFeedback(.success)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showVipSuccess = true
                }
                shouldNavigateToAddIdol = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    print("🎉 DEBUG: Dismissing paywall after success screen")
                    dismiss()
                }
            }
        } else {
            // Try regular promo code
            revenueCatManager.applyPromoCode(promoCode) { success, error in
                DispatchQueue.main.async {
                    globalLoading.hide()

                    if success {
                        self.codeButtonState = .success
                        self.showPromoSuccess = true
                        self.promoErrorMessage = nil

                        piggyHapticFeedback(.success)

                        // Show success screen first, then dismiss
                        print("🎉 DEBUG: Setting showVipSuccess to true (nested)")
                        piggyHapticFeedback(.success)
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showVipSuccess = true
                        }
                        shouldNavigateToAddIdol = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            print("🎉 DEBUG: Dismissing paywall after success screen (nested)")
                            self.dismiss()
                        }
                    } else {
                        self.codeButtonState = .default
                        self.promoErrorMessage = error?.localizedDescription ?? "Invalid promo code"

                        piggyHapticFeedback(.error)

                        // Clear error after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                self.promoErrorMessage = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            handleKeyboardShow(notification)
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            handleKeyboardHide()
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func handleKeyboardShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        // Convert keyboard frame to local coordinates
        let keyboardHeight = keyboardFrame.height
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            self.keyboardHeight = keyboardHeight
        }
        
        print("📱 Keyboard shown: height = \(keyboardHeight)")
    }
    
    private func handleKeyboardHide() {
        withAnimation(.easeInOut(duration: 0.3)) {
            keyboardHeight = 0
        }
        print("📱 Keyboard hidden")
    }

    /// Helper function to hide keyboard programmatically
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Feature Row Component

struct SimpleFeatureRow: View {
    let feature: SimplePremiumFeature
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text(feature.title)
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.white)
                
                if let description = feature.description {
                    Text(description)
                        .font(PiggyFont.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, PiggySpacing.md)
        .padding(.vertical, PiggySpacing.md)
    }
}

// MARK: - Models

struct SimplePremiumFeature {
    let title: String
    let description: String?
    
    init(_ title: String, _ description: String? = nil) {
        self.title = title
        self.description = description
    }
}

enum PaywallTriggerContext {
    case fourthArtistLimit
    case premiumAICoaching
    case advancedGoals
    case generalUpgrade
    case vipTips
}

// MARK: - Data

let simplePremiumFeatures = [
    SimplePremiumFeature("Track Up to 6 Artists", "vs 3 artists in free plan"),
    SimplePremiumFeature("AI Priority Coach", "Smart comeback recommendations"),
    SimplePremiumFeature("Priority Alerts", "First to know about tours & drops")
]

// MARK: - PaywallModalContent for PiggyModal

struct PaywallModalContent: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @EnvironmentObject private var globalLoading: GlobalLoadingManager
    @State private var promoCode = ""
    @State private var showPromoCode = false
    @State private var showVipSuccess = false
    @State private var shouldNavigateToAddIdol = false
    @State private var buttonState: ButtonState = .default
    @State private var codeButtonState: ButtonState = .default
    
    enum ButtonState: Equatable {
        case `default`
        case loading
        case success
        case error(String)
    }
    
    let triggerContext: PaywallTriggerContext?
    
    init(triggerContext: PaywallTriggerContext? = nil) {
        self.triggerContext = triggerContext
    }
    
    var body: some View {
        ZStack {
            // Background
            PiggyGradients.background
                .ignoresSafeArea()

            // Main scroll content
            ScrollView {
                VStack(spacing: PiggySpacing.lg) {
                    // Header Section (inline title)
                    paywallModalHeaderSection

                    // Main title
                    VStack(spacing: PiggySpacing.xs) {
                        Text("Upgrade to Piggy Bong VIP")
                            .font(PiggyFont.title1)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Unlock premium K-pop fan features")
                            .font(PiggyFont.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Feature list with emoji icons
                    VStack(alignment: .leading, spacing: PiggySpacing.lg) {
                        VipEmojiFeatureRow(
                            emoji: "✨",
                            title: "Smart AI budgeting based on your fan type"
                        )
                        
                        VipEmojiFeatureRow(
                            emoji: "🗓",
                            title: "Personalized comeback + concert tracker"
                        )
                        
                        VipEmojiFeatureRow(
                            emoji: "⭐️",
                            title: "Priority ranking to make better tradeoffs"
                        )
                        
                        VipEmojiFeatureRow(
                            emoji: "🔓",
                            title: "Unlock 3 bonus groups and custom goals"
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Bottom spacing to allow for fixed pricing section
                    Spacer(minLength: 200)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, PiggySpacing.sm)
                .padding(.horizontal, PiggySpacing.md)
                .padding(.bottom, PiggySpacing.xl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: PiggySpacing.md) {
                // Price info
                (Text("$0.00 today, then ") +
                Text("$2.99")
                    .fontWeight(.bold) +
                Text("/month. Cancel anytime."))
                    .font(PiggyFont.caption)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
                
                // Call-to-action button
                Button(action: startFreeTrial) {
                    HStack {
                        switch buttonState {
                        case .loading:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                            Text("Processing...")
                                .font(PiggyFont.bodyEmphasized)
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                            Text("Success!")
                                .font(PiggyFont.bodyEmphasized)
                        case .error:
                            Text("Start Free Trial for 7 Days")
                                .font(PiggyFont.bodyEmphasized)
                        case .default:
                            Text("Start Free Trial for 7 Days")
                                .font(PiggyFont.bodyEmphasized)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.button)
                            .fill(PiggyGradients.primaryButton)
                    )
                    .shadow(color: Color.piggyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    .scaleEffect(buttonState == .loading ? 0.98 : 1.0)
                }
                .disabled(globalLoading.isVisible || buttonState == .success)
                
                // Promo code section (always visible)
                HStack(spacing: PiggySpacing.md) {
                    // Custom TextField for better placeholder visibility
                    ZStack(alignment: .leading) {
                        if promoCode.isEmpty {
                            Text("Enter a promo code")
                                .foregroundColor(.white.opacity(0.6))
                                .font(PiggyFont.body)
                                .padding(.horizontal, PiggySpacing.md)
                        }
                        
                        TextField("", text: $promoCode)
                            .font(PiggyFont.body)
                            .foregroundColor(.white)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .padding(.horizontal, PiggySpacing.md)
                            .padding(.vertical, PiggyComponentSize.medium.verticalPadding)
                            .frame(height: PiggyComponentSize.medium.height)
                            .background(Color.piggyCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: PiggyBorderRadius.input)
                                    .stroke(Color.piggyBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PiggyBorderRadius.input))
                    }
                    
                    PiggyButton(
                        title: {
                            switch codeButtonState {
                            case .loading: return "Validating..."
                            case .success: return "Applied!"
                            case .error: return "Invalid"
                            case .default: return "Apply"
                            }
                        }(),
                        action: applyPromoCode,
                        style: .primary,
                        size: .medium
                    )
                    .disabled(promoCode.isEmpty || globalLoading.isVisible)
                    .frame(width: 80)
                }
                
                // Privacy footer
                VStack(spacing: PiggySpacing.md) {
                    // Action buttons row with smaller text
                    HStack(spacing: 8) {
                        Button(action: {
                            print("🔗 Paywall: Terms of Service button tapped")
                            LegalDocumentService.shared.openTermsOfService {
                                print("⚠️ Paywall: Terms of Service fallback triggered")
                            }
                        }) {
                            Text("Terms of Service")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.piggyTextSecondary)
                                .underline()
                        }
                        
                        Text("|")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Button(action: {
                            print("🔗 Paywall: Privacy Policy button tapped")
                            LegalDocumentService.shared.openPrivacyPolicy {
                                print("⚠️ Paywall: Privacy Policy fallback triggered")
                            }
                        }) {
                            Text("Privacy Policy")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.piggyTextSecondary)
                                .underline()
                        }
                        
                        Text("|")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Button(action: restorePurchases) {
                            Text("Restore Purchase")
                                .font(.system(size: 10, weight: .regular))
                        }
                        .foregroundColor(.piggyTextSecondary)
                        .disabled(globalLoading.isVisible)
                    }
                }
            }
            .padding(.horizontal, PiggySpacing.lg)
            .padding(.bottom, PiggySpacing.md)
        }
    }
    
    // MARK: - Header Section
    private var paywallModalHeaderSection: some View {
        HStack {
            Text("Upgrade to VIP")
                .font(PiggyFont.title2)
                .foregroundColor(.piggyTextPrimary)

            Spacer()

            PiggyIconButton(
                "xmark",
                size: .medium,
                style: .tertiary,
                action: { dismiss() }
            )
        }
    }

    // MARK: - Helper Functions

    private func startFreeTrial() {
        globalLoading.show(LoadingMessage.processingPayment, simpleMode: false, priority: .critical)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        revenueCatManager.purchaseMonthlySubscription { success, error in
            DispatchQueue.main.async {
                globalLoading.hide()

                if success {
                    buttonState = .success
                    let successImpact = UIImpactFeedbackGenerator(style: .heavy)
                    successImpact.impactOccurred()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        dismiss()
                    }
                } else {
                    buttonState = .error(error?.localizedDescription ?? "Purchase failed")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        buttonState = .default
                    }
                }
            }
        }
    }
    
    private func restorePurchases() {
        globalLoading.show(LoadingMessage.processingPayment, simpleMode: true, priority: .high)

        revenueCatManager.restorePurchases { success, error in
            DispatchQueue.main.async {
                globalLoading.hide()

                if success {
                    piggyHapticFeedback(.success)
                    dismiss()
                }
            }
        }
    }
    
    private func applyPromoCode() {
        globalLoading.show(LoadingMessage.processingPayment, simpleMode: true, priority: .high)

        if promoCode.uppercased() == "PIGGYVIP25" {
            DispatchQueue.main.async {
                globalLoading.hide()

                codeButtonState = .success
                piggyHapticFeedback(.success)

                revenueCatManager.activateTemporaryVIP(minutes: 3)

                // IMMEDIATELY sync SubscriptionService with new VIP status
                SubscriptionService.shared.updateSubscriptionStatus(from: revenueCatManager)

                // Show success screen first, then dismiss
                print("🎉 DEBUG: Setting showVipSuccess to true")
                piggyHapticFeedback(.success)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showVipSuccess = true
                }
                shouldNavigateToAddIdol = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    print("🎉 DEBUG: Dismissing paywall after success screen")
                    dismiss()
                }
            }
        } else {
            revenueCatManager.applyPromoCode(promoCode) { success, error in
                DispatchQueue.main.async {
                    globalLoading.hide()

                    if success {
                        codeButtonState = .success
                        piggyHapticFeedback(.success)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    } else {
                        codeButtonState = .error("Invalid code")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            codeButtonState = .default
                            promoCode = ""
                        }
                    }
                }
            }
        }
    }
}

// MARK: - VIP Emoji Feature Row Component

struct VipEmojiFeatureRow: View {
    let emoji: String
    let title: String
    
    var body: some View {
        HStack(spacing: PiggySpacing.md) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 32, height: 32, alignment: .center)
            
            Text(title)
                .font(PiggyFont.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    PaywallModalContent(triggerContext: .advancedGoals)
        .environmentObject(RevenueCatManager.shared)
}
