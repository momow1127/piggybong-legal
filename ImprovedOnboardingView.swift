import SwiftUI

struct ImprovedOnboardingView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var currentStep = 0
    @State private var showingNotificationPermission = false
    @State private var onboardingComplete = false
    
    private let totalSteps = 4
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.black, .purple.opacity(0.8), .pink.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    HStack {
                        ForEach(0..<totalSteps, id: \.self) { step in
                            Circle()
                                .fill(step <= currentStep ? .white : .white.opacity(0.3))
                                .frame(width: 12, height: 12)
                            
                            if step < totalSteps - 1 {
                                Rectangle()
                                    .fill(step < currentStep ? .white : .white.opacity(0.3))
                                    .frame(height: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    // Content based on current step
                    TabView(selection: $currentStep) {
                        // Step 1: Welcome
                        WelcomeStepView()
                            .tag(0)
                        
                        // Step 2: Groups Selection
                        GroupsSelectionStepView()
                            .tag(1)
                        
                        // Step 3: Priorities
                        PrioritiesStepView()
                            .tag(2)
                        
                        // Step 4: Notification Permission (No back button)
                        NotificationPermissionStepView(
                            onPermissionGranted: {
                                handleNotificationPermissionGranted()
                            },
                            onPermissionDenied: {
                                handleNotificationPermissionDenied()
                            }
                        )
                        .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $onboardingComplete) {
            // Navigate to main app after onboarding
            MainAppView()
        }
    }
    
    private func handleNotificationPermissionGranted() {
        print("Notification permission granted - proceeding to main app")
        completeOnboarding()
    }
    
    private func handleNotificationPermissionDenied() {
        print("Notification permission denied - still proceeding to main app")
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        onboardingComplete = true
    }
}

// MARK: - Step Views

struct WelcomeStepView: View {
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                
                VStack(spacing: 16) {
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Piggy Bong")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your ultimate K-pop companion for smart budget planning and priority management")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = 1
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

struct GroupsSelectionStepView: View {
    @State private var selectedGroups: Set<String> = []
    @State private var currentStep = 1
    
    private let kpopGroups = [
        "BTS", "BLACKPINK", "TWICE", "Stray Kids", "ITZY", "aespa",
        "NewJeans", "LE SSERAFIM", "IVE", "NMIXX", "Red Velvet", "MAMAMOO"
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Choose Your Groups")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select your favorite K-pop groups to get personalized content")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 40)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(kpopGroups, id: \.self) { group in
                    GroupSelectionCard(
                        groupName: group,
                        isSelected: selectedGroups.contains(group),
                        onTap: {
                            if selectedGroups.contains(group) {
                                selectedGroups.remove(group)
                            } else {
                                selectedGroups.insert(group)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = 2
                }
            }) {
                Text("Continue (\(selectedGroups.count) selected)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        selectedGroups.isEmpty ? 
                        Color.gray.opacity(0.5) :
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(selectedGroups.isEmpty)
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

struct GroupSelectionCard: View {
    let groupName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(groupName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.pink)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                          LinearGradient(colors: [.pink.opacity(0.3), .purple.opacity(0.3)], 
                                       startPoint: .topLeading, endPoint: .bottomTrailing) :
                          Color.white.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .pink : .clear, lineWidth: 2)
                    )
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct PrioritiesStepView: View {
    @State private var currentStep = 2
    @State private var monthlyBudget = 100.0
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Set Your Budget")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("How much do you typically spend on K-pop each month?")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 40)
            
            VStack(spacing: 24) {
                Text("$\(Int(monthlyBudget))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Slider(value: $monthlyBudget, in: 10...500, step: 10)
                    .accentColor(.pink)
                    .padding(.horizontal, 32)
                
                HStack {
                    Text("$10")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("$500+")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentStep = 3
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

struct NotificationPermissionStepView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isRequestingPermission = false
    
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header Section
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .padding(.top, 60)
                
                Text("Stay Updated")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Get notified about concerts, album releases, and exclusive K-pop updates")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Benefits Section
            VStack(spacing: 16) {
                NotificationBenefitRow(
                    icon: "music.note",
                    title: "Concert Alerts",
                    description: "Never miss your favorite group's tour announcements"
                )
                
                NotificationBenefitRow(
                    icon: "gift.fill",
                    title: "Exclusive Updates",
                    description: "Get early access to limited edition merchandise"
                )
                
                NotificationBenefitRow(
                    icon: "calendar.badge.plus",
                    title: "Event Reminders",
                    description: "Stay on top of comebacks and special events"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Action Buttons - NO BACK BUTTON
            VStack(spacing: 16) {
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Enable Notifications")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isRequestingPermission)
                
                Button(action: {
                    // Skip notifications and complete onboarding
                    onPermissionDenied()
                }) {
                    Text("Maybe Later")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkCurrentPermissionStatus()
        }
    }
    
    private func checkCurrentPermissionStatus() {
        notificationManager.checkAuthorizationStatus()
        
        // If permission is already granted, automatically proceed
        if notificationManager.isPermissionGranted {
            onPermissionGranted()
        }
    }
    
    private func requestNotificationPermission() {
        guard !isRequestingPermission else { return }
        
        isRequestingPermission = true
        
        notificationManager.requestPermission { granted, error in
            DispatchQueue.main.async {
                self.isRequestingPermission = false
                
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
                
                if granted {
                    print("Notification permission granted")
                    self.onPermissionGranted()
                } else {
                    print("Notification permission denied")
                    self.onPermissionDenied()
                }
            }
        }
    }
}

// MARK: - Main App View Placeholder

struct MainAppView: View {
    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            Text("Priorities")
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Priorities")
                }
            
            Text("Events")
                .tabItem {
                    Image(systemName: "calendar.badge.plus")
                    Text("Events")
                }
            
            Text("Profile")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.pink)
    }
}

// MARK: - Preview

struct ImprovedOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ImprovedOnboardingView()
    }
}