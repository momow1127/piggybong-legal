import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var tabSelection = TabSelection()

    var body: some View {
        TabView(selection: $tabSelection.selectedTab) {
            // Home Tab - Fan Dashboard
            FanHomeDashboardView()
                .environmentObject(tabSelection)
                .tabItem {
                    Image(tabSelection.selectedTab == 0 ? "house_filled" : "house_line")
                    Text("Home")
                }
                .tag(0)
            
            // Events Tab - Activities and Planning
            EventsView()
                .environmentObject(tabSelection)
                .tabItem {
                    Image(tabSelection.selectedTab == 1 ? "events_filled" : "events_line")
                    Text("Events")
                }
                .tag(1)
            
            // Profile Tab - Settings and Account
            ProfileSettingsView()
            .environmentObject(tabSelection)
            .tabItem {
                Image(tabSelection.selectedTab == 2 ? "profile_filled" : "profile_line")
                Text("Profile")
            }
            .tag(2)

            // Debug Tab - Only available in DEBUG builds
            #if DEBUG
            TestCrashView()
                .environmentObject(tabSelection)
                .tabItem {
                    Image(systemName: tabSelection.selectedTab == 3 ? "ladybug.fill" : "ladybug")
                    Text("Debug")
                }
                .tag(3)
            #endif
        }
        .accentColor(.piggyTextPrimary) // Selected icon + label = DS white token
        .onAppear {
            configureGlassmorphismTabBar()
        }
        .onChange(of: tabSelection.selectedTab) { _, newTab in
            // Track tab navigation performance
            let tabNames = ["Home", "Events", "Profile", "Debug"]
            if newTab < tabNames.count {
                PerformanceService.shared.quickTrace(
                    name: "tab_navigation",
                    attributes: [
                        "tab_name": tabNames[newTab],
                        "tab_index": String(newTab)
                    ]
                )
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Reset to Home tab when user logs in
                tabSelection.selectedTab = 0
            }
        }
        .onAppear {
            // Track main app load
            PerformanceService.shared.trackScreenLoad("MainTabView", loadTime: 0.5)
        }
    }

    // MARK: - Glassmorphism Tab Bar Configuration
    private func configureGlassmorphismTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // Glassmorphism background - matches elevated card style
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundEffect = blurEffect

        // Semi-transparent dark background matching app gradient
        appearance.backgroundColor = UIColor(Color.piggyBackground.opacity(0.95))

        // Add subtle border at the top for definition
        appearance.shadowColor = UIColor(Color.piggyBorder.opacity(0.2))
        appearance.shadowImage = UIImage()

        // Selected state - white text and icon with subtle glow
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.piggyTextPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.piggyTextPrimary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Unselected state - secondary with good contrast
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.piggyTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.piggyTextSecondary),
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]

        // Apply the glassmorphism appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Additional blur configuration for iOS 15+
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().backgroundImage = UIImage()
            UITabBar.appearance().shadowImage = UIImage()
        }
    }
}

#Preview {
    MainTabView()
}