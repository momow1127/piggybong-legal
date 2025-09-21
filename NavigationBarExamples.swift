import SwiftUI

// MARK: - Navigation Bar Usage Examples

// Example 1: Modal Presentation (Sheet/FullScreenCover)
struct ExampleModalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("This is a modal view")
                    Text("Navigation bar has gradient background")
                    Text("Title and Done button are white")
                }
                .padding()
            }
            .background(PiggyGradients.background.ignoresSafeArea())
            .piggyModalNavigationBar(title: "Modal Example") {
                dismiss()
            }
        }
    }
}

// Example 2: Pushed Screen with Default Back
struct ExamplePushedView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("This is a pushed view")
                Text("Uses system back button")
                Text("Large title style with gradient")
            }
            .padding()
        }
        .background(PiggyGradients.background.ignoresSafeArea())
        .piggyNavigationBar(title: "Pushed Example", displayMode: .large)
    }
}

// Example 3: Pushed Screen with Custom Back Action
struct ExampleCustomBackView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("This is a pushed view with custom back")
                Text("Custom back button handling")
                Text("Useful for unsaved changes confirmation")
            }
            .padding()
        }
        .background(PiggyGradients.background.ignoresSafeArea())
        .piggyPushedNavigationBar(title: "Custom Back") {
            // Custom back logic here
            handleBackButton()
        }
    }
    
    private func handleBackButton() {
        // You can add confirmation dialogs, save logic, etc.
        dismiss()
    }
}

// Example 4: View with Additional Toolbar Items
struct ExampleToolbarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("View with additional toolbar items")
                    Text("Multiple buttons in navigation bar")
                }
                .padding()
            }
            .background(PiggyGradients.background.ignoresSafeArea())
            .piggyNavigationBar(title: "Toolbar Example", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ExampleModalView()
        }
    }
}

// Example 5: Scrollable Content (Tests Scroll Edge Appearance)
struct ExampleScrollableView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(0..<50, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Item \(index + 1)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("This tests scroll behavior with the gradient navigation bar. The appearance should remain consistent when scrolling.")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .background(PiggyGradients.background.ignoresSafeArea())
            .piggyNavigationBar(title: "Scrollable Test", displayMode: .large)
        }
    }
}

#Preview("Modal View") {
    ExampleModalView()
}

#Preview("Pushed View") {
    NavigationView {
        ExamplePushedView()
    }
}

#Preview("Custom Back View") {
    NavigationView {
        ExampleCustomBackView()
    }
}

#Preview("Toolbar View") {
    ExampleToolbarView()
}

#Preview("Scrollable View") {
    ExampleScrollableView()
}