import SwiftUI

// MARK: - Permission Card
struct PermissionCard: View {
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let isEnabled: Bool
    let isPending: Bool
    let showToggle: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: PiggySpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: PiggyBorderRadius.md)
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if isPending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: iconColor))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(PiggyFont.bodyEmphasized)
                        .foregroundColor(.piggyTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(description)
                        .font(PiggyFont.caption1)
                        .foregroundColor(.piggyTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                
                // Status indicator
                if showToggle {
                    Toggle("", isOn: .constant(isEnabled))
                        .labelsHidden()
                        .disabled(true)
                } else {
                    VStack {
                        if isPending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .piggyPrimary))
                                .scaleEffect(0.8)
                        } else if isEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.piggyPrimary)
                        }
                    }
                    .frame(width: 24, height: 24)
                }
            }
            .padding(PiggySpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                    .fill(Color.piggySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: PiggyBorderRadius.lg)
                            .stroke(
                                isEnabled ? Color.green.opacity(0.3) : Color.piggyTextSecondary.opacity(0.1),
                                lineWidth: isEnabled ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .disabled(isPending)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        PermissionCard(
            title: "Push Notifications",
            description: "Get timely updates about concerts, albums, and events",
            iconName: "bell.fill",
            iconColor: .blue,
            isEnabled: false,
            isPending: false,
            showToggle: false
        ) {
            print("Permission card tapped")
        }
        
        PermissionCard(
            title: "Push Notifications",
            description: "Get timely updates about concerts, albums, and events",
            iconName: "bell.fill",
            iconColor: .blue,
            isEnabled: true,
            isPending: false,
            showToggle: false
        ) {
            print("Permission card tapped")
        }
    }
    .padding()
}