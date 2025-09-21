import SwiftUI
import Charts

struct MonthlyReviewView: View {
    @State private var monthlyData: MonthlyReviewData?
    @State private var isLoading = true
    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView("加载本月数据...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if let data = monthlyData {
                    LazyVStack(spacing: 24) {
                        // Month Picker
                        monthPicker
                        
                        // Summary Card
                        summaryCard(data)
                        
                        // Goals Progress
                        goalsProgressSection(data)
                        
                        // Top Categories
                        topCategoriesSection(data)
                        
                        // Weekly Breakdown
                        weeklyBreakdownSection(data)
                        
                        // Achievements & Insights
                        achievementsSection(data)
                        
                        // Next Month Planning
                        planningSection(data)
                    }
                    .padding()
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("本月回顾")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadMonthlyData()
            }
            .onChange(of: selectedMonth) {
                loadMonthlyData()
            }
        }
    }
    
    private var monthPicker: some View {
        VStack {
            DatePicker(
                "选择月份",
                selection: $selectedMonth,
                displayedComponents: [.date]
            )
            .datePickerStyle(CompactDatePickerStyle())
            .labelsHidden()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func summaryCard(_ data: MonthlyReviewData) -> some View {
        VStack(spacing: 20) {
            // Main Stats
            HStack {
                Spacer()
                
                VStack {
                    Text("总支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(Int(data.totalSpent))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack {
                    Text("vs 上月")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: data.comparisonIcon)
                        Text("\(data.monthOverMonthChange)%")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(data.comparisonColor)
                }
                
                Spacer()
            }
            
            // Budget Progress
            VStack(spacing: 8) {
                HStack {
                    Text("预算使用")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("¥\(Int(data.totalSpent)) / ¥\(Int(data.budget))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: data.budgetUsage, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: data.budgetColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            Text(data.budgetInsight)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func goalsProgressSection(_ data: MonthlyReviewData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("目标达成")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(data.goals) { goal in
                    GoalProgressRow(goal: goal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func topCategoriesSection(_ data: MonthlyReviewData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支出分类")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data.topCategories) { category in
                BarMark(
                    x: .value("金额", category.amount),
                    y: .value("分类", category.name)
                )
                .foregroundStyle(.blue)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("¥\(Int(amount))")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func weeklyBreakdownSection(_ data: MonthlyReviewData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("周度趋势")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data.weeklyBreakdown) { week in
                BarMark(
                    x: .value("周", week.weekLabel),
                    y: .value("金额", week.amount)
                )
                .foregroundStyle(.orange)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("¥\(Int(amount))")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func achievementsSection(_ data: MonthlyReviewData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("本月成就")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(data.achievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private func planningSection(_ data: MonthlyReviewData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("下月规划")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(data.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(recommendation)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("暂无数据")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("开始记录支出，查看月度分析")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    // MARK: - Helper Views
    struct GoalProgressRow: View {
        let goal: GoalProgress
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Text(goal.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(goal.isCompleted ? .green : .orange)
                }
                
                ProgressView(value: goal.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: goal.isCompleted ? .green : .orange))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
        }
    }
    
    struct AchievementRow: View {
        let achievement: MonthlyAchievement
        
        var body: some View {
            HStack(spacing: 12) {
                Text(achievement.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if achievement.isNew {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadMonthlyData() {
        isLoading = true
        
        Task {
            do {
                // Simulate API call delay
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                let mockData = createMockData()
                
                await MainActor.run {
                    monthlyData = mockData
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func createMockData() -> MonthlyReviewData {
        MonthlyReviewData(
            totalSpent: 1580.0,
            budget: 2000.0,
            monthOverMonthChange: 12,
            goals: [
                GoalProgress(name: "控制演唱会支出", progress: 0.8, isCompleted: false),
                GoalProgress(name: "每日记录支出", progress: 1.0, isCompleted: true),
                GoalProgress(name: "节省交通费", progress: 0.6, isCompleted: false)
            ],
            topCategories: [
                CategoryAmount(name: "演唱会", amount: 680),
                CategoryAmount(name: "专辑", amount: 320),
                CategoryAmount(name: "周边", amount: 280),
                CategoryAmount(name: "交通", amount: 200),
                CategoryAmount(name: "其他", amount: 100)
            ],
            weeklyBreakdown: [
                WeeklyAmount(weekLabel: "第1周", amount: 450),
                WeeklyAmount(weekLabel: "第2周", amount: 320),
                WeeklyAmount(weekLabel: "第3周", amount: 510),
                WeeklyAmount(weekLabel: "第4周", amount: 300)
            ],
            achievements: [
                MonthlyAchievement(
                    icon: "🎯",
                    title: "记录达人",
                    description: "连续30天记录支出",
                    isNew: true
                ),
                MonthlyAchievement(
                    icon: "💰",
                    title: "预算控制",
                    description: "支出未超预算",
                    isNew: false
                ),
                MonthlyAchievement(
                    icon: "📊",
                    title: "数据分析师",
                    description: "查看分析页面10次",
                    isNew: false
                )
            ],
            recommendations: [
                "演唱会支出占比较高(43%)，可考虑设置单项预算",
                "周末支出波动较大，建议制定周末消费计划",
                "已连续记录30天，保持良好习惯！",
                "下月预算建议：¥1800（比本月略减）"
            ]
        )
    }
}

// MARK: - Data Models
struct MonthlyReviewData {
    let totalSpent: Double
    let budget: Double
    let monthOverMonthChange: Int
    let goals: [GoalProgress]
    let topCategories: [CategoryAmount]
    let weeklyBreakdown: [WeeklyAmount]
    let achievements: [MonthlyAchievement]
    let recommendations: [String]
    
    var budgetUsage: Double {
        min(totalSpent / budget, 1.0)
    }
    
    var budgetColor: Color {
        if budgetUsage < 0.7 { return .green }
        else if budgetUsage < 0.9 { return .orange }
        else { return .red }
    }
    
    var budgetInsight: String {
        let remaining = budget - totalSpent
        if remaining > 0 {
            return "还剩 ¥\(Int(remaining)) 预算"
        } else {
            return "已超预算 ¥\(Int(abs(remaining)))"
        }
    }
    
    var comparisonIcon: String {
        monthOverMonthChange > 0 ? "arrow.up" : "arrow.down"
    }
    
    var comparisonColor: Color {
        monthOverMonthChange > 0 ? .red : .green
    }
}

struct GoalProgress: Identifiable {
    let id = UUID()
    let name: String
    let progress: Double
    let isCompleted: Bool
}

struct CategoryAmount: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}

struct WeeklyAmount: Identifiable {
    let id = UUID()
    let weekLabel: String
    let amount: Double
}

struct MonthlyAchievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let isNew: Bool
}

#Preview {
    MonthlyReviewView()
}