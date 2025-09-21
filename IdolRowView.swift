import SwiftUI

struct IdolRowView: View {
    let idols: [IdolModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Title
            Text("Your Idols")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            // Horizontal Scrolling Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Leading padding to prevent cut-off
                    Color.clear
                        .frame(width: 0)
                    
                    // Idol circles
                    ForEach(idols, id: \.id) { idol in
                        IdolCircleView(idol: idol, isInteractive: false)
                    }
                    
                    // Add Idol button - matching size with other circles
                    AddIdolButtonView()
                    
                    // Trailing padding
                    Color.clear
                        .frame(width: 0)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct IdolCircleView: View {
    let idol: IdolModel
    let isInteractive: Bool
    
    private let circleSize: CGFloat = 64
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile image container
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: circleSize, height: circleSize)
                
                // Profile image
                AsyncImage(url: URL(string: idol.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(width: circleSize, height: circleSize)
                .clipShape(Circle())
                
                // Remove any interactive indicators for MVP
                // No glowing rings, borders, or highlights
            }
            
            // Idol name
            Text(idol.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: circleSize)
        }
        // Remove any tap gestures or interactive states for MVP
    }
}

struct AddIdolButtonView: View {
    private let circleSize: CGFloat = 64
    
    var body: some View {
        VStack(spacing: 8) {
            // Button circle - matching size with idol circles
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: circleSize, height: circleSize)
                
                // Plus icon
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            // Button label
            Text("Add Idol")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .lineLimit(1)
                .frame(width: circleSize)
        }
        // Remove any tap functionality for MVP
    }
}

// MARK: - Supporting Models
struct IdolModel {
    let id: String
    let name: String
    let profileImageURL: String
}

// MARK: - Preview
struct IdolRowView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleIdols = [
            IdolModel(id: "1", name: "Yuna", profileImageURL: "https://example.com/yuna.jpg"),
            IdolModel(id: "2", name: "Karina", profileImageURL: "https://example.com/karina.jpg"),
            IdolModel(id: "3", name: "Winter", profileImageURL: "https://example.com/winter.jpg"),
            IdolModel(id: "4", name: "Ningning", profileImageURL: "https://example.com/ningning.jpg")
        ]
        
        IdolRowView(idols: sampleIdols)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}