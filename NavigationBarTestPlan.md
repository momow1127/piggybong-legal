# Navigation Bar Gradient Testing Plan

## Device Testing
- [ ] iPhone SE (3rd gen) - Smallest screen
- [ ] iPhone 14/15 - Standard size
- [ ] iPhone 14/15 Pro Max - Largest screen
- [ ] iPad (if supported) - Tablet layout

## iOS Version Testing
- [ ] iOS 16.0+ - Minimum supported
- [ ] iOS 17.x - Current major
- [ ] iOS 18.x - Latest version

## Navigation Patterns
- [ ] **Modal Sheets** (.sheet)
  - [ ] Title shows correctly
  - [ ] Done button is white
  - [ ] Gradient background visible
  
- [ ] **Full Screen Covers** (.fullScreenCover)
  - [ ] Same as sheets
  - [ ] Dismiss functionality works
  
- [ ] **Pushed Views** (NavigationLink)
  - [ ] Back button is white
  - [ ] Large title transitions smoothly
  - [ ] Gradient persists during transition
  
- [ ] **Tab Bar Navigation**
  - [ ] Consistent across all tabs
  - [ ] Tab switching preserves styling

## Content Scenarios
- [ ] **Empty/Short Content**
  - [ ] Navigation bar appears correctly
  - [ ] No transparency effects
  
- [ ] **Long Scrollable Content**
  - [ ] Scroll edge appearance matches standard
  - [ ] No color changes during scroll
  - [ ] Large title collapse/expand works
  
- [ ] **Keyboard Interactions**
  - [ ] Navigation bar visible when keyboard is up
  - [ ] Styling preserved during keyboard animations

## Edge Cases
- [ ] **App Launch**
  - [ ] First view shows gradient correctly
  - [ ] Status bar is light from start
  
- [ ] **Memory Warnings**
  - [ ] Gradient images don't get purged
  - [ ] Styling persists after memory pressure
  
- [ ] **Orientation Changes**
  - [ ] Gradient scales correctly
  - [ ] Text remains readable
  
- [ ] **Accessibility**
  - [ ] VoiceOver reads titles correctly
  - [ ] High contrast mode compatibility
  - [ ] Dynamic Type scaling works

## Views to Test
- [ ] NotificationSettingsView
- [ ] QuickAddPurchaseView  
- [ ] IdolNewsFeedView
- [ ] ArtistManagementView
- [ ] ProfileSettingsView
- [ ] DashboardView (HomeView)
- [ ] Any other NavigationView screens

## Visual Verification
- [ ] Gradient direction (leading to trailing)
- [ ] Color accuracy (#5D2CEE → #8B55ED)
- [ ] White text at 100% opacity
- [ ] No separator lines visible
- [ ] Status bar is light content

## Performance Testing
- [ ] Smooth navigation transitions
- [ ] No frame drops during navigation
- [ ] Memory usage remains stable
- [ ] Battery impact negligible