import SwiftUI

// MARK: - Greeting Row Component
struct GreetingRowView: View {
    var hasUnreadNotifications: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Hello K-pop fans!")
                .font(PiggyFont.bodyMedium)
                .foregroundColor(.white)

            Spacer()

            NavigationLink(destination: NotificationListView()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)

                    if hasUnreadNotifications {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        // ❗️Don't add horizontal padding here. Assume parent (e.g. LazyVStack) provides it.
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        VStack(spacing: 20) {
            GreetingRowView(hasUnreadNotifications: false)
            GreetingRowView(hasUnreadNotifications: true)
        }
        .padding()
        .background(PiggyGradients.background)
    }
}