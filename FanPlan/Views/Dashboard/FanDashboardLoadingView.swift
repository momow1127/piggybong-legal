import SwiftUI

struct FanDashboardLoadingView: View {
    var body: some View {
        VStack(spacing: PiggySpacing.xl) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 24)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 16)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }
            .padding(.horizontal, PiggySpacing.lg)
            
            // Quick stats skeleton
            VStack(spacing: PiggySpacing.md) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 20)
                        .cornerRadius(4)
                    Spacer()
                }
                
                HStack(spacing: PiggySpacing.md) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(spacing: PiggySpacing.sm) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 18)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 14)
                                .cornerRadius(4)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, PiggySpacing.lg)
            
            // Goals section skeleton
            VStack(spacing: PiggySpacing.md) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 20)
                        .cornerRadius(4)
                    Spacer()
                }
                
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: PiggySpacing.xs) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 16)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 14)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 16)
                            .cornerRadius(4)
                    }
                    .padding(PiggySpacing.md)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(PiggyBorderRadius.md)
                }
            }
            .padding(.horizontal, PiggySpacing.lg)
            
            // Artists section skeleton
            VStack(spacing: PiggySpacing.md) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 20)
                        .cornerRadius(4)
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PiggySpacing.md) {
                        ForEach(0..<5, id: \.self) { _ in
                            VStack(spacing: PiggySpacing.sm) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 14)
                                    .cornerRadius(4)
                            }
                            .padding(PiggySpacing.md)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(PiggyBorderRadius.md)
                        }
                    }
                    .padding(.horizontal, PiggySpacing.lg)
                }
            }
            
            Spacer()
        }
        .background(PiggyGradients.background)
    }
}

#Preview {
    FanDashboardLoadingView()
}