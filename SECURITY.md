# PiggyBong Security Guide

This document outlines the security practices and architecture implemented in PiggyBong to ensure a professional, secure application.

## 🔒 Security Overview

PiggyBong implements enterprise-level security practices including:

- **Zero Hardcoded Credentials**: All API keys and secrets are managed through environment variables
- **Secure Configuration Management**: Multi-environment support with validation
- **Data Protection**: Encrypted communication with Supabase backend
- **Client-Side Security**: Proper handling of authentication tokens
- **Development Security**: Secure local development setup

## 🏗️ Architecture Security

### Environment-Based Configuration

```swift
// ✅ Secure: Environment variable approach
static let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "placeholder"
static let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "placeholder"

// ❌ Insecure: Hardcoded credentials (NOT used in our app)
// static let url = "https://real-project.supabase.co"
// static let apiKey = "real-api-key-12345"
```

### Credential Validation

Our `SupabaseService` includes robust credential validation:

```swift
private init() {
    // Validates credentials exist and are not placeholder values
    if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"],
       let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
       !envURL.isEmpty && !envKey.isEmpty && envKey != "your-anon-key-here" {
        // Use validated credentials
    } else {
        // Fail gracefully with placeholder values
        print("⚠️ No valid Supabase credentials found")
    }
}
```

### API Key Security

- **Anon Keys**: We use Supabase anonymous keys which are safe for client-side use
- **Scoped Permissions**: Keys have limited, read-only permissions appropriate for a mobile app
- **No Service Keys**: We never expose service role keys in the client

## 🛠️ Setup & Configuration

### 1. Environment Setup

Use our automated setup script:

```bash
./scripts/setup_environment.sh
```

Or manually create `.env` file:

```bash
# Production/Cloud Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Local Development (Optional)
SUPABASE_LOCAL_URL=http://127.0.0.1:54321
SUPABASE_LOCAL_ANON_KEY=your-local-anon-key

# Feature Flags
ENABLE_PUSH_NOTIFICATIONS=false
ENABLE_DEBUG_LOGGING=true
```

### 2. Xcode Configuration

For Xcode environment variables:

1. Open your scheme in Xcode (Product → Scheme → Edit Scheme)
2. Go to "Run" → "Arguments" → "Environment Variables"
3. Add your environment variables:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key

### 3. Production Deployment

For App Store deployment:

1. **Never include .env files in your app bundle**
2. **Use Xcode build configurations** to inject environment variables
3. **Configure CI/CD** to use secure credential storage (GitHub Secrets, etc.)

## 🔐 Data Security

### Database Security (Supabase)

- **Row Level Security (RLS)**: Enabled on all user data tables
- **Authentication Required**: All user operations require valid authentication
- **Data Isolation**: Users can only access their own data
- **HTTPS Only**: All API communications are encrypted

### Client-Side Security

```swift
// Secure API request handling
private func makeRequest(path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
    guard let url = URL(string: "\(baseURL)/rest/v1\(path)") else {
        throw SupabaseError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.setValue(apiKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    // Handle errors appropriately
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw SupabaseError.invalidResponse
    }
    
    return data
}
```

## 🚨 Security Checklist

### Development

- [ ] No hardcoded API keys or secrets
- [ ] Environment variables used for all configuration
- [ ] .env files excluded from version control
- [ ] Credential validation implemented
- [ ] Graceful failure for missing credentials

### Production

- [ ] Environment variables configured in deployment
- [ ] No debug logging in production builds
- [ ] HTTPS enforced for all API calls
- [ ] Error messages don't expose sensitive information
- [ ] Database RLS policies tested and verified

### Code Review

- [ ] No credentials in code comments
- [ ] No placeholder credentials left in place
- [ ] Proper error handling for authentication failures
- [ ] Logging doesn't include sensitive data

## 🛡️ Threat Mitigation

### Common Threats Addressed

1. **Credential Exposure**: Environment variables prevent hardcoded secrets
2. **Data Leakage**: RLS ensures users only see their own data
3. **Man-in-the-Middle**: HTTPS enforced for all communications
4. **Unauthorized Access**: Proper authentication and token validation
5. **Code Injection**: Parameterized queries and input validation

### Security Monitoring

Monitor for:
- Failed authentication attempts
- Unusual API usage patterns
- Database connection errors
- Invalid credential warnings in logs

## 📞 Security Contact

For security-related issues:
1. Review this documentation
2. Check environment variable configuration
3. Verify Supabase project settings
4. Contact the development team with specific error messages

## 🔄 Regular Security Maintenance

### Monthly Tasks
- [ ] Review access logs
- [ ] Update dependencies
- [ ] Rotate API keys if needed
- [ ] Test backup and recovery procedures

### Quarterly Tasks
- [ ] Security audit of database permissions
- [ ] Review and update security documentation
- [ ] Penetration testing of API endpoints
- [ ] Update security training for development team

---

**Remember**: Security is everyone's responsibility. When in doubt, err on the side of caution and ask for a security review.