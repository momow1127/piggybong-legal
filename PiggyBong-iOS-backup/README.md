# PiggyBong iOS App

A clean, MVP-focused K-pop fan spending tracker built with SwiftUI and Supabase.

## 🎯 MVP Features

- **Simple Onboarding** - Quick 3-step setup process
- **Fast Purchase Logging** - One-tap adding with preset amounts
- **Budget Tracking** - Visual monthly progress with cute piggy themes
- **Artist Allocation** - Per-artist spending breakdown
- **Clean Dashboard** - Budget vs. spent overview

## 🏗️ Architecture

```
Sources/
├── App/                    # App entry point
│   └── PiggyBongApp.swift
├── Core/                   # Shared components
│   ├── Models/            # Data models (User, Artist, Purchase, Budget)
│   ├── Services/          # Business logic (Auth, Database, Budget)
│   └── Extensions/        # Utility extensions
├── Features/              # Feature modules
│   ├── Onboarding/       # User onboarding flow
│   ├── Dashboard/        # Main dashboard & profile
│   ├── Purchases/        # Purchase tracking
│   └── Budget/           # Budget management
└── Resources/            # Design tokens & assets
    └── DesignTokens.swift
```

## 🎨 Design Principles

- **K-pop Focused** - Artist-centric organization and cute piggy theming
- **MVP Only** - Simple, essential features without over-engineering
- **Fast Logging** - < 3 taps to add any purchase
- **Visual Feedback** - Progress bars and status indicators

## 🚀 Getting Started

### Prerequisites

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd PiggyBong-iOS
   ```

2. **Install dependencies**
   ```bash
   swift package resolve
   ```

3. **Set up Supabase**
   - Create a new Supabase project
   - Run the `database_schema.sql` file in your Supabase SQL editor
   - Update `SupabaseService.swift` with your project URL and anon key

4. **Build and run**
   - Open the project in Xcode
   - Select your target device/simulator
   - Build and run (⌘+R)

## 📊 Database Schema

The app uses Supabase with the following main tables:

- **users** - User profiles and settings
- **artists** - K-pop artists and groups
- **purchases** - Individual spending records
- **budgets** - Monthly budget tracking
- **artist_budget_allocations** - Per-artist spending limits

See `database_schema.sql` for the complete setup.

## 🎯 Core Models

### User
```swift
struct User {
    let id: UUID
    let email: String
    let name: String
    var monthlyBudget: Double
    var currency: String
}
```

### Purchase
```swift
struct Purchase {
    let id: UUID
    let userId: UUID
    let artistId: UUID
    let amount: Double
    let category: PurchaseCategory // album, concert, merch, etc.
    let description: String
    let purchaseDate: Date
}
```

### Budget
```swift
struct Budget {
    let id: UUID
    let userId: UUID
    let month: Int
    let year: Int
    let totalBudget: Double
    var spent: Double
    
    var progress: Double // spent / totalBudget
    var remaining: Double // totalBudget - spent
    var isOverBudget: Bool // spent > totalBudget
}
```

## 🎨 Design Tokens

The app uses a consistent design system defined in `DesignTokens.swift`:

- **Colors** - Piggy pink primary, purple secondary, budget status colors
- **Typography** - Rounded fonts for headings, system fonts for body
- **Spacing** - 8pt grid system (xs: 4pt, sm: 8pt, md: 16pt, etc.)
- **Components** - Reusable card and button styles

## 🔄 Data Flow

1. **Authentication** - Supabase Auth with email/password
2. **Real-time Sync** - Purchases and budgets sync automatically
3. **Local State** - ObservableObject services manage UI state
4. **Budget Updates** - Automatic calculation of spent amounts

## 📱 Key Views

### OnboardingView
- Welcome screen with piggy mascot
- Account creation form
- Budget setup with preset amounts

### DashboardView
- Monthly budget progress (circular chart)
- Quick add purchase button
- Recent purchases list
- Top artists this month

### QuickAddPurchaseView
- Artist picker with search
- Category selection (visual icons)
- Preset amount buttons per category
- One-tap purchase logging

### BudgetView
- Monthly budget overview
- Spending by category breakdown
- Artist allocation management
- Budget vs. spent analytics

## 🎯 MVP Constraints

This is an MVP build focused on core functionality:

- **No complex charts** - Simple progress bars and percentages
- **No social features** - Personal tracking only
- **No cloud sync** - Supabase handles data persistence
- **No offline mode** - Online-first architecture
- **No complex budgeting** - Monthly budgets only

## 🔧 Development Notes

### Mock Data
The app includes mock data for development:
- Pre-populated artists (BTS, BLACKPINK, NewJeans, etc.)
- Sample purchases and budgets
- Placeholder authentication flow

### Error Handling
- Simple error messages in UI
- Graceful fallbacks for network issues
- Form validation for user inputs

### Performance
- Lazy loading for lists
- Efficient SwiftUI state management
- Minimal database queries

## 🚀 Next Steps (Post-MVP)

Potential enhancements after MVP launch:

- **Push Notifications** - Budget alerts and artist news
- **Data Export** - CSV export of spending data
- **Advanced Analytics** - Spending trends and insights
- **Artist News Integration** - Latest updates and releases
- **Social Features** - Share spending goals with friends
- **Widget Support** - Budget progress on home screen

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

This is an MVP project. Focus on:
- Bug fixes and stability
- UI/UX improvements
- Performance optimizations
- Documentation updates

Keep it simple and focused on the core K-pop spending tracking experience!