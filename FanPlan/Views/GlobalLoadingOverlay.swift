import SwiftUI

// MARK: - Global Loading Overlay View
struct GlobalLoadingOverlay: View {
    @EnvironmentObject private var globalLoading: GlobalLoadingManager

    var body: some View {
        ZStack {
            if globalLoading.isVisible {
                // Full screen overlay with proper z-index
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(true) // Block all interactions
                    .transition(.opacity)

                // Your existing beautiful LoadingView
                OverlayLoadingView(
                    message: globalLoading.message,
                    isSimpleMode: globalLoading.isSimpleMode
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .opacity.combined(with: .scale(scale: 1.1))
                ))
            }
        }
        .zIndex(999) // Ensure it's always on top
        .animation(.easeInOut(duration: 0.3), value: globalLoading.isVisible)
    }
}

#Preview("Global Loading") {
    ZStack {
        Color.black
        GlobalLoadingOverlay()
    }
    .environmentObject(GlobalLoadingManager.shared)
}