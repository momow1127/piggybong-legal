# FanPlan Development Guidelines

## 🎯 **Duplicate Prevention Strategy**

### **The Golden Rule**
> **"If you're writing it for the second time, make it shared."**

---

## 📁 **Project Structure**

```
FanPlan/
├── Utils/              # 🔧 Shared utilities (ALWAYS CHECK HERE FIRST!)
│   ├── README.md       # 📋 Inventory of available utilities
│   ├── HapticManager.swift
│   ├── CurrencyFormatter.swift
│   └── ButtonStyles.swift
├── Extensions/         # 🔌 Type extensions
├── Constants/          # 📊 App constants 
├── Components/         # 🧩 Reusable UI components
└── Views/             # 📱 App screens
```

---

## ✅ **Before Writing ANY New Code**

### **1. Search First! (Cmd+Shift+F)**
```
Search for: "formatCurrency", "HapticManager", "ButtonStyle"
```

### **2. Check Utils Inventory**
- Read `FanPlan/Utils/README.md`
- See what's already available

### **3. Ask Yourself:**
- "Does this utility already exist?"
- "Could this be generic and reusable?"
- "Will other views need this too?"

---

## 🔨 **Creating New Utilities**

### **DO:**
```swift
// ✅ Generic and reusable
func formatCurrency(_ amount: Double) -> String {
    // Implementation
}

// ✅ Proper location: Utils/CurrencyFormatter.swift
// ✅ Update Utils/README.md with example
```

### **DON'T:**
```swift
// ❌ Don't create inline utilities
struct MyView: View {
    private func formatMoney(_ amount: Double) -> String {
        // This will be duplicated elsewhere!
    }
}
```

---

## 🚨 **Common Mistakes to Avoid**

### **❌ Red Flags - Stop and Refactor:**
- Creating another `HapticManager`
- Writing `formatCurrency` function again  
- Making custom `ButtonStyle` in view file
- Copy-pasting utility functions
- Creating similar enums (`TransactionType`, etc.)

### **✅ Green Flags - Good Practice:**
- Using existing utilities from `Utils/`
- Checking documentation before coding
- Making utilities generic and reusable
- Updating documentation when adding utilities

---

## 🔍 **Quality Checks**

### **Before Committing:**
```bash
# Run duplicate detector
./check-duplicates.sh

# Check for file size issues  
find FanPlan -name "*.swift" -exec wc -l {} + | sort -nr | head -5
```

### **Code Review Checklist:**
- [ ] No duplicate utilities created
- [ ] Used existing shared utilities
- [ ] File under 500 lines (warning at 500, error at 800)
- [ ] Function under 50 lines  
- [ ] Updated Utils/README.md if needed

---

## 📖 **Quick Reference**

### **Available Utilities:**
```swift
// Haptic Feedback
HapticManager.light()
HapticManager.medium() 
HapticManager.heavy()
HapticManager.success()
HapticManager.error()

// Currency
formatCurrency(amount)

// Button Styles
.buttonStyle(ScaleButtonStyle())
```

### **File Size Guidelines:**
- **Views:** < 300 lines
- **ViewModels:** < 400 lines  
- **Services:** < 500 lines
- **⚠️ Warning:** 500+ lines
- **🚨 Error:** 800+ lines

---

## 🛠️ **Tools Setup**

### **Install SwiftLint:**
```bash
brew install swiftlint
```

### **Run Checks:**
```bash
# Check duplicates
./check-duplicates.sh

# Run SwiftLint
swiftlint

# Find large files
find FanPlan -name "*.swift" -exec wc -l {} + | sort -nr
```

---

## 🎯 **Refactoring Large Files**

### **When file > 500 lines:**

1. **Extract Components First**
2. **Move Utilities to Utils/**
3. **Remove Duplicates**
4. **Test Build**
5. **Update Documentation**

### **Strategy:**
```markdown
Day 1: Extract views/components
Day 2: Extract utilities and models
Day 3: Remove duplicates and test
```

---

## 📞 **Need Help?**

- **Found duplicate?** Check `Utils/README.md`
- **Need new utility?** Create in `Utils/` and document it
- **Large file?** Use refactoring strategy above
- **Build errors?** Run `./check-duplicates.sh`

---

**Remember:** Clean code today saves hours debugging tomorrow! 🚀