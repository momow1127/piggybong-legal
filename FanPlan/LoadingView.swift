import SwiftUI

struct LoadingView: View {
    let isSimpleMode: Bool

    @State private var isAnimating = false
    @State private var currentMessageIndex = 0
    @State private var showSparkles = false
    @State private var lightstickGlow = false
    @State private var networkCheckCompleted = false
    @ObservedObject private var networkManager = NetworkManager.shared
    
    private let kpopLoadingMessages = [
        "Tuning your bias radar...",
        "Loading your K-pop journey...",
        "Syncing with your bias...",
        "Preparing your lightstick...",
        "Gathering fan chants...",
        "Calculating bias wrecker potential...",
        "Loading fan mode...",
        "Preparing for comeback season..."
    ]
    
    var body: some View {
        ZStack {
            // Ensure proper background color is always shown
            Color(red: 0x0D/255, green: 0x00/255, blue: 0x11/255)
                .ignoresSafeArea(.all)
            
            // Add gradient overlay
            PiggyGradients.background
                .ignoresSafeArea(.all)
            
            // Background sparkles (only in full mode) - OPTIMIZED: Reduced count for better performance
            if !isSimpleMode {
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: ["sparkles", "star.fill", "heart.fill"].randomElement() ?? "sparkles")
                        .font(.system(size: CGFloat.random(in: 8...16)))
                        .foregroundColor(Color.piggySecondary.opacity(0.3))
                        .position(
                            x: CGFloat.random(in: 50...350),
                            y: CGFloat.random(in: 100...600)
                        )
                        .scaleEffect(showSparkles ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 1.8...3.2))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: showSparkles
                        )
                }
            }
            
            VStack(spacing: PiggySpacing.lg) {
                // Animated pig lightstick with glow
                ZStack {
                    // Glow effect
                    Image("piggy-lightstick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.piggySecondary)
                        .blur(radius: 20)
                        .opacity(lightstickGlow ? 0.8 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: lightstickGlow
                        )
                    
                    // Main lightstick
                    Image("piggy-lightstick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? 15 : -15))
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // Loading message (simple or dynamic)
                VStack(spacing: PiggySpacing.sm) {
                    if isSimpleMode {
                        Text("Until the next comeback...")
                            .font(PiggyFont.title2)
                            .foregroundColor(.piggyTextPrimary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(kpopLoadingMessages[currentMessageIndex])
                            .font(PiggyFont.bodyEmphasized)
                            .foregroundColor(.piggyTextSecondary)
                            .multilineTextAlignment(.center)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                            .id(currentMessageIndex)
                        
                        // Network status indicator (only in full mode)
                        if networkCheckCompleted {
                            HStack(spacing: PiggySpacing.xs) {
                                Image(systemName: networkManager.isConnected ? "wifi" : "wifi.slash")
                                    .foregroundColor(networkManager.isConnected ? .green : .orange)
                                    .font(.caption)
                                
                                Text(networkManager.isConnected ? "Connected" : "Offline Mode")
                                    .font(PiggyFont.caption2)
                                    .foregroundColor(.piggyTextTertiary)
                            }
                        }
                    }
                }
                
                // Loading indicators (only in full mode)
                if !isSimpleMode {
                    // Enhanced loading dots with K-pop colors
                    HStack(spacing: PiggySpacing.sm) {
                        ForEach(0..<3) { index in
                            Circle()
                                .frame(width: 12, height: 12)
                                .foregroundColor([.piggyPrimary, .piggySecondary, .pink].randomElement() ?? .piggyPrimary)
                                .scaleEffect(isAnimating ? 1.2 : 0.6)
                                .animation(
                                    Animation.easeInOut(duration: 0.8)
                                        .repeatForever()
                                        .delay(Double(index) * 0.25),
                                    value: isAnimating
                                )
                        }
                    }
                    
                    // Fun bias loading indicator
                    HStack(spacing: PiggySpacing.xs) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .scaleEffect(isAnimating ? 1.3 : 0.7)
                            .animation(
                                Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Text("Finding your perfect bias...")
                            .font(PiggyFont.caption1)
                            .foregroundColor(.piggyTextTertiary)
                            .opacity(isAnimating ? 1.0 : 0.7)
                            .animation(
                                Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
            showSparkles = true
            lightstickGlow = true
            
            // Check network connectivity (only in full mode)
            if !isSimpleMode {
                Task {
                    let isConnected = await networkManager.checkConnectivity()
                    await MainActor.run {
                        networkCheckCompleted = true
                        if !isConnected {
                            print("📡 Network connectivity check failed during loading")
                        }
                    }
                }
                
                // Cycle through messages (only in full mode)
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentMessageIndex = (currentMessageIndex + 1) % kpopLoadingMessages.count
                    }
                }
            }
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    @State private var isWiggling = false
    @State private var showSadEmoji = false
    @ObservedObject private var networkManager = NetworkManager.shared
    
    private let kpopErrorMessages = [
        "Your bias is temporarily unavailable...",
        "The lightstick signal got lost...",
        "Comeback season overload...",
        "Fan Twitter broke the servers...",
        "Too many people streaming at once..."
    ]
    
    var body: some View {
        ZStack {
            // Ensure proper background color is always shown
            Color(red: 0x0D/255, green: 0x00/255, blue: 0x11/255)
                .ignoresSafeArea(.all)
            
            // Add gradient overlay
            PiggyGradients.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: PiggySpacing.lg) {
                // Sad lightstick animation
                ZStack {
                    Image("piggy-lightstick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .grayscale(0.8)
                        .rotationEffect(.degrees(isWiggling ? 5 : -5))
                        .animation(
                            Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: isWiggling
                        )
                    
                    // Sad face overlay
                    if showSadEmoji {
                        Text("😭")
                            .font(.title)
                            .offset(x: 30, y: -20)
                            .scaleEffect(showSadEmoji ? 1.2 : 0.5)
                            .animation(
                                Animation.spring(response: 0.6, dampingFraction: 0.8),
                                value: showSadEmoji
                            )
                    }
                }
                
                Text("Oh no, bestie! 😱")
                    .font(PiggyFont.title2)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(kpopErrorMessages.randomElement() ?? message)
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PiggySpacing.lg)
                
                Text(message)
                    .font(PiggyFont.caption1)
                    .foregroundColor(.piggyTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PiggySpacing.lg)
                
                VStack(spacing: PiggySpacing.md) {
                    // Show different retry button based on network status
                    if networkManager.isConnected {
                        Button(action: onRetry) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again (Fighting!) 💪")
                            }
                        }
                        .buttonStyle(.primaryButton())
                    } else {
                        VStack(spacing: PiggySpacing.sm) {
                            Button(action: onRetry) {
                                HStack {
                                    Image(systemName: "wifi.slash")
                                    Text("Retry Connection")
                                }
                            }
                            .buttonStyle(.primaryButton())
                            
                            Button(action: {
                                // Switch to offline mode
                                onRetry()
                            }) {
                                HStack {
                                    Image(systemName: "airplane")
                                    Text("Continue Offline")
                                }
                            }
                            .buttonStyle(.secondaryButton())
                        }
                    }
                    
                    Text(networkManager.isConnected ? 
                         "Don't worry, your bias still loves you! 💜" : 
                         "Some features limited in offline mode 📡")
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggySecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            isWiggling = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showSadEmoji = true
            }
        }
    }
}

#Preview {
    LoadingView(isSimpleMode: false)
}

#Preview {
    ErrorView(message: "Network connection failed. Please check your internet connection.") {
        // Retry action
    }
}
