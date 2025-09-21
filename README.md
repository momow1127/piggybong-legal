# Piggy Bong - K-pop Fan Planning App 🎤💰

Last Updated: January 2025
<img width="120" height="120" alt="120" src="https://github.com/user-attachments/assets/ba1b116a-b7fb-425f-8459-ebddf98ec53a" />

> Your ultimate K-pop companion for smart budget planning and priority management

Piggy Bong is an iOS app designed specifically for K-pop fans to help them plan, budget, and prioritize their fan activities intelligently. Whether you're saving for concert tickets, collecting albums, or planning a trip to Korea, Piggy Bong helps you achieve your K-pop dreams within your budget.

## 📄 Legal Documents

This repository also contains the Privacy Policy and Terms of Service for PiggyBong - K-pop Fan Spending Tracker. See the website files for the complete legal documentation.

## 🌟 Features

### 📱 Smart Onboarding
- **Interactive Setup**: Choose your favorite K-pop groups and set your priorities
- **Fan Activity Prioritization**: Drag-and-drop interface to rank how you usually spend — concerts, albums, merch, subscriptions, and more
- **Monthly Fan Spending Estimate**: Tell us how much you typically spend on K-pop each month
- **AI-Powered Recommendations**: Get personalized budget breakdowns based on your preferences

### 🎯 Priority Management
- **Dynamic Priority Lists**: Manage and reorder your K-pop goals in real-time
- **Smart Allocation**: Intelligent budget distribution across your priorities
- **Flexible Planning**: Mark priorities as flexible or fixed based on your needs
- **Progress Tracking**: Monitor your progress toward each goal

### 📊 Progressive Dashboard
- **Personalized Experience**: Dashboard adapts based on your journey stage
- **Real-time Updates**: Stay informed about opportunities and progress
- **Budget Insights**: Visual breakdown of your spending allocations
- **Goal Timeline**: Track when you'll achieve your dreams

### 🎪 Events & Updates
- **Concert Tracking**: Keep track of upcoming concerts and events
- **News Feed**: Stay updated with your favorite groups' latest news
- **Notifications**: Get alerted about important updates and opportunities

### 👤 Profile & Settings
- **Customizable Profile**: Personalize your fan experience
- **Budget Management**: Adjust your spending limits and preferences
- **Data Sync**: Seamless synchronization across devices

## 🛠 Technical Stack

- **Framework**: SwiftUI for modern iOS development
- **Backend**: Supabase for real-time data synchronization
- **Database**: PostgreSQL with custom schema for fan data
- **Authentication**: Secure user authentication and data protection
- **Architecture**: MVVM pattern with ObservableObject for state management

## 📋 Requirements

- iOS 18.4 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Active internet connection for data synchronization

## 🚀 Getting Started

### Prerequisites
1. Xcode installed on your Mac
2. iOS Simulator or physical iOS device
3. Supabase account (for backend services)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/momow1127/piggybong-legal.git
   cd piggybong-legal
   ```

2. **Open in Xcode**
   ```bash
   open FanPlan.xcodeproj
   ```

3. **Configure Supabase**
   - Update `Config.swift` with your Supabase credentials
   - Replace `url` and `anonKey` with your project values

4. **Install Dependencies**
   - Dependencies are managed via Swift Package Manager
   - Xcode will automatically resolve packages on first build

5. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run the app

## 🎨 Design System

### Consistent UI Padding
The app features a unified design system with:
- **Standard Horizontal Padding**: 16pt across all screens
- **Responsive Layouts**: Adapts to different screen sizes
- **Custom Modifiers**: Reusable UI components for consistency

### Color Scheme
- **Primary Gradient**: Purple to pink gradient for key elements
- **Dark Theme**: Optimized for comfortable viewing
- **Accent Colors**: Carefully chosen colors for different priority types

## 📁 Project Structure

```
FanPlan/
├── Views/
│   ├── OnboardingView.swift     # Multi-step onboarding flow
│   ├── DashboardView.swift      # Main dashboard interface
│   ├── PrioritiesView.swift     # Priority management
│   ├── EventsView.swift         # Events and updates
│   └── ProfileView.swift        # User profile and settings
├── Models/
│   ├── DatabaseModels.swift     # Core data models
│   ├── PriorityModels.swift     # Priority-specific models
│   └── EventModels.swift        # Event-related models
├── Services/
│   ├── SupabaseClient.swift     # Backend integration
│   ├── SmartAllocationService.swift # Budget allocation logic
│   └── AuthManager.swift        # Authentication handling
├── Components/
│   ├── DashboardComponents.swift # Reusable UI components
│   └── Config.swift             # App configuration and constants
└── Assets/
    └── Assets.xcassets/         # App icons and images
```

## 🔧 Configuration

### Environment Variables
The app supports environment-based configuration:

```swift
// Config.swift
static var supabaseURL: String {
    if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
        return envURL
    }
    return "your-default-url"
}
```

### Database Schema
The app uses a custom PostgreSQL schema designed for K-pop fan data:
- User profiles and preferences
- Priority and goal tracking
- Event and concert information
- Budget and spending analytics

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) for modern iOS development
- Backend powered by [Supabase](https://supabase.com/) for real-time data
- UI/UX designed with K-pop fans in mind
- Special thanks to the K-pop community for inspiration

## 📞 Support

If you have any questions or need support, please:
- Open an issue on GitHub
- Contact the development team
- Check the [documentation](docs/) for detailed guides

---

**Made with 💜 for the K-pop community**

*Piggy Bong - Plan smart. Love hard. Stay joyful.*
