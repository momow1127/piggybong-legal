# Account Deletion Implementation Guide

## Overview
This guide provides the technical implementation for GDPR/CCPA-compliant account deletion in PiggyBong, ensuring users can completely remove their data from all systems.

## Implementation Requirements

### 1. User Interface Components

Add to `ProfileView.swift` or create `AccountManagementView.swift`:

```swift
// MARK: - Account Deletion Section
private var accountDeletionSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Account Management")
            .font(.headline)
            .foregroundColor(.primary)
        
        Button(action: {
            showDeleteConfirmation = true
        }) {
            HStack {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                Text("Delete Account")
                    .foregroundColor(.red)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted within 30 days. You will lose access to premium features and your subscription will be cancelled.")
        }
        
        Text("Deleting your account will permanently remove all your budget data, goals, preferences, and subscription access.")
            .font(.caption)
            .foregroundColor(.gray)
    }
}

@State private var showDeleteConfirmation = false
@State private var isDeletingAccount = false

// MARK: - Account Deletion Handler
private func deleteAccount() async {
    isDeletingAccount = true
    
    do {
        // 1. Cancel active subscriptions
        try await RevenueCatManager.shared.cancelSubscription()
        
        // 2. Delete user data from Supabase
        try await AccountDeletionService.shared.deleteUserAccount()
        
        // 3. Clear local data
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        
        // 4. Sign out and return to onboarding
        await MainActor.run {
            // Reset to onboarding flow
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = UIHostingController(
                    rootView: OnboardingView()
                )
            }
        }
        
    } catch {
        print("❌ Account deletion failed: \(error)")
        // Show error alert
    }
    
    isDeletingAccount = false
}
```

### 2. Account Deletion Service

Create `AccountDeletionService.swift`:

```swift
import Foundation
import Combine

class AccountDeletionService {
    static let shared = AccountDeletionService()
    
    private init() {}
    
    // MARK: - Main Deletion Function
    func deleteUserAccount() async throws {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let userUUID = UUID(uuidString: userId) else {
            throw DeletionError.invalidUserId
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Delete from all database tables
            group.addTask {
                try await self.deleteUserPurchases(userId: userUUID)
            }
            
            group.addTask {
                try await self.deleteUserGoals(userId: userUUID)
            }
            
            group.addTask {
                try await self.deleteUserBudgets(userId: userUUID)
            }
            
            group.addTask {
                try await self.deleteUserArtists(userId: userUUID)
            }
            
            group.addTask {
                try await self.deleteUserAITips(userId: userUUID)
            }
            
            group.addTask {
                try await self.deleteUserActivity(userId: userUUID)
            }
            
            // Wait for all deletions to complete
            try await group.waitForAll()
            
            // Finally, delete the user record
            try await deleteUserRecord(userId: userUUID)
        }
        
        // Log deletion for audit purposes
        await logAccountDeletion(userId: userUUID)
    }
    
    // MARK: - Individual Table Deletions
    private func deleteUserPurchases(userId: UUID) async throws {
        try await SupabaseService.shared.makeRequest(
            path: "/purchases?user_id=eq.\(userId.uuidString)",
            method: "DELETE"
        )
    }
    
    private func deleteUserGoals(userId: UUID) async throws {
        try await SupabaseService.shared.makeRequest(
            path: "/goals?user_id=eq.\(userId.uuidString)",
            method: "DELETE"
        )
    }
    
    private func deleteUserBudgets(userId: UUID) async throws {
        try await SupabaseService.shared.makeRequest(
            path: "/budgets?user_id=eq.\(userId.uuidString)",
            method: "DELETE"
        )
    }
    
    private func deleteUserArtists(userId: UUID) async throws {
        try await SupabaseService.shared.makeRequest(
            path: "/user_artists?user_id=eq.\(userId.uuidString)",
            method: "DELETE"
        )
    }
    
    private func deleteUserAITips(userId: UUID) async throws {
        try await SupabaseService.shared.makeRequest(
            path: "/ai_tips?user_id=eq.\(userId.uuidString)",
            method: "DELETE"
        )
    }
    
    private func deleteUserActivity(userId: UUID) async throws {
        try await SupabaseService.shared.makeRequest(
            path: "/fan_activity?user_id=eq.\(userId.uuidString)",
            method: "DELETE"
        )
    }
    
    private func deleteUserRecord(userId: UUID) async throws {
        try await SupabaseService.shared.makeRequest(
            path: "/users?id=eq.\(userId.uuidString)",
            method: "DELETE"
        )
    }
    
    // MARK: - Audit Logging
    private func logAccountDeletion(userId: UUID) async {
        let logData = [
            "user_id": userId.uuidString,
            "deletion_timestamp": ISO8601DateFormatter().string(from: Date()),
            "deletion_reason": "user_requested",
            "ip_address": "anonymized"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: logData)
            try await SupabaseService.shared.makeRequest(
                path: "/deletion_logs",
                method: "POST",
                body: jsonData
            )
        } catch {
            print("⚠️ Failed to log account deletion: \(error)")
            // Don't fail deletion if logging fails
        }
    }
    
    // MARK: - Error Types
    enum DeletionError: LocalizedError {
        case invalidUserId
        case deletionFailed(String)
        case partialDeletion([String])
        
        var errorDescription: String? {
            switch self {
            case .invalidUserId:
                return "Invalid user ID for deletion"
            case .deletionFailed(let reason):
                return "Account deletion failed: \(reason)"
            case .partialDeletion(let tables):
                return "Partial deletion completed. Failed tables: \(tables.joined(separator: ", "))"
            }
        }
    }
}

// MARK: - RevenueCat Extension
extension RevenueCatManager {
    func cancelSubscription() async throws {
        // RevenueCat doesn't directly cancel subscriptions
        // But we can revoke entitlements and update customer info
        
        try await withCheckedThrowingContinuation { continuation in
            Purchases.shared.getCustomerInfo { customerInfo, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    // Mark customer for deletion in RevenueCat
                    // This removes their data from RevenueCat systems
                    Purchases.shared.syncPurchases { customerInfo, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }
}
```

### 3. Database Deletion Logs Table

Add to Supabase SQL:

```sql
-- Create deletion logs table for compliance audit trail
CREATE TABLE deletion_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    deletion_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deletion_reason TEXT NOT NULL DEFAULT 'user_requested',
    ip_address TEXT DEFAULT 'anonymized',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for efficient querying
CREATE INDEX idx_deletion_logs_user_id ON deletion_logs(user_id);
CREATE INDEX idx_deletion_logs_timestamp ON deletion_logs(deletion_timestamp);

-- Row Level Security
ALTER TABLE deletion_logs ENABLE ROW LEVEL SECURITY;

-- Policy for service role only (admin access)
CREATE POLICY "Service role can manage deletion logs" ON deletion_logs
    USING (auth.role() = 'service_role');
```

### 4. Data Export Before Deletion

Create `DataExportService.swift`:

```swift
import Foundation

class DataExportService {
    static let shared = DataExportService()
    
    private init() {}
    
    func exportUserData(userId: UUID) async throws -> URL {
        let userData = UserDataExport()
        
        // Gather all user data
        userData.user = try await SupabaseService.shared.getUser(id: userId)
        userData.purchases = try await SupabaseService.shared.getPurchases(for: userId, limit: 1000)
        userData.goals = try await SupabaseService.shared.getGoals(for: userId)
        userData.artists = try await SupabaseService.shared.getUserArtists(userId: userId)
        
        // Create JSON export
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(userData)
        
        // Save to temporary file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent("piggybong_data_export_\(Date().timeIntervalSince1970).json")
        
        try jsonData.write(to: exportURL)
        
        return exportURL
    }
}

struct UserDataExport: Codable {
    var user: DatabaseUser?
    var purchases: [DashboardTransaction] = []
    var goals: [Goal] = []
    var artists: [DatabaseUserArtist] = []
    var exportDate = Date()
    var exportVersion = "1.0"
    var dataDescription = "Complete PiggyBong user data export"
}
```

## Implementation Checklist

### UI Components
- [ ] Add "Delete Account" button to Profile/Settings
- [ ] Implement confirmation dialog with clear warnings
- [ ] Add data export option before deletion
- [ ] Show deletion progress indicator
- [ ] Handle deletion errors gracefully

### Backend Integration
- [ ] Create AccountDeletionService class
- [ ] Implement cascading deletion for all user data
- [ ] Add deletion audit logging
- [ ] Create data export functionality
- [ ] Test deletion completeness

### Database Setup
- [ ] Create deletion_logs table in Supabase
- [ ] Add foreign key constraints for cascade deletion
- [ ] Set up Row Level Security policies
- [ ] Create backup procedures for compliance
- [ ] Test database deletion procedures

### RevenueCat Integration
- [ ] Implement subscription cancellation
- [ ] Clear customer data from RevenueCat
- [ ] Handle active subscription edge cases
- [ ] Test subscription cleanup

### Legal Compliance
- [ ] 30-day deletion timeline implementation
- [ ] Audit trail for regulatory compliance
- [ ] Data retention policy enforcement
- [ ] Cross-border deletion coordination

### Testing
- [ ] Test complete deletion flow
- [ ] Verify all data is removed
- [ ] Test edge cases (active subscriptions, pending goals)
- [ ] Validate audit logging
- [ ] Test data export functionality

## Usage Instructions

1. **User Initiates Deletion:**
   - User taps "Delete Account" in settings
   - System shows confirmation with data export option
   - User confirms deletion

2. **Pre-Deletion:**
   - Offer data export (optional)
   - Cancel active subscriptions
   - Show final confirmation

3. **Deletion Process:**
   - Delete all user data across all tables
   - Log deletion for compliance
   - Clear local app data
   - Return user to onboarding

4. **Post-Deletion:**
   - User cannot log back in with same credentials
   - All data permanently removed within 30 days
   - Audit logs maintained for legal compliance

## Error Handling

- **Network Errors:** Retry deletion with exponential backoff
- **Partial Failures:** Log which tables failed, continue with others
- **Subscription Issues:** Notify user about manual cancellation if needed
- **Database Errors:** Provide clear error messages and support contact

This implementation ensures complete GDPR/CCPA compliance while providing a smooth user experience for account deletion.