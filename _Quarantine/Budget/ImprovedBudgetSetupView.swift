import SwiftUI

struct ImprovedBudgetSetupView: View {
    @State private var budgetAmount: Double = 300
    @State private var customAmount: String = ""
    @State private var isEditingCustom: Bool = false
    
    // Quick select preset amounts
    private let presetAmounts: [Double] = [50, 100, 200, 300, 500, 1000]
    
    var body: some View {
        ZStack {
            // Background with white opacity overlay
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.8),
                    Color.pink.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // White opacity overlay for better readability
            Color.white.opacity(0.1)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 12) {
                        Text("Set Your Monthly Budget")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("How much do you want to spend on K-pop each month?")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Main Budget Display
                    VStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("$\(Int(budgetAmount))")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.white) // Fixed: Made $300 white
                            
                            Text("per month") // Fixed: Positioned next to amount
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 8)
                        }
                        
                        // Budget slider with better styling
                        VStack(spacing: 16) {
                            Slider(value: $budgetAmount, in: 50...2000, step: 50)
                                .accentColor(.white)
                                .padding(.horizontal, 20)
                            
                            HStack {
                                Text("$50") // Fixed: Larger font and bold
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                                Text("$1000+") // Fixed: Larger font and bold
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.15))
                            .backdrop(BlurEffect(style: .systemUltraThinMaterialLight))
                    )
                    .padding(.horizontal, 20)
                    
                    // Quick Select Buttons - Improved positioning for optimal tap area
                    VStack(spacing: 16) {
                        Text("Quick Select")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        // Fixed: Better positioning with optimal tap areas (44pt minimum)
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(presetAmounts, id: \.self) { amount in
                                Button(action: {
                                    budgetAmount = amount
                                    isEditingCustom = false
                                }) {
                                    Text("$\(Int(amount))")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(budgetAmount == amount ? .purple : .white)
                                        .frame(minWidth: 80, minHeight: 48) // Optimal tap area
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(budgetAmount == amount ? Color.white : Color.white.opacity(0.2))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Custom amount input
                        VStack(spacing: 12) {
                            Button(action: {
                                isEditingCustom.toggle()
                            }) {
                                HStack {
                                    Text("Custom Amount")
                                        .font(.system(size: 18, weight: .semibold))
                                    Spacer()
                                    Image(systemName: isEditingCustom ? "chevron.up" : "chevron.down")
                                }
                                .foregroundColor(.white)
                                .frame(minHeight: 48)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if isEditingCustom {
                                HStack {
                                    Text("$")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    TextField("Enter amount", text: $customAmount)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .onChange(of: customAmount) { value in
                                            if let amount = Double(value) {
                                                budgetAmount = max(50, min(2000, amount))
                                            }
                                        }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.2))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Continue Button - Clean positioning
                    Button(action: {
                        // Handle budget confirmation
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Helper for backdrop blur effect
struct BlurEffect: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// Extension for backdrop modifier
extension View {
    func backdrop<T: View>(@ViewBuilder content: () -> T) -> some View {
        self.background(content())
    }
}

#Preview {
    ImprovedBudgetSetupView()
}