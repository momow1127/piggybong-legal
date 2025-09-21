import SwiftUI

// MARK: - Budget Header Component
struct BudgetHeader: View {
    @Binding var selectedTimeframe: TimeFrame
    @Binding var showingFilters: Bool
    @Binding var showingHistory: Bool
    let animateCards: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Top navigation
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Manage your K-pop expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Search button
                    NavigationButton(icon: "magnifyingglass") {
                        // Handle search
                        HapticManager.light()
                    }
                    
                    // Filter button
                    NavigationButton(icon: "line.3.horizontal.decrease") {
                        showingFilters = true
                        HapticManager.light()
                    }
                    
                    // History button
                    NavigationButton(icon: "clock") {
                        showingHistory = true
                        HapticManager.light()
                    }
                }
            }
            
            // Time frame selector
            TimeFrameSelector(selectedTimeframe: $selectedTimeframe)
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : -20)
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Time Frame Selector
struct TimeFrameSelector: View {
    @Binding var selectedTimeframe: TimeFrame
    
    private func backgroundGradient(for timeframe: TimeFrame) -> some ShapeStyle {
        if selectedTimeframe == timeframe {
            return AnyShapeStyle(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
        } else {
            return AnyShapeStyle(Color.clear)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                Button(timeframe.displayName) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTimeframe = timeframe
                    }
                    HapticManager.light()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedTimeframe == timeframe ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(backgroundGradient(for: timeframe))
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}


