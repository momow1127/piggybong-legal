import SwiftUI

// MARK: - Loading State View Component
struct LoadingStateView: View {
    let isEmpty: Bool
    let hasError: Bool
    let message: String?
    let onRetry: (() -> Void)?
    
    init(
        isEmpty: Bool = false,
        hasError: Bool = false,
        message: String? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.isEmpty = isEmpty
        self.hasError = hasError
        self.message = message
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: PiggySpacing.md) {
            if hasError {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: PiggyIcon.emptyState))
                    .foregroundColor(.piggyError)
                
                Text("Something went wrong")
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)
                
                if let onRetry = onRetry {
                    Button("Retry", action: onRetry)
                        .font(PiggyFont.button)
                        .foregroundColor(.piggyPrimary)
                }
            } else if isEmpty {
                Image(systemName: "chart.bar")
                    .font(.system(size: PiggyIcon.emptyState))
                    .foregroundColor(.piggyTextSecondary)
                
                Text("No data yet")
                    .font(PiggyFont.title3)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(message ?? "Start by adding some fan activities")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
                    .multilineTextAlignment(.center)
            } else {
                // Loading state
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .piggyTextPrimary))
                
                Text("Loading your fan dashboard...")
                    .font(PiggyFont.body)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
        .padding(PiggySpacing.xl)
    }
}

// MARK: - Preview
struct LoadingStateView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: PiggySpacing.lg) {
            LoadingStateView()
            LoadingStateView(isEmpty: true)
            LoadingStateView(hasError: true, onRetry: {})
        }
        .background(PiggyGradients.background)
    }
}