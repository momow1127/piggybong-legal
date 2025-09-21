# FanPlan Utils Inventory

## 🎯 **Available Utilities**

> **Rule: Always check this list before creating new utilities!**

### 🔊 HapticManager
**File:** `Utils/HapticManager.swift`

```swift
HapticManager.light()    // Light tap feedback
HapticManager.medium()   // Medium tap feedback  
HapticManager.heavy()    // Heavy tap feedback
HapticManager.success()  // Success notification
HapticManager.error()    // Error notification
```

### 💰 Currency Formatting
**File:** `Utils/CurrencyFormatter.swift`

```swift
formatCurrency(150.5) // Returns "150"
formatCurrency(1000)  // Returns "1000"
```

### 🎨 Button Styles  
**File:** `Utils/ButtonStyles.swift`

```swift
.buttonStyle(ScaleButtonStyle()) // Press animation effect
```

---

## 📋 **Before Adding New Utilities**

1. **Search first:** `Cmd+Shift+F` in Xcode
2. **Check this file** - is it already listed?
3. **Ask team:** "Do we have X utility already?"

## ➕ **Adding New Utilities**

1. Create in appropriate `Utils/` subfolder
2. **Update this README** with usage examples
3. Make it **generic and reusable**
4. Add **documentation comments**

## 🚨 **Common Duplicates to Avoid**

- ❌ Multiple `HapticManager` structs
- ❌ Multiple currency formatting functions
- ❌ Duplicate button styles
- ❌ Multiple date formatters
- ❌ Duplicate color extensions

---

**Last Updated:** $(date +%Y-%m-%d)
**Maintainer:** Development Team