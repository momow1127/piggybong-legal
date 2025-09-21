import Foundation

// MARK: - RevenueCat Configuration Guide
/// Complete setup checklist for App Store Connect and RevenueCat integration
/// Addresses "Product not found" and "READY_TO_SUBMIT" status issues
struct RevenueCatConfigurationGuide {

    // MARK: - Current Product Issues Analysis

    /// Products mentioned in error logs that need fixing
    static let problematicProducts = [
        "carmenwong.PiggyBong.Monthly",     // ❌ Wrong format - contains bundle ID
        "PIGGYBONG_APP_2025",              // ❌ Wrong format - too generic
        "piggybong_vip_monthly"            // ✅ Correct format
    ]

    /// Correct product identifiers that should be used
    static let correctProductIDs = [
        "piggybong_vip_monthly",           // ✅ Monthly VIP subscription
        "piggybong_vip_annual",            // ✅ Annual VIP subscription (recommended)
        "piggybong_premium_monthly",       // ✅ Alternative premium tier
    ]

    // MARK: - App Store Connect Setup Checklist

    /// Complete step-by-step checklist for App Store Connect
    static func getAppStoreConnectChecklist() -> [SetupStep] {
        return [
            // STEP 1: App Store Connect App Setup
            SetupStep(
                title: "1. Create App in App Store Connect",
                description: """
                • Go to App Store Connect → My Apps
                • Create new app with Bundle ID: carmenwong.PiggyBong
                • Ensure App Store Connect app status is "Prepare for Submission" or higher
                • Add app metadata (name, description, screenshots)
                """,
                isRequired: true,
                verificationMethod: "App visible in App Store Connect dashboard"
            ),

            // STEP 2: In-App Purchase Creation
            SetupStep(
                title: "2. Create In-App Purchase Products",
                description: """
                • Go to Features → In-App Purchases → Create
                • Product Type: Auto-Renewable Subscription
                • Product ID: piggybong_vip_monthly (exactly this)
                • Reference Name: Piggy Bong VIP Monthly
                • Price: Select appropriate tier (e.g., $4.99/month)
                • Subscription Group: Create "Piggy Bong VIP" group
                """,
                isRequired: true,
                verificationMethod: "Product shows 'Ready to Submit' status"
            ),

            // STEP 3: Subscription Group Configuration
            SetupStep(
                title: "3. Configure Subscription Group",
                description: """
                • Create subscription group: "Piggy Bong VIP"
                • Add localizations for all target markets
                • Set subscription group name and optional message
                • Rank subscriptions (monthly = 1, annual = 2 for higher priority)
                """,
                isRequired: true,
                verificationMethod: "Subscription group appears in Features section"
            ),

            // STEP 4: Product Localization
            SetupStep(
                title: "4. Add Product Localizations",
                description: """
                • For each product, add localizations:
                  - English: "VIP Monthly Subscription"
                  - Description: "Unlock unlimited K-pop artist tracking, premium insights, and ad-free experience"
                • Add additional languages if targeting international markets
                • Ensure all required fields are filled
                """,
                isRequired: true,
                verificationMethod: "All localizations show green checkmarks"
            ),

            // STEP 5: App Submission for Review
            SetupStep(
                title: "5. Submit App for Review",
                description: """
                • CRITICAL: In-app purchases only become available AFTER app approval
                • Submit app with version 1.0 to App Store Review
                • Include in-app purchases in submission
                • Provide review notes explaining subscription benefits
                • Status must change from "Ready to Submit" → "In Review" → "Approved"
                """,
                isRequired: true,
                verificationMethod: "App status shows 'Ready for Sale' or 'In Review'"
            ),

            // STEP 6: Testing with Sandbox
            SetupStep(
                title: "6. Set Up Sandbox Testing",
                description: """
                • Create sandbox test users in App Store Connect
                • Test purchases work in development/TestFlight builds
                • Verify RevenueCat receives purchase events
                • Check subscription status changes correctly
                """,
                isRequired: false,
                verificationMethod: "Successful test purchases in sandbox environment"
            ),

            // STEP 7: RevenueCat Configuration
            SetupStep(
                title: "7. Configure RevenueCat Project",
                description: """
                • Log into RevenueCat dashboard
                • Add App Store Connect integration
                • Upload App Store Connect API key
                • Verify product IDs match exactly:
                  - App Store Connect: piggybong_vip_monthly
                  - RevenueCat: piggybong_vip_monthly
                • Create entitlements (e.g., "vip_access")
                """,
                isRequired: true,
                verificationMethod: "Products show 'Active' status in RevenueCat"
            )
        ]
    }

    // MARK: - Common Pitfalls and Solutions

    static func getCommonPitfalls() -> [ConfigurationPitfall] {
        return [
            ConfigurationPitfall(
                issue: "Product ID Mismatch",
                description: "RevenueCat product IDs don't exactly match App Store Connect",
                solution: """
                • App Store Connect: piggybong_vip_monthly
                • RevenueCat: piggybong_vip_monthly
                • iOS Code: "piggybong_vip_monthly"
                All three MUST be identical (case-sensitive)
                """,
                severity: .critical
            ),

            ConfigurationPitfall(
                issue: "Bundle ID in Product Name",
                description: "Using bundle ID in product identifier (carmenwong.PiggyBong.Monthly)",
                solution: """
                • WRONG: carmenwong.PiggyBong.Monthly
                • RIGHT: piggybong_vip_monthly
                Product IDs should NOT include bundle identifier
                """,
                severity: .critical
            ),

            ConfigurationPitfall(
                issue: "App Not Submitted for Review",
                description: "In-app purchases stuck in 'Ready to Submit' status",
                solution: """
                • In-app purchases only work AFTER app is approved by Apple
                • Submit app version 1.0 with in-app purchases included
                • Wait for Apple approval (typically 24-48 hours)
                • Products automatically become available after approval
                """,
                severity: .critical
            ),

            ConfigurationPitfall(
                issue: "Missing Subscription Group",
                description: "Subscription products not added to subscription group",
                solution: """
                • Create subscription group in App Store Connect
                • Add all subscription tiers to the same group
                • Configure group metadata and localizations
                • This enables upgrade/downgrade functionality
                """,
                severity: .high
            ),

            ConfigurationPitfall(
                issue: "Incomplete Localizations",
                description: "Missing product descriptions or localizations",
                solution: """
                • Add English localization at minimum
                • Include compelling product descriptions
                • All required fields must be filled out
                • Consider additional languages for international markets
                """,
                severity: .medium
            ),

            ConfigurationPitfall(
                issue: "Wrong RevenueCat API Key",
                description: "Using wrong API key or outdated credentials",
                solution: """
                • Verify API key in RevenueCat dashboard
                • Check if key has proper permissions
                • Regenerate key if necessary
                • Update key in iOS app code and configuration
                """,
                severity: .high
            )
        ]
    }

    // MARK: - Verification Methods

    /// Verify RevenueCat configuration is correct
    static func verifyConfiguration() -> ConfigurationStatus {
        var issues: [String] = []
        var warnings: [String] = []

        // Check product ID format
        for productID in problematicProducts {
            if productID.contains(".") {
                issues.append("Product ID '\(productID)' contains periods - should use underscores")
            }
            if productID.contains(Bundle.main.bundleIdentifier ?? "") {
                issues.append("Product ID '\(productID)' contains bundle identifier - remove it")
            }
            if productID.uppercased() == productID {
                warnings.append("Product ID '\(productID)' is all uppercase - consider lowercase with underscores")
            }
        }

        // Check for correct format
        let hasCorrectProducts = correctProductIDs.contains { productID in
            // This would check against your actual RevenueCat configuration
            return true // Placeholder
        }

        if !hasCorrectProducts {
            issues.append("No products found with correct naming convention")
        }

        return ConfigurationStatus(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            recommendations: [
                "Use snake_case for product IDs (e.g., piggybong_vip_monthly)",
                "Submit app for review to activate in-app purchases",
                "Test purchases in sandbox environment first",
                "Monitor RevenueCat dashboard for real-time status updates"
            ]
        )
    }
}

// MARK: - Supporting Data Structures

struct SetupStep {
    let title: String
    let description: String
    let isRequired: Bool
    let verificationMethod: String
}

struct ConfigurationPitfall {
    let issue: String
    let description: String
    let solution: String
    let severity: Severity

    enum Severity {
        case critical, high, medium, low
    }
}

struct ConfigurationStatus {
    let isValid: Bool
    let issues: [String]
    let warnings: [String]
    let recommendations: [String]
}

// MARK: - Quick Reference Commands

extension RevenueCatConfigurationGuide {

    /// Product IDs that should be created in App Store Connect
    static let requiredProducts = [
        (id: "piggybong_vip_monthly", name: "VIP Monthly", price: "$4.99/month"),
        (id: "piggybong_vip_annual", name: "VIP Annual", price: "$39.99/year"),
    ]

    /// RevenueCat entitlements that should be configured
    static let requiredEntitlements = [
        (id: "vip_access", name: "VIP Access", description: "Unlimited artists and premium features")
    ]

    /// Bundle ID verification
    static let expectedBundleID = "carmenwong.PiggyBong"
}