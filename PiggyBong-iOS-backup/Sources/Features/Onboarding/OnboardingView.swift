import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var currentStep = 0
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var monthlyBudget = ""
    
    private let steps = [
        OnboardingStep.welcome,
        OnboardingStep.account,
        OnboardingStep.budget
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: PiggySpacing.sm) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index <= currentStep ? Color.piggyPrimary : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .animation(PiggyAnimation.standard, value: currentStep)
                    }
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.top, PiggySpacing.md)
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        stepView(for: steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(PiggyAnimation.standard, value: currentStep)
                
                // Navigation buttons
                HStack(spacing: PiggySpacing.md) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .piggyButton(.outline)
                    }
                    
                    Button(currentStep == steps.count - 1 ? "Get Started" : "Next") {
                        if currentStep == steps.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .piggyButton(.primary)
                    .disabled(!canProceed)
                }
                .padding(.horizontal, PiggySpacing.lg)
                .padding(.bottom, PiggySpacing.xl)
            }
            .background(Color.piggyBackground.ignoresSafeArea())
        }
    }
    
    @ViewBuilder
    private func stepView(for step: OnboardingStep) -> some View {
        ScrollView {
            VStack(spacing: PiggySpacing.xl) {
                Spacer()
                
                switch step {
                case .welcome:
                    WelcomeStepView()
                case .account:
                    AccountStepView(email: $email, password: $password, name: $name)
                case .budget:
                    BudgetStepView(monthlyBudget: $monthlyBudget)
                }
                
                Spacer()
            }
            .padding(.horizontal, PiggySpacing.lg)
        }
    }
    
    private var canProceed: Bool {
        switch steps[currentStep] {
        case .welcome:
            return true
        case .account:
            return !email.isEmpty && !password.isEmpty && !name.isEmpty
        case .budget:
            return !monthlyBudget.isEmpty && Double(monthlyBudget) != nil
        }
    }
    
    private func completeOnboarding() {
        Task {
            await authManager.signUp(email: email, password: password, name: name)
        }
    }
}

enum OnboardingStep {
    case welcome
    case account
    case budget
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: PiggySpacing.lg) {
            // Piggy illustration placeholder
            RoundedRectangle(cornerRadius: PiggySpacing.cardCornerRadius)
                .fill(Color.piggyPrimary.opacity(0.1))
                .frame(width: 200, height: 200)
                .overlay(
                    Image(systemName: "banknote")
                        .font(.system(size: 80))
                        .foregroundColor(.piggyPrimary)
                )
            
            VStack(spacing: PiggySpacing.md) {
                Text("Welcome to PiggyBong!")
                    .font(PiggyFont.largeTitle)
                    .foregroundColor(.piggyTextPrimary)
                
                Text("Track your K-pop spending and stay within budget while supporting your favorite artists.")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct AccountStepView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var name: String
    
    var body: some View {
        VStack(spacing: PiggySpacing.lg) {
            VStack(spacing: PiggySpacing.md) {
                Text("Create Your Account")
                    .font(PiggyFont.title1)
                    .foregroundColor(.piggyTextPrimary)
                
                Text("Let's set up your PiggyBong account")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: PiggySpacing.md) {
                TextField("Your Name", text: $name)
                    .textFieldStyle(PiggyTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(PiggyTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(PiggyTextFieldStyle())
            }
        }
    }
}

struct BudgetStepView: View {
    @Binding var monthlyBudget: String
    
    var body: some View {
        VStack(spacing: PiggySpacing.lg) {
            VStack(spacing: PiggySpacing.md) {
                Text("Set Your Monthly Budget")
                    .font(PiggyFont.title1)
                    .foregroundColor(.piggyTextPrimary)
                
                Text("How much do you want to spend on K-pop each month?")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: PiggySpacing.md) {
                HStack {
                    Text("$")
                        .font(PiggyFont.title2)
                        .foregroundColor(.piggyTextPrimary)
                    
                    TextField("0", text: $monthlyBudget)
                        .font(PiggyFont.budgetAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                }
                .padding(PiggySpacing.md)
                .background(Color.piggySurface)
                .cornerRadius(PiggyBorderRadius.md)
                
                Text("Don't worry, you can change this anytime!")
                    .font(PiggyFont.footnote)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
    }
}

struct PiggyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(PiggySpacing.md)
            .background(Color.piggySurface)
            .cornerRadius(PiggyBorderRadius.md)
            .font(PiggyFont.body)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
}