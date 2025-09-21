import SwiftUI

struct PrivacyPolicyView: View {
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
                        title: "Privacy Policy",
                        showAvatar: false,
                        applyHorizontalPadding: false
                    )
                    
                    // Header Section
                    headerSection
                    
                    // GitHub Pages Notice
                    githubPagesNotice
                    
                    // Privacy Content
                    privacyContent
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
            
            // Contact Information
            VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                Text("Contact Information")
                    .font(PiggyFont.body)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Text("Piggy Bong")
                    .font(PiggyFont.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Email: hello@piggybong.com")
                    .font(PiggyFont.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Website: https://piggybong.app")
                    .font(PiggyFont.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
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
    
    // MARK: - Privacy Content
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: PiggySpacing.lg) {
            // Section 1: Introduction
            privacySection(
                title: "1. Introduction",
                content: """
Welcome to Piggy Bong, the K-pop fan budget management app that helps you save for your favorite artists while tracking your fan-related expenses.

We are committed to protecting your privacy and being transparent about our data practices. This policy complies with applicable privacy laws including GDPR, CCPA, and other regional privacy regulations.
"""
            )
            
            // Section 2: Information We Collect
            privacySection(
                title: "2. Information We Collect",
                content: """
Information You Provide Directly:
• Account Information: Name, email, budget preferences, currency
• Budget & Financial Data: Monthly budget, expenses, savings goals
• K-pop Preferences: Selected artists, priority rankings, fan activity preferences
• App Usage Preferences: Notifications, display preferences

Information We Collect Automatically:
• Device Information: Device type, OS version, app version
• Usage Analytics: App feature usage, screen interactions (anonymized)
• Technical Data: IP address (anonymized after 30 days), session duration

Information from Third-Party Services:
• Supabase Backend Services: Database storage and authentication
• RevenueCat Subscription Data: Subscription status and purchase history
• AI Recommendation Services: Anonymized budget patterns (optional)
"""
            )
            
            // Section 3: How We Use Your Information
            privacySection(
                title: "3. How We Use Your Information",
                content: """
Core App Functionality:
• Provide budget tracking and management features
• Store and sync your financial goals and progress
• Display your selected K-pop artists and preferences
• Calculate budget allocations and recommendations
• Send notifications about goals and budget status

Subscription Management:
• Process subscription payments through RevenueCat
• Manage free trials and promotional codes
• Provide access to premium features

App Improvement:
• Analyze app usage to improve features
• Fix bugs and technical issues
• Develop new features based on user needs
"""
            )
            
            // Section 4: Information Sharing
            privacySection(
                title: "4. Information Sharing and Disclosure",
                content: """
We do not sell, rent, or trade your personal information. We only share data in limited circumstances:

Service Providers:
• Supabase: Database storage, user authentication, API services
• RevenueCat: Managing subscriptions, processing payments
• AI Services: Anonymized budget patterns for recommendations (optional)

Legal Requirements:
We may disclose information if required by law or to:
• Protect our legal rights or property
• Prevent fraud or security threats
• Comply with legal investigations

All service providers use secure infrastructure with encryption, access controls, and compliance certifications.
"""
            )
            
            // Section 5: Data Security
            privacySection(
                title: "5. Data Security",
                content: """
Technical Safeguards:
• Encryption: All data is encrypted in transit and at rest
• Access Controls: Strict authentication and authorization systems
• Network Security: Secure HTTPS connections for all data transmission
• Regular Audits: Ongoing security assessments and vulnerability testing

Organizational Safeguards:
• Limited Access: Only authorized personnel can access user data
• Training: Regular privacy and security training for all staff
• Incident Response: Established procedures for security incidents
• Data Minimization: We collect only necessary data for app functionality

In the unlikely event of a data breach, we will notify relevant authorities within 72 hours and users if personal data is affected.
"""
            )
            
            // Section 6: Data Retention
            privacySection(
                title: "6. Data Retention and Deletion",
                content: """
Retention Periods:
• Account Data: Retained while your account is active
• Budget Data: Up to 3 years after account deletion for legal compliance
• Usage Analytics: Anonymized after 12 months, deleted after 24 months
• Support Communications: Retained for 2 years for quality assurance

Account Deletion:
You can delete your account at any time through:
• App Settings > Account > Delete Account
• Email request to help.piggybong@gmail.com

Upon account deletion:
• Personal data is permanently deleted within 30 days
• Anonymized analytics may be retained for service improvement
• Financial records may be retained as required by law
• Backup data is purged within 90 days
"""
            )
            
            // Section 7: Your Privacy Rights
            privacySection(
                title: "7. Your Privacy Rights",
                content: """
Universal Rights (All Users):
• Access: Request a copy of your personal data
• Correction: Update or correct inaccurate information
• Deletion: Delete your account and associated data
• Portability: Export your data in a standard format

GDPR Rights (EU Residents):
• Consent Withdrawal: Withdraw consent for optional features
• Restriction: Limit processing of your personal data
• Objection: Object to processing for direct marketing
• Supervisory Authority: File complaints with local data protection authority

CCPA Rights (California Residents):
• Categories Disclosure: Information about data categories collected
• Sale Opt-Out: We do not sell personal information
• Non-Discrimination: Equal service regardless of privacy choices

To exercise your rights:
• In-App: Settings > Privacy > Data Rights
• Email: help.piggybong@gmail.com
• Response Time: Within 30 days for most requests
"""
            )
            
            // Section 8: Children's Privacy
            privacySection(
                title: "8. Children's Privacy (COPPA Compliance)",
                content: """
Piggy Bong is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.

If we discover we have collected data from a child under 13:
• We will immediately delete the information
• We will not use the information for any purpose
• We will not disclose the information to third parties

Parents: If you believe your child has provided personal information to us, please contact help.piggybong@gmail.com immediately.

Our app includes age verification to prevent underage registration.
"""
            )
            
            // Section 9: International Transfers
            privacySection(
                title: "9. International Data Transfers",
                content: """
Your data may be processed in:
• United States (Supabase, RevenueCat infrastructure)
• European Union (Supabase EU regions for EU users)
• Other locations as disclosed in third-party privacy policies

When we transfer data internationally, we ensure:
• Adequacy Decisions: Transfers to countries with adequate privacy protection
• Standard Contractual Clauses: EU-approved contract terms
• Specific Safeguards: Additional protections based on destination country
"""
            )
            
            // Section 10: Contact Information
            contactSection()
        }
    }
    
    // MARK: - Privacy Section Component
    private func privacySection(title: String, content: String) -> some View {
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
            Text("10. Contact Information and Complaints")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: PiggySpacing.sm) {
                Text("Privacy Contact:")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                
                // Email Link
                Button(action: {
                    openMailtoSafely("help.piggybong@gmail.com")
                }) {
                    Text("• Email: help.piggybong@gmail.com")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .underline()
                }
                
                Text("• Response Time: Within 5 business days")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("• Language: English (primary), Korean (limited support)")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Regulatory Complaints:")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, PiggySpacing.sm)
                
                Text("• EU Residents: Contact your local supervisory authority")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("• California Residents: California Attorney General's Office")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("• Other Jurisdictions: Contact your local privacy regulator")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("This Privacy Policy is effective as of August 29, 2025.")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, PiggySpacing.sm)
                
                Text("For questions about this policy or our privacy practices, please contact us at help.piggybong@gmail.com.")
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
            
            Text("For the most up-to-date version, visit our online Privacy Policy")
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
            if let url = URL(string: LegalDocumentService.shared.getPrivacyPolicyURL()) {
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
        print("📧 Email '\(email)' copied to clipboard")
    }
}

#Preview {
    PrivacyPolicyView()
}