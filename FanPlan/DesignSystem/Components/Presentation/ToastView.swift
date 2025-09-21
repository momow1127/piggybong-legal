import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    enum ToastType {
        case success
        case warning
        case error
        
        var backgroundColor: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(message)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(type.backgroundColor)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Above tab bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isShowing = false
                    }
                }
            }
        }
        .allowsHitTesting(isShowing)
    }
}

// MARK: - Toast Manager
@MainActor
class ToastManager: ObservableObject {
    @Published var isShowing = false
    @Published var message = ""
    @Published var type: ToastView.ToastType = .success
    
    func showToast(message: String, type: ToastView.ToastType = .success) {
        self.message = message
        self.type = type
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isShowing = true
        }
        
        // Auto dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.isShowing = false
            }
        }
    }
    
    func hideToast() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isShowing = false
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @StateObject private var toastManager = ToastManager()
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ToastView(
                message: toastManager.message,
                type: toastManager.type,
                isShowing: $toastManager.isShowing
            )
        }
        .environmentObject(toastManager)
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

#Preview {
    VStack {
        Spacer()
        
        Button("Show Success Toast") {
            // Preview functionality
        }
        
        Button("Show Warning Toast") {
            // Preview functionality
        }
        
        Button("Show Error Toast") {
            // Preview functionality
        }
        
        Spacer()
    }
    .withToast()
}