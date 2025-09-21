import SwiftUI
import UIKit

// MARK: - Navigation Bar Style Manager
class NavigationBarStyleManager: ObservableObject {
    static let shared = NavigationBarStyleManager()
    
    private init() {}
    
    // Configure global navigation bar appearance
    func configureGlobalNavigationBarStyle() {
        // Standard appearance (non-scrolling)
        let standardAppearance = UINavigationBarAppearance()
        configureAppearance(standardAppearance)
        
        // Scroll edge appearance (when content scrolls behind nav bar)
        let scrollEdgeAppearance = UINavigationBarAppearance()
        configureAppearance(scrollEdgeAppearance)
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        UINavigationBar.appearance().compactAppearance = standardAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = scrollEdgeAppearance
        
        // Force status bar style
        UINavigationBar.appearance().barStyle = .black
        
        // Configure transparent tab bar
        configureTabBarAppearance()
    }
    
    private func configureAppearance(_ appearance: UINavigationBarAppearance) {
        // Configure completely transparent background
        appearance.configureWithTransparentBackground()
        appearance.backgroundImage = nil // No background image
        appearance.backgroundColor = UIColor.clear // Completely transparent
        appearance.shadowImage = UIImage() // Remove separator line
        appearance.shadowColor = .clear
        
        // Configure title attributes (100% white)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Configure large title attributes (100% white)
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Configure button appearance (100% white)
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .medium)
        ]
        buttonAppearance.highlighted.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        buttonAppearance.disabled.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.3)
        ]
        
        appearance.buttonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        
        // Ensure no translucency or background effects
        appearance.backgroundColor = UIColor.clear
        appearance.backgroundEffect = nil
    }
    
    private func configureTabBarAppearance() {
        // Standard tab bar appearance (non-scrolling)
        let standardTabAppearance = UITabBarAppearance()
        standardTabAppearance.configureWithTransparentBackground()
        standardTabAppearance.backgroundColor = UIColor.clear
        standardTabAppearance.shadowColor = .clear
        standardTabAppearance.shadowImage = UIImage()
        
        // Configure tab bar item colors
        standardTabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0x5D/255.0, green: 0x2C/255.0, blue: 0xEE/255.0, alpha: 1.0) // piggyPrimary
        standardTabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0x5D/255.0, green: 0x2C/255.0, blue: 0xEE/255.0, alpha: 1.0)
        ]
        
        standardTabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        standardTabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        
        // Apply to all tab bars
        UITabBar.appearance().standardAppearance = standardTabAppearance
        UITabBar.appearance().scrollEdgeAppearance = standardTabAppearance
        
        // Ensure translucency
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = UIColor.clear
    }
}

// MARK: - SwiftUI View Modifier for Navigation Bar Styling
struct PiggyNavigationBarStyle: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode
    
    init(title: String, displayMode: NavigationBarItem.TitleDisplayMode = .automatic) {
        self.title = title
        self.displayMode = displayMode
    }
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // The global navigation bar configuration handles status bar style
            }
    }
}

// MARK: - SwiftUI Extensions
extension View {
    func piggyNavigationBar(title: String, displayMode: NavigationBarItem.TitleDisplayMode = .automatic) -> some View {
        modifier(PiggyNavigationBarStyle(title: title, displayMode: displayMode))
    }
    
    // For modal presentations
    func piggyModalNavigationBar(title: String, onDismiss: @escaping () -> Void) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                }
            }
    }
    
    // For pushed screens with custom back button
    func piggyPushedNavigationBar(title: String, onBack: (() -> Void)? = nil) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarBackButtonHidden(onBack != nil)
            .toolbar {
                if let onBack = onBack {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            onBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                Text("Back")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
    }
}

// MARK: - Status Bar Style Controller
class StatusBarStyleController: ObservableObject {
    static let shared = StatusBarStyleController()
    
    @Published var statusBarStyle: UIStatusBarStyle = .lightContent
    
    private init() {}
    
    func setLightContent() {
        statusBarStyle = .lightContent
    }
    
    func setDarkContent() {
        statusBarStyle = .darkContent
    }
}

// MARK: - Host Controller for Status Bar
class HostingController<Content: View>: UIHostingController<Content> {
    private let statusBarController = StatusBarStyleController.shared
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarController.statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusBarController.setLightContent()
    }
}
