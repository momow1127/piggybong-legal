import SwiftUI

// MARK: - Content State Enum
enum ContentState<T> {
    case idle
    case loading
    case loaded(T)
    case empty(message: String? = nil)
    case error(Error)
    case offline
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var hasContent: Bool {
        if case .loaded = self { return true }
        return false
    }
}

// MARK: - Basic Skeleton View
struct PiggySkeletonView: View {
    @State private var opacity: Double = 0.3
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.15))
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.7
                }
            }
    }
}

// MARK: - Simple State Container (No Complex Dependencies)
struct PiggyStateContainer<Content: View, Data>: View {
    let state: ContentState<Data>
    let content: (Data) -> Content
    let onRetry: (() -> Void)?
    
    init(
        state: ContentState<Data>,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
    }
    
    var body: some View {
        switch state {
        case .idle:
            Color.clear
            
        case .loading:
            VStack {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.piggyPrimary)
                Text("Loading...")
                    .foregroundColor(.white.opacity(0.7))
            }
            
        case .loaded(let data):
            content(data)
            
        case .empty(let message):
            VStack(spacing: 20) {
                Image(systemName: "tray")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("No Data")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                
                if let onRetry = onRetry {
                    Button("Try Again", action: onRetry)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.piggyPrimary)
                        .cornerRadius(8)
                }
            }
            .padding()
            
        case .error(let error):
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                if let onRetry = onRetry {
                    Button("Try Again", action: onRetry)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.piggyPrimary)
                        .cornerRadius(8)
                }
            }
            .padding()
            
        case .offline:
            VStack(spacing: 20) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("You're Offline")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Check your connection and try again")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                if let onRetry = onRetry {
                    Button("Retry", action: onRetry)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

// MARK: - Animated Placeholder (Simple)
struct PiggyAnimatedPlaceholder: View {
    let text: String
    let emoji: String
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            Text(emoji)
                .font(.system(size: 60))
                .scaleEffect(1.0 + animationAmount * 0.1)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: animationAmount
                )
            
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .onAppear {
            animationAmount = 1.0
        }
    }
}

// MARK: - Simple Refreshable Wrapper
struct PiggyRefreshable<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    
    init(
        @ViewBuilder content: () -> Content,
        onRefresh: @escaping () async -> Void
    ) {
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            await onRefresh()
        }
    }
}