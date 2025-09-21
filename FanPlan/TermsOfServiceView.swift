import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Piggy Bong gradient background
            PiggyGradients.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: PiggySpacing.lg) {
                    // Page Header
                    AppHeaderView(
                        title: "Terms of Service",
                        showAvatar: false,
                        applyHorizontalPadding: false
                    )
                    
                    // Header Section
                    headerSection
                    
                    // GitHub Pages Notice
                    githubPagesNotice
                    
                    // Terms Content
                    termsContent
                }
                .padding(.horizontal, LayoutTokens.pageX)
                .padding(.bottom, PiggySpacing.xl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            
            Text("Last Updated: August 29, 2025")
                .font(PiggyFont.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Effective Date: August 29, 2025")
                .font(PiggyFont.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(PiggySpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.xl)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Terms Content
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.lg) {
            // Section 1: Acceptance of Terms
            termsSection(
                title: "1. Acceptance of Terms",
                content: """
Welcome to Piggy Bong, a K-pop fan budget management application. These Terms of Service constitute a legally binding agreement between you and Piggy Bong regarding your use of our mobile application.

By downloading, installing, or using Piggy Bong, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy.

Age Requirements:
• You must be at least 13 years old to create an account
• Users under 18 require parental consent
• We do not knowingly collect information from children under 13
"""
            )
            
            // Section 2: Description of Service
            termsSection(
                title: "2. Description of Service",
                content: """
Piggy Bong provides budget management tools specifically designed for K-pop fans, including:
• Monthly budget tracking and expense categorization
• K-pop artist selection and budget allocation
• Savings goals for concerts, albums, and merchandise
• Purchase tracking and spending analysis
• Artist-focused financial planning tools

Premium Features:
• AI-powered budget recommendations and insights
• Unlimited savings goals (free users limited to 3)
• Advanced analytics and spending reports
• Data export functionality (CSV/JSON)
• Cloud backup and multi-device sync
"""
            )
            
            // Section 3: User Accounts
            termsSection(
                title: "3. User Accounts and Registration",
                content: """
To access certain features, you must create an account by providing:
• Valid email address
• Display name
• Monthly budget information
• K-pop artist preferences

You are responsible for:
• Maintaining the confidentiality of your account credentials
• All activities that occur under your account
• Notifying us immediately of any unauthorized access
"""
            )
            
            // Section 4: Subscription Terms
            termsSection(
                title: "4. Subscription Terms and Billing",
                content: """
Subscription Plans:
• Premium Monthly: $4.99/month with 7-day free trial
• Premium Annual: $39.99/year with 7-day free trial (33% savings)

Free Trial:
• New users receive a 7-day free trial of Premium features
• Trial automatically converts to paid subscription unless cancelled
• Cancel anytime during trial period to avoid charges

Billing is processed through Apple App Store and subscriptions auto-renew unless cancelled at least 24 hours before renewal.
"""
            )
            
            // Section 5: Acceptable Use
            termsSection(
                title: "5. Acceptable Use Policy",
                content: """
You may use Piggy Bong for:
• Personal budget management and financial planning
• Tracking expenses related to K-pop interests
• Setting and monitoring savings goals

You agree NOT to:
• Use the Service for any illegal or unauthorized purpose
• Violate any applicable laws or regulations
• Share copyrighted content without permission
• Attempt to gain unauthorized access to our systems
• Use automated tools to access the Service without permission
"""
            )
            
            // Section 6: Privacy
            termsSection(
                title: "6. Privacy and Data Protection",
                content: """
Our collection and use of personal information is governed by our Privacy Policy. Key points include:
• We collect only necessary information for service provision
• Data is encrypted and securely stored
• We do not sell personal information to third parties
• Users can request data deletion at any time

Data Processing Partners:
• Supabase: Database hosting and backend services
• RevenueCat: Subscription and payment processing
• Apple: App distribution and payment processing
"""
            )
            
            // Section 7: Disclaimers
            termsSection(
                title: "7. Disclaimers and Limitation of Liability",
                content: """
THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND.

Financial Disclaimer:
Piggy Bong is a budgeting tool, not financial advice. We do not:
• Provide investment, tax, or financial planning advice
• Guarantee financial outcomes or savings results
• Assume responsibility for financial decisions

TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES.
"""
            )
            
            // Section 8: Contact Information
            contactSection()
        }
    }
    
    // MARK: - Terms Section Component
    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text(title)
                .font(PiggyFont.title3)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            Text(content)
                .font(PiggyFont.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(PiggySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Contact Section with Tappable Links
    private func contactSection() -> some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            Text("8. Contact Information")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                Text("For questions about these Terms:")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                
                // Email Link
                Button(action: {
                    openMailtoSafely("hello@piggybong.com")
                }) {
                    Text("Email: hello@piggybong.com")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .underline()
                }
                
                // Website Link  
                Button(action: {
                    if let url = URL(string: "https://piggybong.app") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Website: https://piggybong.app")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .underline()
                }
                
                Text("Response Time: Within 48 hours for most inquiries")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, PiggySpacing.sm)
                
                Text("These Terms of Service are effective as of August 29, 2025.")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, PiggySpacing.sm)
                
                Text("By using Piggy Bong, you acknowledge that you have read and understood these Terms and agree to be bound by them.")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, PiggySpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PiggySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - GitHub Pages Notice
    private var githubPagesNotice: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.md) {
            HStack {
                Image(systemName: "safari")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.piggyPrimary)
                
                Text("View Online Version")
                    .font(PiggyFont.bodyEmphasized)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text("For the most up-to-date version, visit our online Terms of Service")
                .font(PiggyFont.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(nil)
        }
        .padding(PiggySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color.piggyPrimary.opacity(0.15), Color.piggyPrimary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                        .stroke(Color.piggyPrimary.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            if let url = URL(string: LegalDocumentService.shared.getTermsOfServiceURL()) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func openMailtoSafely(_ email: String) {
        guard let url = URL(string: "mailto:\(email)") else {
            copyEmailToClipboard(email)
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if !success {
                    DispatchQueue.main.async {
                        copyEmailToClipboard(email)
                    }
                }
            }
        } else {
            copyEmailToClipboard(email)
        }
    }

    private func copyEmailToClipboard(_ email: String) {
        UIPasteboard.general.string = email
        // Note: In a real app, you might want to show a toast or alert here
        print("📧 Email '\(email)' copied to clipboard")
    }
}

#Preview {
    TermsOfServiceView()
}