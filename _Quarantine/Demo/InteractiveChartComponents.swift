import SwiftUI
import Charts

// MARK: - Interactive Chart Components

struct InteractiveLineChart: View {
    let data: [ChartDataPoint]
    let title: String
    let color: Color
    let timeRange: TimeRange
    
    @State private var selectedDataPoint: ChartDataPoint?
    @State private var showingTooltip = false
    @GestureState private var dragLocation: CGPoint = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart header with selected value
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                if let selected = selectedDataPoint {
                    Text("$\\(Int(selected.value))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
            }
            
            // Interactive chart
            Chart(data) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Amount", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Highlight selected point
                if let selected = selectedDataPoint, selected.id == dataPoint.id {
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(100)
                    .symbol(.circle)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.axisStride)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: timeRange.dateFormat)
                                .font(.caption2)
                                .foregroundColor(.piggyTextSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\\(Int(amount))")
                                .font(.caption2)
                                .foregroundColor(.piggyTextSecondary)
                        }
                    }
                }
            }
            .chartBackground { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            selectDataPoint(at: location, geometry: geometry, proxy: proxy)
                        }
                        .gesture(
                            DragGesture()
                                .updating($dragLocation) { value, state, _ in
                                    state = value.location
                                    selectDataPoint(at: value.location, geometry: geometry, proxy: proxy)
                                }
                        )
                }
            }
            .overlay(alignment: .topTrailing) {
                if showingTooltip, let selected = selectedDataPoint {
                    TooltipView(dataPoint: selected, color: color)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedDataPoint)
        }
    }
    
    private func selectDataPoint(at location: CGPoint, geometry: GeometryProxy, proxy: ChartProxy) {
        // Convert tap location to date
        let frame = geometry[proxy.plotAreaFrame]
        let relativeX = location.x - frame.origin.x
        let relativeWidth = relativeX / frame.width
        
        guard relativeWidth >= 0 && relativeWidth <= 1 else { return }
        
        // Find closest data point
        let sortedData = data.sorted { $0.date < $1.date }
        let index = Int(relativeWidth * Double(sortedData.count - 1))
        let clampedIndex = max(0, min(index, sortedData.count - 1))
        
        selectedDataPoint = sortedData[clampedIndex]
        showingTooltip = true
        
        // Hide tooltip after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if showingTooltip {
                withAnimation {
                    showingTooltip = false
                    selectedDataPoint = nil
                }
            }
        }
    }
}

struct InteractiveDonutChart: View {
    let data: [ChartDataPoint]
    let title: String
    let total: Double
    
    @State private var selectedSegment: ChartDataPoint?
    @State private var animationProgress: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                if let selected = selectedSegment {
                    Text("\\(Int(selected.value))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForCategory(selected.label))
                }
            }
            
            HStack(spacing: 20) {
                // Donut chart
                Chart(data) { segment in
                    SectorMark(
                        angle: .value("Value", segment.value * animationProgress),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(colorForCategory(segment.label))
                    .cornerRadius(4)
                    .opacity(selectedSegment == nil || selectedSegment?.id == segment.id ? 1.0 : 0.6)
                    .scaleEffect(selectedSegment?.id == segment.id ? 1.1 : 1.0)
                }
                .frame(width: 150, height: 150)
                .onTapGesture { location in
                    // Simple segment selection - could be enhanced with hit testing
                    if selectedSegment == nil {
                        selectedSegment = data.first
                    } else {
                        selectedSegment = nil
                    }
                }
                .overlay {
                    // Center text
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.piggyTextSecondary)
                        Text("$\\(Int(total))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.piggyTextPrimary)
                    }
                }
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data.prefix(4)) { segment in
                        LegendItem(
                            segment: segment,
                            color: colorForCategory(segment.label),
                            isSelected: selectedSegment?.id == segment.id
                        ) {
                            selectedSegment = selectedSegment?.id == segment.id ? nil : segment
                        }
                    }
                    
                    if data.count > 4 {
                        Text("+ \\(data.count - 4) more")
                            .font(.caption)
                            .foregroundColor(.piggyTextSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedSegment)
    }
    
    private func colorForCategory(_ category: String) -> Color {
        let colors: [String: Color] = [
            "Concert Tickets": .purple,
            "Albums": .blue,
            "Merchandise": .pink,
            "Digital Content": .orange,
            "Transportation": .green,
            "Food": .yellow,
            "Other": .gray
        ]
        return colors[category] ?? .gray
    }
}

struct InteractiveBarChart: View {
    let data: [ChartDataPoint]
    let title: String
    let color: Color
    
    @State private var selectedBar: ChartDataPoint?
    @State private var animationProgress: Double = 0
    
    var maxValue: Double {
        data.map(\.value).max() ?? 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.piggyTextPrimary)
                
                Spacer()
                
                if let selected = selectedBar {
                    Text("\\(Int(selected.value))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
            }
            
            // Horizontal bar chart
            VStack(alignment: .leading, spacing: 8) {
                ForEach(data.prefix(5)) { item in
                    HStack(spacing: 12) {
                        // Label
                        Text(item.label)
                            .font(.caption)
                            .foregroundColor(.piggyTextPrimary)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(2)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color.opacity(0.2))
                                    .frame(height: 16)
                                
                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedBar?.id == item.id ? color : color.opacity(0.8))
                                    .frame(
                                        width: geometry.size.width * (item.value / maxValue) * animationProgress,
                                        height: 16
                                    )
                                    .animation(.easeOut(duration: 0.8).delay(Double(data.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.1), value: animationProgress)
                            }
                        }
                        .frame(height: 16)
                        .onTapGesture {
                            selectedBar = selectedBar?.id == item.id ? nil : item
                        }
                        
                        // Value
                        Text("\\(Int(item.value))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.piggyTextSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .frame(height: 24)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1.0
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedBar)
    }
}

struct SparklineChart: View {
    let data: [ChartDataPoint]
    let color: Color
    let showPoints: Bool
    
    init(data: [ChartDataPoint], color: Color = .blue, showPoints: Bool = false) {
        self.data = data
        self.color = color
        self.showPoints = showPoints
    }
    
    var body: some View {
        Chart(data) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", dataPoint.value)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            
            if showPoints {
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(color)
                .symbolSize(20)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 40)
    }
}

// MARK: - Supporting Views

struct TooltipView: View {
    let dataPoint: ChartDataPoint
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dataPoint.date, format: .dateTime.month().day())
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            
            Text("$\\(Int(dataPoint.value))")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

struct LegendItem: View {
    let segment: ChartDataPoint
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.label)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.piggyTextPrimary)
                    
                    Text("\\(Int(segment.value))%")
                        .font(.caption2)
                        .foregroundColor(.piggyTextSecondary)
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Chart Container Views

struct ResponsiveChartContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let isCompact: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(isCompact ? .subheadline : .headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.piggyTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.piggyTextSecondary)
                }
            }
            
            // Chart content
            content()
        }
        .padding(isCompact ? 12 : 16)
        .background(Color.white)
        .cornerRadius(isCompact ? 12 : 16)
        .shadow(
            color: .black.opacity(0.1),
            radius: isCompact ? 4 : 8,
            x: 0,
            y: isCompact ? 1 : 2
        )
    }
}

struct ChartLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .piggyPrimary))
            
            Text("Loading chart data...")
                .font(.caption)
                .foregroundColor(.piggyTextSecondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

struct ChartErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Failed to load chart")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.piggyTextPrimary)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.piggyTextSecondary)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: retry)
                .font(.caption)
                .foregroundColor(.piggyPrimary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview Helpers

extension ChartDataPoint {
    static var sampleData: [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: i - 6, to: now) ?? now
            return ChartDataPoint(
                date: date,
                value: Double.random(in: 20...100),
                label: "Day \\(i + 1)"
            )
        }
    }
    
    static var sampleCategoryData: [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date(), value: 45, label: "Concert Tickets"),
            ChartDataPoint(date: Date(), value: 25, label: "Albums"),
            ChartDataPoint(date: Date(), value: 20, label: "Merchandise"),
            ChartDataPoint(date: Date(), value: 10, label: "Digital Content")
        ]
    }
    
    static var sampleGoalsData: [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date(), value: 84, label: "BTS Concert"),
            ChartDataPoint(date: Date(), value: 57, label: "BLACKPINK Merch"),
            ChartDataPoint(date: Date(), value: 92, label: "Album Collection"),
            ChartDataPoint(date: Date(), value: 34, label: "Fan Meeting")
        ]
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            InteractiveLineChart(
                data: ChartDataPoint.sampleData,
                title: "Spending Trend",
                color: .blue,
                timeRange: .week
            )
            
            InteractiveDonutChart(
                data: ChartDataPoint.sampleCategoryData,
                title: "Category Breakdown",
                total: 100
            )
            
            InteractiveBarChart(
                data: ChartDataPoint.sampleGoalsData,
                title: "Goal Progress",
                color: .purple
            )
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}