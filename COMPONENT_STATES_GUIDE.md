# PiggyBong Component States Guide 🎨

## 📋 Complete Component Library

### 🔘 Button States

#### **PiggyButton**
All button styles support these states:

| State | Visual Treatment |
|-------|-----------------|
| **Default** | Normal appearance |
| **Hover** | Not applicable on iOS |
| **Pressed** | Scale 97%, Opacity 80% |
| **Loading** | Shows spinner, disabled interaction |
| **Disabled** | Opacity 60%, no interaction |

```swift
// Primary Button (Purple gradient)
PiggyButton(title: "Save for concert", action: {}, style: .primary)

// Secondary Button (Outlined)
PiggyButton.secondary("Maybe later", action: {})

// Tertiary Button (Text only)
PiggyButton.tertiary("Skip", action: {})

// Destructive Button (Red)
PiggyButton.destructive("Delete goal", action: {})

// Button with states
PiggyButton(
    title: "Processing...",
    action: {},
    isLoading: true,  // Shows spinner
    isDisabled: false
)
```

---

### 📝 Text Field States

#### **PiggyTextField**

| State | Border Color | Background | Helper Text |
|-------|-------------|------------|-------------|
| **Default** | Gray 30% | Card bg | Optional helper |
| **Active/Focus** | Gold | Card bg | Helper visible |
| **Success** | Green | Card bg | Success message |
| **Error** | Red | Card bg | Error message |
| **Disabled** | Gray 10% | Card bg 50% | Grayed out |

```swift
// Default state
PiggyTextField(
    label: "Monthly budget",
    placeholder: "Enter amount",
    text: $budget,
    icon: "dollarsign.circle",
    state: .default,
    helperText: "Minimum $50"
)

// Success state with checkmark
PiggyTextField(
    label: "Email",
    placeholder: "fan@example.com",
    text: $email,
    state: .success,
    helperText: "Email verified!"
)

// Error state with message
PiggyTextField(
    label: "Username",
    placeholder: "Choose username",
    text: $username,
    state: .error("Username already taken")
)

// Disabled state
PiggyTextField(
    label: "Locked field",
    placeholder: "",
    text: .constant("Cannot edit"),
    state: .disabled
)

// With character limit
PiggyTextField(
    label: "Bio",
    placeholder: "Tell us about yourself",
    text: $bio,
    maxLength: 100  // Shows 75/100 counter
)
```

---

### 🎯 Toggle & Checkbox States

#### **PiggyToggle**

| State | Visual |
|-------|--------|
| **Off** | Gray background |
| **On** | Gold background |
| **Disabled** | Reduced opacity |

```swift
PiggyToggle(
    label: "Concert notifications",
    isOn: $notificationsEnabled,
    description: "Get alerts for presales"
)
```

#### **PiggyCheckbox**

| State | Visual |
|-------|--------|
| **Unchecked** | Empty border |
| **Checked** | Gold fill with checkmark |
| **Disabled** | Reduced opacity |

```swift
PiggyCheckbox(
    label: "Remember my choice",
    isChecked: $rememberChoice
)
```

#### **PiggyRadioButton**

```swift
PiggyRadioButton(
    label: "Weekly",
    value: "weekly",
    selectedValue: $frequency
)
```

---

### 🃏 Card States

#### **PiggyCard**

| Style | Shadow | Border | Background |
|-------|--------|--------|------------|
| **Flat** | None | None | Card bg |
| **Elevated** | 8px | None | Card bg 80% |
| **Outlined** | None | Gray 30% | Card bg |

```swift
// Elevated card (default)
PiggyCard {
    Text("Content here")
}

// Outlined card
PiggyCard(style: .outlined) {
    Text("Content here")
}

// Custom padding
PiggyCard(padding: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) {
    Text("Compact content")
}
```

#### **PiggyFeatureCard**

| State | Visual |
|-------|--------|
| **Default** | Normal size |
| **Pressed** | Scale 95%, Opacity 90% |
| **Selected** | Scale 105%, Outlined border |

```swift
PiggyFeatureCard(
    icon: "star.fill",
    title: "VIP Benefits",
    description: "Exclusive perks for fans",
    accentColor: .piggyAccent,
    isSelected: true
)
```

---

### 📊 Notification Cards

#### **PiggyNotificationCard**

Different types with specific colors and priorities:

```swift
// AI Tip (Gold accent)
PiggyNotificationCard(
    type: .aiTip,
    title: "Smart tip",
    subtitle: "Group orders save 30% on shipping",
    actionLabel: "Learn how"
)

// Comeback Alert (Orange accent, High priority)
PiggyNotificationCard(
    type: .comeback,
    title: "SEVENTEEN comeback!",
    subtitle: "New album Dec 15 - you have $80 saved",
    actionLabel: "Start saving",
    isNew: true
)

// Savings Success (Green accent)
PiggyNotificationCard(
    type: .savings,
    title: "Goal reached!",
    subtitle: "Concert fund hit $500",
    actionLabel: "Celebrate"
)
```

---

### 📉 Data Visualization

#### **PiggyProgressBar**

```swift
PiggyProgressBar(
    value: 0.75,  // 75%
    label: "Concert savings",
    color: .piggyAccent,
    showPercentage: true
)
```

#### **PiggyStatsCard**

```swift
PiggyStatsCard(
    icon: "dollarsign.circle.fill",
    title: "Monthly Budget",
    value: "$300",
    subtitle: "Remaining this month",
    trend: .up("12%")  // Shows green arrow up
)

// Trend options:
// .up("12%")    - Green arrow up
// .down("5%")   - Red arrow down  
// .neutral("0%") - Gray dash
```

---

### 🎨 Dropdown States

#### **PiggyDropdown**

| State | Visual |
|-------|--------|
| **Collapsed** | Shows selected value or placeholder |
| **Expanded** | Shows all options with animation |
| **Selected Option** | Shows checkmark |

```swift
PiggyDropdown(
    title: "Select artist",
    options: artists,
    selectedOption: $selectedArtist,
    placeholder: "Choose your bias"
)
```

---

## 🎯 Interactive States Summary

### Press States
- **Buttons**: Scale 97%, Opacity 80%
- **Cards**: Scale 95%, Opacity 90%
- **Links**: Opacity 70%

### Disabled States
- **All components**: Opacity 60%, no interaction

### Loading States
- **Buttons**: Show spinner, disable interaction
- **Cards**: Can show skeleton loader

### Focus States (Text Fields)
- **Border**: 2px gold border
- **Background**: Same
- **Animation**: Quick transition

---

## 💫 Animation Timings

```swift
PiggyAnimation.quick    // 0.2s - Press states, toggles
PiggyAnimation.standard // 0.3s - Transitions, dropdowns
PiggyAnimation.bounce   // 0.6s - Cards, celebrations
```

---

## 🌈 Color Usage by State

| State | Color | Usage |
|-------|-------|-------|
| **Active/Focus** | Gold (#FFD700) | Borders, selections |
| **Success** | Green | Checkmarks, positive states |
| **Error** | Red | Errors, warnings |
| **Disabled** | Gray 10% | Inactive elements |
| **Default** | Gray 30% | Normal borders |

---

## 📱 Accessibility Notes

- All interactive elements have minimum 44x44pt touch targets
- Disabled states maintain readable contrast
- Loading states announce to screen readers
- Error messages are associated with inputs

---

## 🚀 Quick Copy-Paste Examples

### Complete Form Example
```swift
VStack(spacing: PiggySpacing.lg) {
    PiggyTextField(
        label: "Username",
        placeholder: "Enter username",
        text: $username,
        icon: "person.fill"
    )
    
    PiggyTextField(
        label: "Budget",
        placeholder: "Monthly amount",
        text: $budget,
        icon: "dollarsign.circle",
        keyboardType: .numberPad
    )
    
    PiggyToggle(
        label: "Enable notifications",
        isOn: $notificationsOn
    )
    
    PiggyButton(
        title: "Save Settings",
        action: saveSettings,
        style: .primary,
        isLoading: isSaving
    )
}
```

### Dashboard Card Example
```swift
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
    PiggyStatsCard(
        icon: "dollarsign.circle.fill",
        title: "Budget",
        value: "$300",
        trend: .up("12%")
    )
    
    PiggyStatsCard(
        icon: "star.fill",
        title: "Goals",
        value: "3/5",
        trend: .neutral("On track")
    )
}
```

---

*Use these components consistently across all screens for a cohesive PiggyBong experience!* 💜