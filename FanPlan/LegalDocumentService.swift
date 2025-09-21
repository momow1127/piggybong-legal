import SwiftUI
import SafariServices

/// Service for managing legal document access - Professional domain URLs with in-app fallback
class LegalDocumentService: ObservableObject {
    static let shared = LegalDocumentService()
    
    // MARK: - Legal Document URLs
    private let privacyPolicyURL = "https://piggybong.com/privacy.html"
    private let termsOfServiceURL = "https://piggybong.com/terms.html"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Opens Privacy Policy in Safari with in-app fallback
    func openPrivacyPolicy(fallbackHandler: @escaping () -> Void) {
        openLegalDocument(url: privacyPolicyURL, fallbackHandler: fallbackHandler)
    }
    
    /// Opens Terms of Service in Safari with in-app fallback  
    func openTermsOfService(fallbackHandler: @escaping () -> Void) {
        openLegalDocument(url: termsOfServiceURL, fallbackHandler: fallbackHandler)
    }
    
    /// Gets Privacy Policy URL for direct use
    func getPrivacyPolicyURL() -> String {
        return privacyPolicyURL
    }
    
    /// Gets Terms of Service URL for direct use
    func getTermsOfServiceURL() -> String {
        return termsOfServiceURL
    }
    
    // MARK: - Private Methods
    
    /// Opens a legal document URL in Safari with fallback handling
    private func openLegalDocument(url: String, fallbackHandler: @escaping () -> Void) {
        print("🔍 LegalDocumentService: Attempting to open URL: \(url)")
        
        guard let url = URL(string: url) else {
            print("❌ LegalDocumentService: Invalid URL - \(url)")
            fallbackHandler()
            return
        }
        
        print("✅ LegalDocumentService: Valid URL created: \(url)")
        
        // Try to open in Safari first
        if UIApplication.shared.canOpenURL(url) {
            print("📱 LegalDocumentService: URL can be opened, attempting to open...")
            UIApplication.shared.open(url) { success in
                if !success {
                    print("⚠️ LegalDocumentService: Failed to open URL in Safari, using fallback")
                    DispatchQueue.main.async {
                        fallbackHandler()
                    }
                } else {
                    print("✅ LegalDocumentService: Successfully opened legal document in Safari")
                }
            }
        } else {
            print("⚠️ LegalDocumentService: Cannot open URL, using fallback")
            fallbackHandler()
        }
    }
}

// MARK: - SwiftUI Integration

/// View modifier for easy legal document integration
struct LegalDocumentLink: ViewModifier {
    let documentType: LegalDocumentType
    @State private var showFallbackSheet = false
    
    enum LegalDocumentType {
        case privacy, terms
    }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                let service = LegalDocumentService.shared
                
                switch documentType {
                case .privacy:
                    service.openPrivacyPolicy {
                        showFallbackSheet = true
                    }
                case .terms:
                    service.openTermsOfService {
                        showFallbackSheet = true
                    }
                }
            }
            .sheet(isPresented: $showFallbackSheet) {
                switch documentType {
                case .privacy:
                    PrivacyPolicyView()
                case .terms:
                    TermsOfServiceView()
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds legal document link functionality with fallback
    func legalDocumentLink(_ type: LegalDocumentLink.LegalDocumentType) -> some View {
        self.modifier(LegalDocumentLink(documentType: type))
    }
}

// MARK: - Safari View Controller (Optional Enhanced Integration)

@available(iOS 14.0, *)
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor(.piggyPrimary)
        safari.preferredBarTintColor = UIColor(.piggyBackground)
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}