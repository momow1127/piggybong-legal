import SwiftUI
import Charts

// MARK: - Responsive Dashboard with Interactive Charts
struct ResponsiveDashboard: View {
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @StateObject private var dashboardViewModel = ResponsiveDashboardViewModel()
    @State private var selectedMetric: DashboardMetric = .spending
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingDetailView = false
    @State private var selectedChartData: ChartDataPoint?
    
    // Responsive layout properties
    @State private var screenSize: CGSize = .zero
    @State private var isCompact: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.05)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header with greeting and metrics
                            headerSection
                            
                            // Quick metrics cards
                            metricsSection
                            
                            // Time range selector
                            timeRangeSelector
                            
                            // Interactive charts section
                            chartsSection
                            
                            // Goals progress section
                            goalsSection
                            
                            // Recent activity section
                            activitySection
                            
                            // Insights and recommendations
                            insightsSection
                        }
                        .padding(.horizontal, isCompact ? 12 : 20)
                        .padding(.vertical, 8)
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    screenSize = geometry.size
                    isCompact = geometry.size.width < 375
                    dashboardViewModel.loadDashboardData()
                }
                .onChange(of: geometry.size) { newSize in
                    screenSize = newSize
                    isCompact = newSize.width < 375
                }
                .onChange(of: selectedTimeRange) { _ in
                    dashboardViewModel.updateTimeRange(selectedTimeRange)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good \(currentTimeGreeting()),")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.piggyTextSecondary)
                    
                    Text("K-pop Fan!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.piggyTextPrimary)
                }
                
                Spacer()
                
                // Profile/Settings button
                Button(action: {}) {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundColor(.piggyPrimary)
                }
            }
            
            // Current month overview
            Text("Your fandom journey this \(getCurrentMonth())")
                .font(.subheadline)
                .foregroundColor(.piggyTextSecondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        let columns = isCompact ? 
            Array(repeating: GridItem(.flexible(), spacing: 12), count: 2) :
            Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
        
        LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(
                title: "Spent This Month",
                value: "$\(Int(dashboardViewModel.monthlySpent))",
                subtitle: "of $\(Int(dashboardViewModel.monthlyBudget))",
                progress: dashboardViewModel.spendingProgress,
                color: dashboardViewModel.spendingProgress > 0.8 ? .red : .blue,
                icon: "creditcard",
                isSelected: selectedMetric == .spending
            ) {
                selectedMetric = .spending
            }
            
            MetricCard(
                title: "Saved Total",
                value: "$\(Int(dashboardViewModel.totalSaved))",
                subtitle: "\(dashboardViewModel.savingsGrowth > 0 ? "+" : "")\(Int(dashboardViewModel.savingsGrowth))% this month",
                progress: min(dashboardViewModel.totalSaved / 1000, 1.0),
                color: .green,
                icon: "arrow.up.circle",
                isSelected: selectedMetric == .savings
            ) {
                selectedMetric = .savings
            }
            
            if !isCompact {
                MetricCard(
                    title: "Active Goals",
                    value: "\(dashboardViewModel.activeGoalsCount)",
                    subtitle: "\(dashboardViewModel.completedGoalsCount) completed",
                    progress: Double(dashboardViewModel.completedGoalsCount) / max(Double(dashboardViewModel.activeGoalsCount + dashboardViewModel.completedGoalsCount), 1.0),
                    color: .purple,
                    icon: "target",
                    isSelected: selectedMetric == .goals
                ) {
                    selectedMetric = .goals
                }
            }
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .background(Color.white)
        .cornerRadius(8)
    }
    
    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(spacing: 16) {
            // Main interactive chart based on selected metric
            mainChartCard
            
            // Secondary charts in responsive layout
            if !isCompact {
                HStack(spacing: 16) {
                    categoryBreakdownChart
                    goalProgressChart
                }
            } else {
                // Stack vertically on compact screens
                VStack(spacing: 16) {
                    categoryBreakdownChart
                    goalProgressChart
                }
            }
        }
    }
    
    // MARK: - Main Chart Card
    private var mainChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedMetric.title)
                        .font(.headline)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Text(selectedMetric.subtitle)
                        .font(.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                Spacer()
                
                Button(action: { showingDetailView = true }) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.piggyPrimary)
                }
            }
            
            // Interactive chart based on selected metric
            Group {
                switch selectedMetric {
                case .spending:
                    spendingTrendChart
                case .savings:
                    savingsGrowthChart
                case .goals:
                    goalsProgressOverTimeChart
                }
            }
            .frame(height: isCompact ? 200 : 250)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Spending Trend Chart
    private var spendingTrendChart: some View {
        Chart(dashboardViewModel.spendingData) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Amount", dataPoint.value)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            .symbol(.circle)
            .symbolSize(selectedChartData?.id == dataPoint.id ? 60 : 30)
            
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value("Amount", dataPoint.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: selectedTimeRange.axisStride)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: selectedTimeRange.dateFormat)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text("$\(Int(amount))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        TapGesture()
                            .onEnded { location in
                                // Handle chart tap for data point selection
                                if let dataPoint = findNearestDataPoint(at: location, in: geometry, chartProxy: chartProxy) {
                                    selectedChartData = dataPoint
                                }
                            }
                    )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedChartData)
    }
    
    // MARK: - Savings Growth Chart
    private var savingsGrowthChart: some View {
        Chart(dashboardViewModel.savingsData) { dataPoint in
            BarMark(
                x: .value("Date", dataPoint.date),
                y: .value("Amount", dataPoint.value)
            )
            .foregroundStyle(.green)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: selectedTimeRange.axisStride)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: selectedTimeRange.dateFormat)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text("$\(Int(amount))")
                            .font(.caption2)
                    }
                }
            }
        }
    }
    
    // MARK: - Goals Progress Over Time Chart
    private var goalsProgressOverTimeChart: some View {
        Chart(dashboardViewModel.goalsProgressData) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(.purple)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            
            PointMark(
                x: .value("Date", dataPoint.date),
                y: .value("Progress", dataPoint.value)
            )
            .foregroundStyle(.purple)
            .symbolSize(40)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: selectedTimeRange.axisStride)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: selectedTimeRange.dateFormat)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let progress = value.as(Double.self) {
                        Text("\(Int(progress))%")
                            .font(.caption2)
                    }
                }
            }
        }
    }
    
    // MARK: - Category Breakdown Chart
    private var categoryBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.piggyTextPrimary)
            
            Chart(dashboardViewModel.categoryData) { category in
                SectorMark(
                    angle: .value("Amount", category.value),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", category.label))
                .cornerRadius(4)
            }
            .frame(height: isCompact ? 150 : 180)
            .chartLegend(position: .bottom, alignment: .center, spacing: 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Goal Progress Chart
    private var goalProgressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Progress")
                .font(.headline)
                .foregroundColor(.piggyTextPrimary)
            
            Chart(dashboardViewModel.goalsData.prefix(5)) { goal in
                BarMark(
                    x: .value("Progress", goal.value),
                    y: .value("Goal", goal.label)
                )
                .foregroundStyle(goal.value >= 100 ? .green : .blue)
                .cornerRadius(4)
            }
            .frame(height: isCompact ? 150 : 180)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let progress = value.as(Double.self) {
                            Text("\(Int(progress))%")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to goals view
                }
                .font(.caption)
                .foregroundColor(.piggyPrimary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(dashboardViewModel.topGoals) { goal in
                    GoalProgressRow(goal: goal)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to activity view
                }
                .font(.caption)
                .foregroundColor(.piggyPrimary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(dashboardViewModel.recentActivities.prefix(3)) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Insights")
                .font(.headline)
                .foregroundColor(.piggyTextPrimary)
            
            LazyVStack(spacing: 8) {
                ForEach(dashboardViewModel.insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    private func currentTimeGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    private func getCurrentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    private func findNearestDataPoint(at location: CGPoint, in geometry: GeometryProxy, chartProxy: ChartProxy) -> ChartDataPoint? {
        // Implementation for finding nearest data point on chart tap
        // This would involve converting the tap location to chart coordinates
        return dashboardViewModel.spendingData.first // Simplified for demo
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let color: Color
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(color)
                    }
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.piggyTextSecondary)
                    .lineLimit(2)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(y: 0.5)
            }
            .padding(12)
            .background(isSelected ? color.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalProgressRow: View {
    let goal: DashboardGoal
    
    var body: some View {
        HStack(spacing: 12) {
            // Goal icon
            Image(systemName: goal.icon)
                .font(.title3)
                .foregroundColor(goal.color)
                .frame(width: 32, height: 32)
                .background(goal.color.opacity(0.1))
                .cornerRadius(8)
            
            // Goal details
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.piggyTextPrimary)
                
                Text("$\(Int(goal.currentAmount)) of $\(Int(goal.targetAmount))")
                    .font(.caption)
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Spacer()
            
            // Progress indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(goal.progress))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(goal.color)
                
                ProgressView(value: goal.progress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: goal.color))
                    .frame(width: 60)
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivityRow: View {
    let activity: DashboardActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 32, height: 32)
                .background(activity.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.piggyTextSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let amount = activity.amount {
                    Text(amount > 0 ? "+$\(Int(amount))" : "-$\(Int(abs(amount)))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(amount > 0 ? .green : .red)
                }
                
                Text(activity.relativeTime)
                    .font(.caption2)
                    .foregroundColor(.piggyTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InsightCard: View {
    let insight: DashboardInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title3)
                .foregroundColor(insight.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.piggyTextPrimary)
                
                Text(insight.message)
                    .font(.caption)
                    .foregroundColor(.piggyTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let actionTitle = insight.actionTitle {
                Button(actionTitle) {
                    // Handle insight action
                }
                .font(.caption)
                .foregroundColor(insight.color)
            }
        }
        .padding(12)
        .background(insight.color.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(insight.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Data Models

enum DashboardMetric: CaseIterable {
    case spending, savings, goals
    
    var title: String {
        switch self {
        case .spending: return "Spending Trends"
        case .savings: return "Savings Growth"
        case .goals: return "Goal Progress"
        }
    }
    
    var subtitle: String {
        switch self {
        case .spending: return "Track your fandom expenses"
        case .savings: return "Monitor your savings growth"
        case .goals: return "See your progress over time"
        }
    }
}

enum TimeRange: CaseIterable {
    case week, month, threeMonths, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        case .year: return "Year"
        }
    }
    
    var axisStride: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .weekOfYear
        case .threeMonths: return .month
        case .year: return .month
        }
    }
    
    var dateFormat: Date.FormatStyle {
        switch self {
        case .week: return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day()
        case .threeMonths: return .dateTime.month(.abbreviated)
        case .year: return .dateTime.month(.abbreviated)
        }
    }
}

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

struct DashboardGoal: Identifiable {
    let id = UUID()
    let title: String
    let currentAmount: Double
    let targetAmount: Double
    let progress: Double
    let color: Color
    let icon: String
}

struct DashboardActivity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: Double?
    let relativeTime: String
    let color: Color
    let icon: String
}

struct DashboardInsight: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actionTitle: String?
    let color: Color
    let icon: String
}

#Preview {
    ResponsiveDashboard()
        .environmentObject(RevenueCatManager())
}