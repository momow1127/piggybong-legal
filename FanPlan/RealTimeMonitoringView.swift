import SwiftUI

// MARK: - Real-Time Monitoring Control View
struct RealTimeMonitoringView: View {
    @EnvironmentObject private var realTimeService: RealTimeNotificationService
    @EnvironmentObject private var notificationService: ArtistNotificationService
    @State private var showingTestAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            headerView
            
            if realTimeService.isMonitoring {
                activeMonitoringView
            } else {
                inactiveMonitoringView
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.piggyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.piggyCardBorder, lineWidth: 1)
                )
        )
        .onAppear {
            // Request notification permissions if not already granted
            if !notificationService.isNotificationsEnabled {
                Task {
                    await notificationService.requestNotificationPermission()
                }
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 20))
                .foregroundColor(.piggyPrimary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Live K-pop Monitoring")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Real-time comeback notifications")
                    .font(.system(size: 13))
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { realTimeService.isMonitoring },
                set: { isEnabled in
                    if isEnabled {
                        realTimeService.startRealTimeMonitoring()
                    } else {
                        realTimeService.stopRealTimeMonitoring()
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle())
        }
    }
    
    @ViewBuilder
    private var activeMonitoringView: some View {
        // Status Information
        VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Live monitoring active")
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(timeAgoString(from: realTimeService.lastCheckTime))
                            .font(.system(size: 12))
                            .foregroundColor(.piggyTextSecondary)
                    }
                    
                    // Monitored Artists
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Watching for:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.piggyTextSecondary)
                        
                        FlowLayout(spacing: 6) {
                            ForEach(Array(realTimeService.monitoredArtists.sorted()), id: \.self) { artist in
                                artistBadge(artist)
                            }
                        }
                    }
                    
                    // Dynamic Test Notifications
                    if !realTimeService.userSelectedArtists.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Test notifications:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.piggyTextSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(realTimeService.userSelectedArtists, id: \.id) { artist in
                                        HStack(spacing: 4) {
                                            Button("🎉 \(artist.name)") {
                                                Task {
                                                    await realTimeService.testNotificationForArtist(artist)
                                                }
                                            }
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(10)
                                            
                                            Button("🚨") {
                                                Task {
                                                    await realTimeService.testUrgentNotificationForArtist(artist)
                                                }
                                            }
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(10)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    } else {
                        HStack {
                            Text("Select artists to enable notifications")
                                .font(.system(size: 12))
                                .foregroundColor(.piggyTextSecondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.green.opacity(0.3), lineWidth: 1)
                        )
                )
    }
    
    @ViewBuilder
    private var inactiveMonitoringView: some View {
        // Offline Status
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(.gray)
                    .frame(width: 8, height: 8)
                
                Text("Monitoring paused")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            Text("Turn on to get instant notifications when IVE, aespa, and other artists announce comebacks!")
                .font(.system(size: 12))
                .foregroundColor(.piggyTextSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func artistBadge(_ artist: String) -> some View {
        Text(artist)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.piggyPrimary.opacity(0.2))
            )
            .foregroundColor(.piggyPrimary)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }
}

// MARK: - Flow Layout for Artist Badges
struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: spacing) {
            content()
        }
    }
}

#Preview {
    RealTimeMonitoringView()
        .environmentObject(RealTimeNotificationService.shared)
        .environmentObject(ArtistNotificationService.shared)
        .background(PiggyGradients.background)
}