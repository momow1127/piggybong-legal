import SwiftUI

// MARK: - Name Step Content
struct OnboardingNameStepContent: View {
    @Binding var name: String
    @Binding var isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.piggyPrimary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                
                Text("What should we call you?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
            }
            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter your name", text: $name)
                    .textFieldStyle(PiggyTextFieldStyle())
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
                
                Text("This will personalize your experience")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Budget Step Content
struct OnboardingBudgetStepContent: View {
    @Binding var monthlyBudget: Double
    @Binding var isAnimating: Bool
    
    private let budgetOptions: [Double] = [100, 200, 300, 500, 750, 1000]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.piggySecondary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                
                Text("Monthly K-Pop Budget")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
                
                Text("How much do you want to allocate monthly for K-Pop expenses?")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
            }
            
            // Budget options
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(budgetOptions, id: \.self) { budget in
                    BudgetOptionCard(
                        amount: budget,
                        isSelected: monthlyBudget == budget,
                        onTap: { monthlyBudget = budget }
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.8 + Double(budgetOptions.firstIndex(of: budget) ?? 0) * 0.1), value: isAnimating)
                }
            }
            
            // Custom amount
            VStack(spacing: 8) {
                Text("Or enter a custom amount:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("$0", value: $monthlyBudget, format: .currency(code: "USD"))
                    .textFieldStyle(PiggyTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.8).delay(1.2), value: isAnimating)
        }
        .padding(.top, 20)
    }
}

struct BudgetOptionCard: View {
    let amount: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text("$\(Int(amount))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .piggyPrimary)
                
                Text("per month")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .piggyPrimary.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                isSelected 
                ? LinearGradient(colors: [.piggyPrimary, .piggySecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.piggyPrimary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Artists Step Content
struct OnboardingArtistsStepContent: View {
    @Binding var isAnimating: Bool
    @StateObject private var onboardingService = OnboardingService.shared
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.piggyAccent)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                
                Text("Choose Your Artists")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
                
                Text("Select your favorite K-Pop artists to get personalized recommendations")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
            }
            
            // Artists grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(onboardingService.availableArtists, id: \.id) { artist in
                    VStack {
                        Text(artist.name)
                            .font(.headline)
                        Button("Select") {
                            onboardingService.toggleArtistSelection(artist.id)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Goals Step Content
struct OnboardingGoalsStepContent: View {
    @Binding var isAnimating: Bool
    @StateObject private var onboardingService = OnboardingService.shared
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(.piggyPrimary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                
                Text("What are your goals?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
            }
            
            // Goals list
            VStack(spacing: 12) {
                ForEach(onboardingService.availableGoals, id: \.id) { goal in
                    Button(action: { 
                        // Toggle selection
                        onboardingService.toggleGoalSelection(goal.id)
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(onboardingService.selectedGoals.contains(goal.id) ? Color.piggyPrimary : Color.white.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: onboardingService.selectedGoals.contains(goal.id) ? "checkmark" : "")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(goal.description)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(onboardingService.selectedGoals.contains(goal.id) ? Color.piggyPrimary.opacity(0.2) : Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(onboardingService.selectedGoals.contains(goal.id) ? Color.piggyPrimary : Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
                }
            }
        }
        .padding(.top, 20)
    }
}

// MARK: - Notifications Step Content
struct OnboardingNotificationsStepContent: View {
    @Binding var isAnimating: Bool
    @StateObject private var onboardingService = OnboardingService.shared
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.piggySecondary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
                
                Text("Stay Updated")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: isAnimating)
                
                Text("Get notified about concerts, merchandise, and special events")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
            }
            
            // Notification options
            VStack(spacing: 16) {
                NotificationToggleCard(
                    title: "Concert Alerts",
                    description: "Get notified when your artists announce tours",
                    icon: "music.mic",
                    isEnabled: $onboardingService.enableConcertNotifications
                )
                
                NotificationToggleCard(
                    title: "Merchandise Drops",
                    description: "Never miss limited edition items",
                    icon: "bag.fill",
                    isEnabled: $onboardingService.enableMerchNotifications
                )
                
                NotificationToggleCard(
                    title: "Budget Reminders",
                    description: "Stay on track with your spending goals",
                    icon: "chart.pie.fill",
                    isEnabled: $onboardingService.enableBudgetNotifications
                )
            }
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.8).delay(0.8), value: isAnimating)
        }
        .padding(.top, 20)
    }
}

// MARK: - Completion Step Content
struct OnboardingCompletionStepContent: View {
    let name: String
    @Binding var isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            // Success animation
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.piggyPrimary, .piggySecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: isAnimating)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(0.8), value: isAnimating)
                }
                
                Text("Welcome, \(name)!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: isAnimating)
                
                Text("You're all set to start your K-Pop journey with smart budgeting!")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(1.2), value: isAnimating)
            }
            
            // Feature highlights
            VStack(spacing: 16) {
                FeatureHighlightRow(icon: "chart.pie.fill", text: "Smart budget allocation")
                FeatureHighlightRow(icon: "bell.fill", text: "Personalized notifications")
                FeatureHighlightRow(icon: "heart.fill", text: "Track your fandom journey")
            }
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.8).delay(1.4), value: isAnimating)
        }
        .padding(.top, 60)
    }
}

struct FeatureHighlightRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.piggyPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Supporting Views
struct PiggyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.piggyPrimary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - NotificationToggleCard
struct NotificationToggleCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isEnabled ? Color.piggyPrimary : Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.6))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .piggyPrimary))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEnabled ? Color.piggyPrimary : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}