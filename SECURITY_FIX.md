# 🔒 URGENT: Security Fixes Required

## Critical Issues Found

### 1. Hardcoded Supabase Credentials
**File**: `FanPlan/Secrets.swift`
**Issue**: Production credentials are hardcoded and committed to repository

### 2. RevenueCat Fallback Key  
**File**: `PiggyBong-New/PiggyBong-App/Core/Services/Config.swift`
**Issue**: Production API key used as fallback

## Immediate Actions Required

### Step 1: Remove Hardcoded Credentials
```bash
# 1. Delete the exposed Secrets.swift file
rm FanPlan/Secrets.swift

# 2. Copy the template
cp FanPlan/Secrets.swift.template FanPlan/Secrets.swift

# 3. Add your keys via environment variables instead
export SUPABASE_URL="your-url-here"
export SUPABASE_ANON_KEY="your-key-here" 
export REVENUECAT_API_KEY="your-key-here"
```

### Step 2: Update Config Files
Replace hardcoded fallbacks with secure handling:

```swift
// Remove this:
static let revenueCatAPIKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] ?? "appl_XXXXXXXXXXXXXXXXXXXXXXX"

// Replace with:
static let revenueCatAPIKey: String = {
    guard let key = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] else {
        #if DEBUG
        return "debug_key_placeholder"
        #else
        fatalError("REVENUECAT_API_KEY environment variable required")
        #endif
    }
    return key
}()
```

### Step 3: Regenerate Exposed Keys
1. **Supabase**: Rotate the anon key in Supabase dashboard
2. **RevenueCat**: Generate new API key if the exposed one was real

### Step 4: Set Up Secure Environment
Create a `.env` file (git-ignored) with your keys:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-new-anon-key
REVENUECAT_API_KEY=your-new-revenue-cat-key
```

## Prevention Measures

1. **Pre-commit Hook**: Add key scanning to prevent future commits
2. **CI/CD Secrets**: Use GitHub Actions secrets for deployment
3. **Code Reviews**: Always review for exposed credentials
4. **Regular Audits**: Run security scans monthly

## Status
- [ ] Remove hardcoded credentials
- [ ] Update config files  
- [ ] Regenerate exposed keys
- [ ] Set up environment variables
- [ ] Test app functionality
- [ ] Add pre-commit hooks