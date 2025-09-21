# PiggyBong iOS Setup Guide

## 📱 Creating the Xcode Project

Since this is a Swift Package structure, you'll need to create an Xcode project to run the app. Here's how:

### Option 1: Create New iOS App Project

1. **Open Xcode** and create a new project
2. **Select "iOS" → "App"**
3. **Configure your project:**
   - Product Name: `PiggyBong`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum iOS Version: `17.0`

4. **Replace the generated files** with the files from this package:
   - Delete the default `ContentView.swift` and `PiggyBongApp.swift`
   - Add all files from the `Sources/` directory to your Xcode project
   - Maintain the folder structure in Xcode for organization

5. **Add Supabase dependency:**
   - In Xcode: File → Add Package Dependencies
   - URL: `https://github.com/supabase/supabase-swift.git`
   - Version: `2.0.0` or latest

### Option 2: Use Swift Package Manager (Recommended for Development)

1. **Open Package.swift in Xcode**
   ```bash
   cd PiggyBong-iOS
   open Package.swift
   ```

2. **Create an executable target** by modifying Package.swift:
   ```swift
   .executableTarget(
       name: "PiggyBongApp",
       dependencies: ["PiggyBong"],
       path: "App"
   )
   ```

3. **Create App directory** and add a main.swift file

## 🗄️ Database Setup

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note your Project URL and anon key

### 2. Set Up Database
1. Go to SQL Editor in your Supabase dashboard
2. Copy and paste the contents of `database_schema.sql`
3. Run the script to create all tables and functions

### 3. Configure App
1. Open `Sources/Core/Services/Config.swift`
2. Replace placeholder values:
   ```swift
   static let url = "https://your-actual-project-id.supabase.co"
   static let anonKey = "your-actual-anon-key"
   ```

## 🎨 Assets Setup

Create these color assets in your Xcode project:

### Colors (Assets.xcassets)
- **PiggyPrimary**: `#FF9EC7` (Light pink)
- **PiggySecondary**: `#C7AEFF` (Light purple)  
- **PiggyAccent**: `#FFD700` (Gold)
- **BudgetGreen**: `#4CAF50`
- **BudgetOrange**: `#FF9800`
- **BudgetRed**: `#F44336`
- **PiggyBackground**: `#FAFAFA` (Light mode), `#1C1C1E` (Dark mode)
- **PiggySurface**: `#FFFFFF` (Light mode), `#2C2C2E` (Dark mode)
- **PiggyTextPrimary**: `#000000` (Light mode), `#FFFFFF` (Dark mode)
- **PiggyTextSecondary**: `#666666` (Light mode), `#EBEBF5` (Dark mode)

### App Icon
Create app icon assets or use a piggy bank placeholder icon.

## 🔧 Build Configuration

### Info.plist Settings
Add these keys to your Info.plist:

```xml
<key>CFBundleDisplayName</key>
<string>PiggyBong</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>LSRequiresIPhoneOS</key>
<true/>
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

### Deployment Target
- Minimum iOS version: 17.0
- Xcode version: 15.0+
- Swift version: 5.9+

## 🚀 Running the App

1. **Select your target device** (iPhone 15 Pro recommended for testing)
2. **Build and run** (⌘+R)
3. **Test the onboarding flow:**
   - Create an account
   - Set up monthly budget
   - Add some test purchases
   - View budget progress

## 🧪 Testing Features

### Onboarding
- [ ] Welcome screen displays
- [ ] Account creation works
- [ ] Budget setup saves correctly

### Dashboard  
- [ ] Budget progress shows correctly
- [ ] Recent purchases display
- [ ] Quick add button works

### Purchases
- [ ] Artist picker shows sample artists
- [ ] Category selection works
- [ ] Preset amounts function correctly
- [ ] Purchase saves to database

### Budget
- [ ] Monthly overview displays
- [ ] Spending by category works
- [ ] Budget editing functions

## 🐛 Troubleshooting

### Common Issues

**Build Errors:**
- Ensure iOS deployment target is 17.0+
- Check that Supabase package is properly added
- Verify all Swift files are included in target

**Runtime Errors:**
- Check Supabase configuration in Config.swift
- Ensure database schema is properly set up
- Verify network connectivity

**UI Issues:**
- Create color assets or use fallback colors
- Check that design tokens are properly imported
- Ensure proper iOS version for SwiftUI features

### Debug Mode
The app includes debug logging. Check Xcode console for:
```
🐷 PiggyBong Configuration:
   Environment: development
   App Version: 1.0.0 (1)
   ...
```

## 📝 Development Notes

### MVP Scope
This is an MVP build. Focus on:
- Core spending tracking functionality
- Simple, clean UI
- Reliable data persistence
- Basic budget management

### Code Organization
- Keep features modular and focused
- Use the established design tokens
- Follow SwiftUI best practices
- Maintain clean separation of concerns

### Performance
- Use lazy loading for large lists
- Minimize database queries
- Optimize for iPhone performance
- Test on actual devices when possible

## 🔄 Next Steps

Once the app is running:
1. Test all MVP features thoroughly
2. Add proper error handling
3. Implement data validation
4. Add loading states
5. Polish UI animations
6. Prepare for TestFlight distribution

## 💡 Tips

- Use iOS Simulator for quick testing
- Test on actual device for performance
- Use Xcode previews for UI development
- Check Supabase dashboard for data verification
- Keep the MVP scope focused and simple

Happy coding! 🐷✨