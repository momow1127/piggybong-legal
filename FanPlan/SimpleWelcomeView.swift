import SwiftUI

struct SimpleWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        ZStack {
            // Simple gradient background
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App Icon or Logo
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                // Title
                Text("Piggy Bong")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Subtitle
                Text("Your K-pop Budget Companion")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Spacer()

                // Get Started Button
                Button(action: onNext) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 50)
            }
        }
    }
}

#Preview {
    SimpleWelcomeView(onNext: {})
}