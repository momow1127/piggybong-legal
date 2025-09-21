# Secure Configuration Guide for PiggyBong2

## Important Security Notice
**NEVER commit actual API keys or credentials to version control!**

## Environment Setup

### 1. Local Development (.env file)
Create a `.env` file in the project root (this file is already in .gitignore):

```bash
# Supabase Configuration
SUPABASE_URL=your_actual_supabase_url
SUPABASE_ANON_KEY=your_actual_supabase_anon_key

# RevenueCat Configuration  
REVENUECAT_API_KEY=your_actual_revenuecat_api_key

# API Keys (when you have them)
OPENAI_API_KEY=your_openai_api_key_here
TICKETMASTER_API_KEY=your_ticketmaster_api_key_here
```

### 2. Xcode Configuration

#### Setting Environment Variables in Xcode:
1. Open `FanPlan.xcodeproj` in Xcode
2. Select the "Piggy Bong" scheme -> Edit Scheme
3. Go to Run -> Arguments
4. Add Environment Variables:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key
   - `REVENUECAT_API_KEY`: Your RevenueCat API key

#### Alternative: Xcode Build Settings
1. Select your project in Xcode
2. Go to Build Settings
3. Click `+` -> Add User-Defined Setting
4. Add the same environment variables as above

### 3. Running the Project

#### With Environment Variables:
```bash
# Load environment variables and run
source .env
xcodebuild -project FanPlan.xcodeproj -scheme "Piggy Bong" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  SUPABASE_URL="$SUPABASE_URL" \
  SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  REVENUECAT_API_KEY="$REVENUECAT_API_KEY" \
  build
```

#### Using the Auto-Commit Script:
```bash
# Commits and pushes all changes automatically
./auto-commit.sh
```

### 4. Python Scripts
The Python scripts now automatically read from environment variables:
```bash
# Set environment variables first
export SUPABASE_URL="your_supabase_url"
export SUPABASE_ANON_KEY="your_supabase_anon_key"

# Then run the scripts
python simple_rss_checker.py
python auto_update_artists.py
```

## Security Best Practices

### DO:
- ✅ Use environment variables for all sensitive data
- ✅ Keep `.env` file in `.gitignore`
- ✅ Rotate keys regularly
- ✅ Use different keys for development and production
- ✅ Store production keys in secure services (AWS Secrets Manager, etc.)

### DON'T:
- ❌ Hardcode API keys in source code
- ❌ Commit `.env` files to Git
- ❌ Share API keys in documentation
- ❌ Use production keys in development

## Key Rotation

If keys are accidentally exposed:
1. **Immediately** rotate the exposed keys in the respective dashboards:
   - [Supabase Dashboard](https://app.supabase.com)
   - [RevenueCat Dashboard](https://app.revenuecat.com)
2. Update your local `.env` file
3. Update environment variables in Xcode
4. Update any CI/CD configurations
5. Audit access logs for any unauthorized usage

## Files Updated for Security

The following files have been updated to use environment variables:
- ✅ `Piggy-Bong-Info.plist` - Now uses `$(VARIABLE_NAME)` syntax
- ✅ `FanPlan.xcodeproj/project.pbxproj` - Build settings use environment variables
- ✅ `simple_rss_checker.py` - Uses `os.environ.get()`
- ✅ `auto_update_artists.py` - Uses `os.environ.get()`
- ✅ `FanPlan/Secrets.swift` - Already properly configured
- ✅ `FanPlan/Config.swift` - Already properly configured

## Verification

To verify your configuration is secure:
```bash
# Check for hardcoded keys (should return nothing)
grep -r "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" . --exclude-dir=.git --exclude=.env
grep -r "appl_" . --exclude-dir=.git --exclude=.env
```

## Support

For any security concerns or questions, please refer to:
- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/security)
- [RevenueCat Security](https://www.revenuecat.com/docs/security)