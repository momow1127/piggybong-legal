# API Key Configuration Guide

## Security First Approach
This project follows security best practices. **NEVER hardcode API keys in source files**.

## Setting Up API Keys

### Method 1: Xcode User-Defined Build Settings (Recommended)

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your target
4. Go to "Build Settings" tab
5. Click "+" and select "Add User-Defined Setting"
6. Add these settings:
   - `SUPABASE_URL` = Your Supabase project URL
   - `SUPABASE_ANON_KEY` = Your Supabase anonymous key
   - `REVENUECAT_API_KEY` = Your RevenueCat API key

### Method 2: Environment Variables (For Development)

1. In Xcode, go to Product → Scheme → Edit Scheme
2. Select "Run" from the left sidebar
3. Go to "Arguments" tab
4. In "Environment Variables" section, add:
   - `SUPABASE_URL` = Your Supabase URL
   - `SUPABASE_ANON_KEY` = Your Supabase anon key
   - `REVENUECAT_API_KEY` = Your RevenueCat key

### Method 3: Using .env File (Local Development Only)

1. Copy `.env.example` to `.env`
2. Fill in your actual API keys
3. **NEVER commit .env to version control**

```bash
cp .env.example .env
# Edit .env with your actual values
```

## Getting Your API Keys

### Supabase Keys
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to Settings → API
4. Copy:
   - `URL` (your project URL)
   - `anon public` key (safe for client-side use)

### RevenueCat API Key
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Select your app
3. Go to API Keys section
4. Copy your Public SDK key

## Security Checklist

- [ ] API keys are in build settings, not source code
- [ ] .env file is in .gitignore
- [ ] No keys in project.pbxproj (use variables like `$(SUPABASE_URL)`)
- [ ] Secrets.swift uses environment/build settings only
- [ ] SupabaseConfig.swift has no hardcoded values
- [ ] All documentation uses placeholder values

## CI/CD Configuration

For GitHub Actions or other CI/CD:

```yaml
env:
  SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
  SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
  REVENUECAT_API_KEY: ${{ secrets.REVENUECAT_API_KEY }}
```

## Troubleshooting

If you see warnings about missing API keys:
1. Check that keys are set in build settings
2. Clean build folder (Shift+Cmd+K)
3. Restart Xcode
4. Verify keys don't contain `$(` placeholder syntax

## Important Notes

- Supabase anon key is safe for client-side use (secured by Row Level Security)
- RevenueCat public key is safe for client-side use
- Never expose service keys or admin keys in client code
- Use Supabase Edge Functions for secure server-side operations