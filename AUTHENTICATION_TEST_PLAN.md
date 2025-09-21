# PiggyBong Authentication Testing Plan

## Executive Summary

This document outlines a comprehensive testing strategy for the PiggyBong iOS app's authentication system. The app implements Apple Sign-In, Google Sign-In, and email authentication with Supabase backend integration.

## Authentication System Architecture

### Current Implementation
- **Frontend**: SwiftUI-based authentication flows
- **Backend**: Supabase with PostgreSQL database
- **Authentication Methods**:
  1. Apple Sign-In (ASAuthorizationController)
  2. Google Sign-In (GoogleSignIn SDK)
  3. Email/Password (Supabase Auth)
- **Session Management**: Keychain storage with Supabase JWT tokens
- **User Management**: Custom user profiles linked to auth providers

### Configuration Status
✅ **Environment Variables Configured**:
- `SUPABASE_URL`: https://YOUR-PROJECT.supabase.co
- `SUPABASE_ANON_KEY`: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
- `GOOGLE_CLIENT_ID`: 301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com
- `APPLE_CLIENT_ID`: carmenwong.PiggyBong

✅ **Info.plist Configured**: All required keys and URL schemes are properly set
✅ **Dependencies Installed**: Supabase Swift SDK, GoogleSignIn, RevenueCat

## Test Categories

### 1. Unit Tests (Existing)

**Location**: `/FanPlanTests/AuthenticationServiceTests.swift`

**Coverage**:
- ✅ Initial authentication state validation
- ✅ Email/password validation functions
- ✅ Name and budget validation
- ✅ Sign-up flow with valid data
- ✅ Sign-in flow testing
- ✅ Sign-out flow testing
- ✅ Keychain persistence
- ✅ Error handling for invalid data
- ✅ Concurrent authentication request handling

**Status**: Tests exist but cannot run due to build dependencies

### 2. Integration Tests (Manual Testing Required)

#### Apple Sign-In Flow

**Test Scenarios**:
1. **First-time Apple Sign-In**
   - User grants full name and email
   - Account creation in Supabase
   - Profile linking and session establishment
   - Keychain storage verification

2. **Returning Apple Sign-In User**
   - Existing account recognition
   - Session restoration
   - Profile data synchronization

3. **Apple Sign-In Privacy Features**
   - "Hide My Email" functionality
   - Limited name sharing
   - Private email relay handling

**Expected Results**:
- User profile created with Apple ID linked
- JWT token stored in keychain
- Supabase user record with Apple auth provider
- Automatic budget initialization ($100 default)

#### Google Sign-In Flow

**Test Scenarios**:
1. **First-time Google Sign-In**
   - Google OAuth consent screen
   - Account creation with Google profile data
   - Profile photo and email synchronization

2. **Returning Google User**
   - Automatic sign-in with stored credentials
   - Profile updates from Google account
   - Session validation and refresh

3. **Google Account Switching**
   - Multiple Google accounts handling
   - Account selection interface
   - Proper session isolation

**Expected Results**:
- Google profile data (name, email, photo) imported
- OAuth tokens managed by GoogleSignIn SDK
- Supabase integration with Google provider
- User preferences synchronized

#### Email Authentication Flow

**Test Scenarios**:
1. **New User Registration**
   - Email validation and format checking
   - Password strength validation
   - Email verification code system
   - Terms of service acceptance

2. **User Sign-In**
   - Credential validation
   - Session establishment
   - "Remember me" functionality
   - Password reset flow

3. **Email Verification System**
   - Verification code generation and delivery
   - Code validation and expiration
   - Resend code functionality
   - Account activation flow

**Expected Results**:
- Email verification codes sent via Supabase Edge Functions
- Secure password storage with bcrypt
- Session tokens with proper expiration
- User profile creation with email provider

### 3. Supabase Integration Tests

#### Database Operations
1. **User Profile Creation**
   - Table: `users` with proper schema
   - Foreign key relationships
   - Data validation constraints

2. **Authentication Provider Linking**
   - Apple ID to user mapping
   - Google ID to user mapping
   - Email provider association

3. **Session Management**
   - JWT token validation
   - Refresh token handling
   - Session expiration and renewal

#### Edge Functions Testing
1. **Email Verification** (`verify-email-code`)
2. **Apple Sign-In Validation** (`auth-apple`)
3. **Google Sign-In Integration** (`auth-google`)

### 4. Security Testing

#### Authentication Security
1. **Token Security**
   - JWT token integrity
   - Keychain storage encryption
   - Token expiration handling

2. **Input Validation**
   - SQL injection prevention
   - XSS protection
   - Email format validation
   - Password complexity requirements

3. **Session Security**
   - Secure session invalidation
   - Cross-device session management
   - Unauthorized access prevention

## Manual Testing Procedure

### Phase 1: Development Environment Setup

1. **Build Verification**
   ```bash
   cd "/path/to/project"
   export SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
   export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   xcodebuild -project "FanPlan.xcodeproj" -scheme "Piggy Bong" \
   -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16" build
   ```

2. **Launch App in Simulator**
   - Open iOS Simulator
   - Install and launch Piggy Bong
   - Navigate to authentication screen

3. **Debug Panel Access**
   - Tap "🔧 DEBUG AUTH" button
   - Run comprehensive authentication diagnostics
   - Verify all configuration values

### Phase 2: Authentication Flow Testing

#### Apple Sign-In Testing
**Note**: Requires physical device or TestFlight, not functional in simulator

1. **Device Testing**:
   - Install app via Xcode on physical device
   - Test Apple Sign-In flow end-to-end
   - Verify Supabase user creation
   - Check profile data synchronization

#### Google Sign-In Testing

1. **Simulator Testing**:
   - Tap "Continue with Google" button
   - Complete Google OAuth flow
   - Verify account creation in Supabase dashboard
   - Check profile data import

2. **Error Handling**:
   - Test with cancelled OAuth
   - Test with invalid credentials
   - Verify graceful error messages

#### Email Authentication Testing

1. **Sign-Up Flow**:
   - Enter valid email and password
   - Verify email validation
   - Check verification code delivery
   - Complete account activation

2. **Sign-In Flow**:
   - Test with existing account
   - Verify session persistence
   - Test "forgot password" flow

### Phase 3: Database Verification

1. **Supabase Dashboard Inspection**
   - Navigate to https://YOUR-PROJECT.supabase.co
   - Check `users` table for new records
   - Verify `auth.users` integration
   - Inspect user profile data

2. **Edge Function Monitoring**
   - Check function execution logs
   - Verify email delivery
   - Monitor authentication events

## Test Data Requirements

### Test Accounts Needed
1. **Google Account**: For Google Sign-In testing
2. **Apple ID**: For Apple Sign-In testing (device required)
3. **Test Email**: For email authentication testing
4. **Invalid Credentials**: For error testing

### Environment Configuration
```bash
# Development Environment Variables
export SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
export GOOGLE_CLIENT_ID="301452889528-rqd96cu7r6gtu46fmvafrdfbhsjn9vq1.apps.googleusercontent.com"
```

## Expected Test Results

### Successful Authentication Flow
1. User successfully authenticates via chosen method
2. User profile created in Supabase database
3. Session token stored securely in keychain
4. User redirected to onboarding or main app flow
5. Authentication state persists across app restarts

### Error Scenarios
1. Network connectivity issues handled gracefully
2. Invalid credentials show appropriate error messages
3. OAuth cancellation returns to authentication screen
4. Verification failures provide clear guidance

## Automated Testing Recommendations

### Future Unit Test Enhancements
1. **Mock Supabase Service**: Create test doubles for database operations
2. **Network Testing**: Mock URLSession for network error simulation
3. **Keychain Testing**: Mock keychain operations for CI/CD
4. **OAuth Flow Testing**: Mock third-party authentication

### Integration Test Automation
1. **UI Testing**: XCUITest for complete authentication flows
2. **API Testing**: Direct Supabase Edge Function testing
3. **Performance Testing**: Authentication speed benchmarks
4. **Security Testing**: Automated vulnerability scanning

## Risk Assessment

### High Priority Issues
1. **Apple Sign-In Device Requirement**: Cannot fully test in simulator
2. **Google OAuth Dependencies**: Network and account dependencies
3. **Email Delivery**: Relies on Supabase SMTP configuration
4. **Database Schema**: Changes could break authentication

### Medium Priority Issues
1. **Session Expiration**: Long-term token management
2. **Cross-Device Sync**: Multi-device authentication state
3. **Privacy Compliance**: GDPR/COPPA requirements
4. **Rate Limiting**: Authentication attempt limits

## Conclusion

The PiggyBong authentication system is well-architected with comprehensive error handling and multiple authentication providers. The existing test infrastructure provides good unit test coverage, but manual testing is required for complete validation due to OAuth dependencies and device-specific features.

### Immediate Action Items
1. ✅ Environment variables configured
2. 🔄 Build app successfully (in progress)
3. ⏳ Run manual authentication testing
4. ⏳ Verify Supabase database integration
5. ⏳ Document test results and issues

### Success Metrics
- All three authentication methods work end-to-end
- User profiles created correctly in Supabase
- Session persistence across app restarts
- Error handling provides clear user feedback
- No security vulnerabilities identified

This testing plan provides comprehensive coverage of the authentication system and should be executed in phases to ensure reliable and secure user authentication.