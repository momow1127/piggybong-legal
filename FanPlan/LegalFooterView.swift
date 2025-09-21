import SwiftUI

/// Reusable legal footer component for easy integration across the app
struct LegalFooterView: View {
    var style: FooterStyle = .compact
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    enum FooterStyle {
        case compact    // Small inline links
        case detailed   // Larger buttons with icons
        case minimal    // Just text links
    }
    
    var body: some View {
        switch style {
        case .compact:
            compactFooter
        case .detailed:
            detailedFooter
        case .minimal:
            minimalFooter
        }
    }
    
    // MARK: - Compact Footer (for authentication screens)
    private var compactFooter: some View {
        VStack(spacing: 6) {
            // Fixed: Single sentence prevents awkward line breaking
            HStack(spacing: PiggySpacing.xs) {
                Text("By continuing, you agree to our")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))

                Button {
                    LegalDocumentService.shared.openTermsOfService {
                        showingTerms = true
                    }
                } label: {
                    Text("Terms of Service")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.piggyAccent.opacity(0.8))
                        .underline()
                }

                Text("and")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))

                Button {
                    LegalDocumentService.shared.openPrivacyPolicy {
                        showingPrivacy = true
                    }
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.piggyAccent.opacity(0.8))
                        .underline()
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
    
    // MARK: - Detailed Footer (for settings screens)
    private var detailedFooter: some View {
        VStack(spacing: PiggySpacing.md) {
            Button {
                LegalDocumentService.shared.openTermsOfService {
                    showingTerms = true
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.piggyTextSecondary)
                        .frame(width: 24, alignment: .center)
                    
                    Text("Terms of Service")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.piggyTextSecondary.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            Button {
                LegalDocumentService.shared.openPrivacyPolicy {
                    showingPrivacy = true
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shield")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.piggyTextSecondary)
                        .frame(width: 24, alignment: .center)
                    
                    Text("Privacy Policy")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.piggyTextSecondary.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
    
    // MARK: - Minimal Footer (for general use)
    private var minimalFooter: some View {
        HStack(spacing: 16) {
            Button {
                LegalDocumentService.shared.openTermsOfService {
                    showingTerms = true
                }
            } label: {
                Text("Terms")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .underline()
            }
            
            Button {
                LegalDocumentService.shared.openPrivacyPolicy {
                    showingPrivacy = true
                }
            } label: {
                Text("Privacy")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .underline()
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        PiggyGradients.background
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Compact Style")
                .font(.headline)
                .foregroundColor(.white)
            LegalFooterView(style: .compact)
            
            Divider()
                .background(.white.opacity(0.3))
            
            Text("Detailed Style")
                .font(.headline)
                .foregroundColor(.white)
            LegalFooterView(style: .detailed)
            
            Divider()
                .background(.white.opacity(0.3))
            
            Text("Minimal Style")
                .font(.headline)
                .foregroundColor(.white)
            LegalFooterView(style: .minimal)
        }
        .padding()
    }
}