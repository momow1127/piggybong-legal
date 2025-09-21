import SwiftUI

// MARK: - Optimized Idol Row for MVP
struct OptimizedIdolRowView: View {
    let idols: [IdolModel]
    
    // Consistent sizing and spacing
    private let idolSize: CGFloat = 64
    private let horizontalSpacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            sectionHeader
            
            // Horizontal scrollable row
            idolScrollView
        }
    }
    
    private var sectionHeader: some View {
        Text("Your Idols")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.horizontal, horizontalPadding)
    }
    
    private var idolScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: horizontalSpacing) {
                // Idol circles
                ForEach(idols, id: \.id) { idol in
                    NonInteractiveIdolCircle(
                        idol: idol,
                        size: idolSize
                    )
                }
                
                // Add Idol button - exactly matching idol circle size
                EnlargedAddIdolButton(size: idolSize)
            }
            .padding(.horizontal, horizontalPadding) // Proper padding to prevent cut-off
        }
    }
}

// MARK: - Non-Interactive Idol Circle (MVP)
struct NonInteractiveIdolCircle: View {
    let idol: IdolModel
    let size: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile image - NO interactive indicators
            ZStack {
                // Simple background circle
                Circle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: size, height: size)
                
                // Profile image
                AsyncImage(url: URL(string: idol.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.gray)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                
                // REMOVED: No glowing rings, borders, highlights, or any interactive indicators
            }
            
            // Name label
            Text(idol.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: size)
        }
        // REMOVED: No tap gestures or interactive states
    }
}

// MARK: - Enlarged Add Idol Button (MVP)
struct EnlargedAddIdolButton: View {
    let size: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            // Button circle - exactly matching idol circle dimensions
            ZStack {
                // Background circle with subtle styling
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: size, height: size)
                
                // Border for definition
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    .frame(width: size, height: size)
                
                // Plus icon - properly sized
                Image(systemName: "plus")
                    .font(.system(size: size * 0.3, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Button label
            Text("Add Idol")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .lineLimit(1)
                .frame(width: size)
        }
        // REMOVED: No tap functionality for MVP
    }
}

// MARK: - Usage Examples and Integration

// Example of how to integrate into your main view
struct MainContentView: View {
    @State private var userIdols: [IdolModel] = [
        IdolModel(id: "1", name: "Yuna", profileImageURL: ""),
        IdolModel(id: "2", name: "Karina", profileImageURL: ""),
        IdolModel(id: "3", name: "Winter", profileImageURL: ""),
        IdolModel(id: "4", name: "Ningning", profileImageURL: "")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Your existing content above...
                
                // Optimized Idol Row
                OptimizedIdolRowView(idols: userIdols)
                
                // Your existing content below...
            }
        }
    }
}

// MARK: - Key MVP Changes Summary
/*
 MVP POLISH CHANGES IMPLEMENTED:
 
 1. ✅ REMOVED INTERACTIVITY INDICATORS:
    - No glowing rings around idol circles
    - No borders suggesting tappability  
    - No highlight states or hover effects
    - No tap gestures or interactive states
 
 2. ✅ FIXED LEFT MARGIN:
    - Added proper horizontal padding (.padding(.horizontal, 16))
    - First idol circle is fully visible
    - Consistent padding on both sides
 
 3. ✅ ENLARGED "+ Idol" BUTTON:
    - Button now exactly matches idol circle size (64pt)
    - Consistent dimensions across all circles
    - Proper icon scaling within the circle
 
 4. ✅ CONSISTENT SPACING:
    - Uniform 16pt spacing between all circles
    - Consistent vertical spacing for labels
    - Aligned circle sizes and spacing throughout
 
 VISUAL CONSISTENCY ACHIEVED:
 - All circles are exactly 64pt diameter
 - Uniform 16pt horizontal spacing
 - Consistent typography and colors
 - Clean, non-interactive appearance suitable for MVP
*/

// MARK: - Preview
struct OptimizedIdolRowView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleIdols = [
            IdolModel(id: "1", name: "Yuna", profileImageURL: ""),
            IdolModel(id: "2", name: "Karina", profileImageURL: ""),
            IdolModel(id: "3", name: "Winter", profileImageURL: ""),
            IdolModel(id: "4", name: "Ningning", profileImageURL: ""),
            IdolModel(id: "5", name: "Giselle", profileImageURL: "")
        ]
        
        Group {
            // Light mode
            OptimizedIdolRowView(idols: sampleIdols)
                .padding()
                .previewDisplayName("Light Mode")
            
            // Dark mode
            OptimizedIdolRowView(idols: sampleIdols)
                .padding()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // With fewer idols
            OptimizedIdolRowView(idols: Array(sampleIdols.prefix(2)))
                .padding()
                .previewDisplayName("Few Idols")
        }
        .previewLayout(.sizeThatFits)
    }
}