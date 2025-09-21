# Supabase Edge Functions for PiggyBong

This directory contains Supabase Edge Functions for secure, server-side authentication validation required for App Store submission.

## 📁 Functions Overview

### 🍎 `auth-apple/`
**Purpose**: Server-side Apple Sign In validation
- Validates Apple ID tokens
- Extracts user information securely
- Creates/updates user accounts
- Handles profile data from Apple

### 🔍 `auth-google/`
**Purpose**: Server-side Google Sign In validation  
- Validates Google ID tokens with Google's API
- Extracts verified user information
- Creates/updates user accounts
- Handles profile pictures

### 👤 `user-management/`
**Purpose**: Comprehensive user account operations
- Create user accounts
- Update user profiles
- Delete user accounts  
- Email verification
- User data retrieval

## 🚀 Deployment

### Prerequisites
1. **Supabase CLI installed**:
   ```bash
   npm install -g supabase
   ```

2. **Supabase login**:
   ```bash
   supabase login
   ```

3. **Environment variables set**:
   ```bash
   export SUPABASE_PROJECT_REF=your-project-ref
   ```

### Deploy All Functions
```bash
./deploy-edge-functions.sh
```

### Deploy Individual Functions
```bash
# Apple Sign In validation
supabase functions deploy auth-apple --project-ref $SUPABASE_PROJECT_REF

# Google Sign In validation  
supabase functions deploy auth-google --project-ref $SUPABASE_PROJECT_REF

# User management
supabase functions deploy user-management --project-ref $SUPABASE_PROJECT_REF
```

## ⚙️ Configuration

### Required Environment Variables (in Supabase Dashboard)
Navigate to **Project Settings → Edge Functions → Environment Variables**:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com  
APPLE_CLIENT_ID=your.bundle.identifier
```

### iOS App Configuration
Update your `Info.plist`:
```xml
<key>SUPABASE_URL</key>
<string>https://your-project.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>your-anon-key</string>
```

## 📱 iOS Integration

### 1. Add EdgeFunctionService to Your Project
The `EdgeFunctionService.swift` file provides a complete Swift interface for all Edge Functions.

### 2. Update AuthenticationService
Replace direct database calls with Edge Function calls:

```swift
// Before (direct database)
try await supabaseService.createUser(...)

// After (Edge Function)
let result = try await EdgeFunctionService.shared.validateAppleSignIn(credential: credential)
```

### 3. Example Usage

#### Apple Sign In
```swift
func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
    let result = try await EdgeFunctionService.shared.validateAppleSignIn(credential: credential)
    
    guard result.success else {
        throw AuthenticationError.serverValidationFailed
    }
    
    // Handle successful authentication
    updateUserState(from: result)
}
```

#### Google Sign In
```swift  
func signInWithGoogle(idToken: String) async throws {
    let result = try await EdgeFunctionService.shared.validateGoogleSignIn(
        idToken: idToken, 
        accessToken: nil
    )
    
    // Handle result
}
```

#### User Management
```swift
// Create user
let user = try await EdgeFunctionService.shared.createUser(
    email: "user@example.com",
    name: "Fan User", 
    authProvider: "email"
)

// Update user
try await EdgeFunctionService.shared.updateUser(
    userId: userId,
    monthlyBudget: 200.0
)
```

## 🧪 Testing

### Test in Supabase Dashboard
1. Go to **Edge Functions** in your Supabase dashboard
2. Select a function
3. Use the **Invoke** tab to test with sample payloads

### Test Apple Sign In Function
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "authorizationCode": "c1234567890abcdef...",
  "fullName": {
    "givenName": "John",
    "familyName": "Doe"
  }
}
```

### Test Google Sign In Function
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "accessToken": "ya29.a0ARrdaM..."
}
```

### Test User Management Function
```json
{
  "email": "test@example.com",
  "name": "Test User",
  "authProvider": "email"
}
```

## 🔒 Security Features

### ✅ What These Functions Provide:
- **Server-side token validation** - Tokens verified with Apple/Google
- **Secure user creation** - Prevents client-side manipulation  
- **Email verification** - Proper email confirmation flow
- **Audit logging** - All auth events logged in Supabase
- **Input validation** - Sanitized and validated data
- **CORS protection** - Proper cross-origin handling

### 🛡️ App Store Compliance:
- **Data protection** - User data handled server-side
- **Authentication security** - Industry-standard validation
- **Privacy compliance** - Proper data handling and consent
- **Audit trails** - Complete authentication logging

## 🐛 Troubleshooting

### Common Issues

#### 1. Function Not Found
```
Error: Function 'auth-apple' not found
```
**Solution**: Ensure function is deployed with correct name:
```bash
supabase functions deploy auth-apple --project-ref $SUPABASE_PROJECT_REF
```

#### 2. Environment Variables Missing
```
Error: SUPABASE_URL is undefined
```
**Solution**: Set environment variables in Supabase dashboard under **Project Settings → Edge Functions**.

#### 3. CORS Errors
```
Access to fetch blocked by CORS policy
```
**Solution**: Functions include CORS headers. Check that you're calling from allowed origins.

#### 4. Token Validation Fails
```
Error: Invalid token issuer
```
**Solution**: Ensure tokens are fresh and from correct provider (Apple/Google).

### Debugging

#### View Function Logs
```bash
supabase functions logs auth-apple --project-ref $SUPABASE_PROJECT_REF
```

#### Test Local Development
```bash
supabase start
supabase functions serve auth-apple
```

## 📚 Additional Resources

- [Supabase Edge Functions Documentation](https://supabase.com/docs/guides/functions)
- [Apple Sign In Server-to-Server Validation](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user)
- [Google Sign In Server-Side Validation](https://developers.google.com/identity/sign-in/web/backend-auth)

## 🔄 Development Workflow

### 1. MVP Testing Phase (Current)
- Use existing client-side authentication
- Test all features and user flows
- Validate app functionality

### 2. App Store Preparation Phase
- Deploy Edge Functions to Supabase
- Update iOS app to use Edge Functions  
- Test authentication flows with server validation
- Submit to App Store Review

### 3. Production Phase  
- Monitor function performance
- Add additional security measures
- Scale based on user growth

---

**Need help?** Check the function logs in Supabase dashboard or run the test scripts to debug issues.