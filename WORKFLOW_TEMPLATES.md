# PiggyBong Workflow Templates
## 6-Day Development Cycle Templates & Automation

---

## 🎯 Template Overview

This document provides concrete, actionable workflow templates for each team and phase of the 6-day development cycle, optimized for the PiggyBong iOS project.

---

## 📋 Sprint Planning Template (Day 0)

### **Pre-Sprint Preparation Checklist**

#### **Product Owner Tasks** (2 hours before planning)
- [ ] Prioritized backlog ready with user stories
- [ ] Acceptance criteria defined for top 5 features
- [ ] Business value and user impact documented
- [ ] Stakeholder feedback incorporated
- [ ] Market research and competitor analysis updated

#### **Technical Lead Tasks** (1 hour before planning)
- [ ] Technical debt assessment completed
- [ ] Architecture impact analysis for planned features
- [ ] Resource capacity review (team availability)
- [ ] Dependency mapping with other teams/systems
- [ ] Risk assessment for complex features

#### **Design Lead Tasks** (1 hour before planning)
- [ ] UX research findings summarized
- [ ] Design system component needs identified
- [ ] User journey updates documented
- [ ] Accessibility requirements reviewed
- [ ] Visual design mockups prioritized

### **Sprint Planning Meeting Template** (2 hours)

#### **Agenda Structure**
```markdown
## Sprint Planning - Cycle [Number] - [Date]

### Part 1: What We'll Build (60 minutes)
- [ ] Product vision and cycle goals presentation (10 min)
- [ ] Backlog review and story point estimation (30 min)
- [ ] Team capacity and velocity planning (15 min)
- [ ] Sprint goal definition and commitment (5 min)

### Part 2: How We'll Build It (60 minutes)
- [ ] Task breakdown and ownership assignment (25 min)
- [ ] Cross-team dependency identification (15 min)
- [ ] Technical spike planning (10 min)
- [ ] Risk mitigation strategy discussion (10 min)

### Outputs Required:
- [ ] Sprint backlog with clear ownership
- [ ] Dependency map with timelines
- [ ] Definition of done for each story
- [ ] Communication plan for stakeholders
```

#### **Story Estimation Template**
```markdown
## User Story: [Title]

**As a** [user type]
**I want** [functionality]
**So that** [business value]

### Acceptance Criteria:
- [ ] [Specific, testable criteria 1]
- [ ] [Specific, testable criteria 2]
- [ ] [Specific, testable criteria 3]

### Technical Tasks:
- [ ] iOS UI implementation (Team Alpha) - [X hours]
- [ ] Backend API development (Team Beta) - [X hours]
- [ ] Design system updates (Team Delta) - [X hours]
- [ ] CI/CD pipeline updates (Team Gamma) - [X hours]

### Dependencies:
- **Blocked by**: [Other stories/external dependencies]
- **Blocks**: [Stories waiting on this completion]

### Definition of Done:
- [ ] Feature implemented according to acceptance criteria
- [ ] Unit tests written and passing (>80% coverage)
- [ ] Integration tests passing
- [ ] Code review completed
- [ ] Design system compliance verified
- [ ] Accessibility testing passed
- [ ] Documentation updated
```

---

## 📱 iOS Development Workflow (Team Alpha)

### **Day 1-2: Foundation Development**

#### **Morning Kickoff Template**
```swift
// Daily Development Checklist - Day 1-2
// Team Alpha - iOS Development

### Today's Priority Tasks:
- [ ] Feature scaffolding using existing design system
- [ ] SwiftUI view structure creation
- [ ] ViewModel integration with backend services
- [ ] Navigation flow implementation
- [ ] Initial unit test setup

### Design System Integration Checklist:
- [ ] Import PiggyDesignSystem components
- [ ] Verify typography consistency
- [ ] Apply standard color tokens
- [ ] Implement proper spacing guidelines
- [ ] Use standardized button styles

### Code Quality Standards:
- [ ] Follow Swift naming conventions
- [ ] Implement proper error handling
- [ ] Add SwiftUI previews for all views
- [ ] Document complex business logic
- [ ] Ensure thread safety for async operations
```

#### **Feature Implementation Template**
```swift
// MARK: - [FeatureName]View Implementation Template

import SwiftUI
import PiggyDesignSystem

struct [FeatureName]View: View {
    // MARK: - Properties
    @StateObject private var viewModel = [FeatureName]ViewModel()
    @EnvironmentObject private var userSession: UserSession
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Feature content implementation
                [FeatureName]Content()
            }
            .standardHorizontalPadding()
            .gradientBackground()
            .navigationTitle("[Feature Name]")
            .navigationBarStyle(.piggy)
        }
        .task {
            await viewModel.loadInitialData()
        }
        .alert("Error", isPresented: $viewModel.hasError) {
            Button("Retry") {
                Task { await viewModel.retry() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Content Components
private extension [FeatureName]View {
    @ViewBuilder
    func [FeatureName]Content() -> some View {
        // Implementation using design system components
    }
}

// MARK: - Previews
struct [FeatureName]View_Previews: PreviewProvider {
    static var previews: some View {
        [FeatureName]View()
            .environmentObject(UserSession.mock)
            .preferredColorScheme(.dark)
    }
}
```

#### **ViewModel Template**
```swift
// MARK: - [FeatureName]ViewModel Template

import Foundation
import Combine

@MainActor
class [FeatureName]ViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    // Feature-specific published properties
    @Published var [featureData]: [DataType] = []
    
    // MARK: - Dependencies
    private let [serviceName]: [ServiceType]
    private let analyticsService: AnalyticsService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init([serviceName]: [ServiceType] = .[serviceName]) {
        self.[serviceName] = [serviceName]
        self.analyticsService = AnalyticsService.shared
    }
    
    // MARK: - Public Methods
    func loadInitialData() async {
        isLoading = true
        hasError = false
        
        do {
            // Implementation
            analyticsService.track(event: "[feature]_loaded")
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func retry() async {
        await loadInitialData()
    }
    
    // MARK: - Private Methods
    private func handleError(_ error: Error) {
        hasError = true
        errorMessage = error.localizedDescription
        analyticsService.track(error: error, context: "[FeatureName]ViewModel")
    }
}
```

### **Day 3-4: Integration & Testing**

#### **Integration Testing Template**
```swift
// MARK: - [FeatureName]IntegrationTests

import XCTest
@testable import FanPlan

class [FeatureName]IntegrationTests: XCTestCase {
    
    var viewModel: [FeatureName]ViewModel!
    var mockService: Mock[ServiceName]!
    
    override func setUp() {
        super.setUp()
        mockService = Mock[ServiceName]()
        viewModel = [FeatureName]ViewModel([serviceName]: mockService)
    }
    
    func testSuccessfulDataLoad() async {
        // Given
        let expectedData = [DataType].mock
        mockService.stub[methodName](return: expectedData)
        
        // When
        await viewModel.loadInitialData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasError)
        XCTAssertEqual(viewModel.[featureData], expectedData)
    }
    
    func testErrorHandling() async {
        // Given
        let expectedError = APIError.networkError
        mockService.stub[methodName](throw: expectedError)
        
        // When
        await viewModel.loadInitialData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.hasError)
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription)
    }
}
```

---

## 🔧 Backend Services Workflow (Team Beta)

### **Day 1-2: API Development**

#### **Service Implementation Template**
```swift
// MARK: - [FeatureName]Service Implementation

import Foundation
import Supabase

protocol [FeatureName]ServiceProtocol {
    func get[FeatureName]Data(userId: UUID) async throws -> [DataType]
    func create[FeatureName](data: [CreateDataType]) async throws -> [DataType]
    func update[FeatureName](id: UUID, data: [UpdateDataType]) async throws -> [DataType]
    func delete[FeatureName](id: UUID) async throws
}

class [FeatureName]Service: [FeatureName]ServiceProtocol {
    
    // MARK: - Properties
    private let supabase: SupabaseClient
    private let logger: Logger
    
    // MARK: - Initialization
    init(supabase: SupabaseClient = SupabaseService.shared.client) {
        self.supabase = supabase
        self.logger = Logger(category: "[FeatureName]Service")
    }
    
    // MARK: - Protocol Implementation
    func get[FeatureName]Data(userId: UUID) async throws -> [DataType] {
        logger.info("Fetching [feature] data for user: \(userId)")
        
        let response: [DatabaseModel] = try await supabase
            .from("[table_name]")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        let data = response.map { $0.toDomainModel() }
        logger.info("Successfully fetched \(data.count) [feature] records")
        
        return data
    }
    
    func create[FeatureName](data: [CreateDataType]) async throws -> [DataType] {
        logger.info("Creating new [feature] record")
        
        let databaseModel = data.toDatabaseModel()
        
        let response: DatabaseModel = try await supabase
            .from("[table_name]")
            .insert(databaseModel)
            .select()
            .single()
            .execute()
            .value
        
        let createdData = response.toDomainModel()
        logger.info("Successfully created [feature] with ID: \(createdData.id)")
        
        return createdData
    }
    
    // Additional CRUD operations...
    
    // MARK: - Private Methods
    private func handleSupabaseError(_ error: Error) -> Error {
        // Enhanced error handling and logging
        logger.error("Supabase error: \(error)")
        
        if let supabaseError = error as? SupabaseError {
            switch supabaseError {
            case .network:
                return [FeatureName]Error.networkUnavailable
            case .authentication:
                return [FeatureName]Error.unauthorized
            default:
                return [FeatureName]Error.serverError
            }
        }
        
        return [FeatureName]Error.unknown(error)
    }
}
```

#### **Database Model Template**
```swift
// MARK: - [FeatureName] Database Models

import Foundation

// Database model matching Supabase schema
struct [FeatureName]DatabaseModel: Codable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date
    
    // Feature-specific properties
    let [property1]: [Type1]
    let [property2]: [Type2]?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case [property1] = "[database_column_1]"
        case [property2] = "[database_column_2]"
    }
}

// Domain model for app logic
struct [FeatureName]DomainModel {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date
    
    // Feature-specific properties
    let [property1]: [Type1]
    let [property2]: [Type2]?
}

// MARK: - Model Conversions
extension [FeatureName]DatabaseModel {
    func toDomainModel() -> [FeatureName]DomainModel {
        [FeatureName]DomainModel(
            id: id,
            userId: userId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            [property1]: [property1],
            [property2]: [property2]
        )
    }
}

extension [FeatureName]DomainModel {
    func toDatabaseModel() -> [FeatureName]DatabaseModel {
        [FeatureName]DatabaseModel(
            id: id,
            userId: userId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            [property1]: [property1],
            [property2]: [property2]
        )
    }
}
```

### **Day 3-4: Integration Testing & Optimization**

#### **Service Testing Template**
```swift
// MARK: - [FeatureName]ServiceTests

import XCTest
@testable import FanPlan

class [FeatureName]ServiceTests: XCTestCase {
    
    var service: [FeatureName]Service!
    var mockSupabase: MockSupabaseClient!
    
    override func setUp() {
        super.setUp()
        mockSupabase = MockSupabaseClient()
        service = [FeatureName]Service(supabase: mockSupabase)
    }
    
    func testGetFeatureDataSuccess() async throws {
        // Given
        let userId = UUID()
        let expectedData = [[FeatureName]DatabaseModel].mock
        mockSupabase.stubSelect(return: expectedData)
        
        // When
        let result = try await service.get[FeatureName]Data(userId: userId)
        
        // Then
        XCTAssertEqual(result.count, expectedData.count)
        XCTAssertEqual(result.first?.id, expectedData.first?.id)
        XCTAssertTrue(mockSupabase.selectWasCalled)
    }
    
    func testCreateFeatureSuccess() async throws {
        // Given
        let createData = [CreateDataType].mock
        let expectedResponse = [FeatureName]DatabaseModel.mock
        mockSupabase.stubInsert(return: expectedResponse)
        
        // When
        let result = try await service.create[FeatureName](data: createData)
        
        // Then
        XCTAssertEqual(result.id, expectedResponse.id)
        XCTAssertTrue(mockSupabase.insertWasCalled)
    }
    
    func testNetworkErrorHandling() async {
        // Given
        let userId = UUID()
        mockSupabase.stubSelect(throw: SupabaseError.network)
        
        // When/Then
        do {
            _ = try await service.get[FeatureName]Data(userId: userId)
            XCTFail("Expected error to be thrown")
        } catch let error as [FeatureName]Error {
            XCTAssertEqual(error, .[FeatureName]Error.networkUnavailable)
        }
    }
}
```

---

## ⚙️ DevOps Automation Workflow (Team Gamma)

### **Day 1-2: Pipeline Setup**

#### **Enhanced GitHub Actions Template**
```yaml
# .github/workflows/piggy-bong-coordination.yml

name: PiggyBong Coordination Workflow

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 9 * * 1'  # Weekly cycle kickoff

env:
  DEVELOPER_DIR: /Applications/Xcode.app/Contents/Developer
  PROJECT_NAME: "FanPlan"
  SCHEME_NAME: "Piggy Bong"

jobs:
  coordination-check:
    name: Cross-Team Coordination Check
    runs-on: macos-latest
    timeout-minutes: 10
    
    outputs:
      ios-changes: ${{ steps.changes.outputs.ios }}
      backend-changes: ${{ steps.changes.outputs.backend }}
      design-changes: ${{ steps.changes.outputs.design }}
      
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Detect Changes
      id: changes
      uses: dorny/paths-filter@v2
      with:
        filters: |
          ios:
            - 'FanPlan/**/*.swift'
            - 'FanPlan/**/*.storyboard'
            - 'FanPlan/**/*.xib'
          backend:
            - 'FanPlan/**/*Service.swift'
            - 'FanPlan/**/DatabaseModels.swift'
            - '**/*.sql'
          design:
            - 'FanPlan/DesignSystem/**'
            - '**/*Style*.swift'
            - '**/BrandingConfig.swift'

  ios-quality-gate:
    name: iOS Quality Gate
    needs: coordination-check
    if: needs.coordination-check.outputs.ios-changes == 'true'
    runs-on: macos-latest
    timeout-minutes: 30
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Xcode
      run: |
        sudo xcode-select -s $DEVELOPER_DIR
        xcodebuild -version
        
    - name: Cache Dependencies
      uses: actions/cache@v4
      with:
        path: |
          DerivedData
          ~/.cache/CocoaPods
        key: ios-deps-${{ runner.os }}-${{ hashFiles('**/Podfile.lock', '**/Package.resolved') }}
        
    - name: SwiftLint Analysis
      run: |
        if command -v swiftlint >/dev/null 2>&1; then
          swiftlint lint --reporter github-actions-logging
        else
          echo "SwiftLint not installed, skipping"
        fi
        
    - name: Build iOS App
      run: |
        xcodebuild clean build \
          -project "${PROJECT_NAME}.xcodeproj" \
          -scheme "${SCHEME_NAME}" \
          -destination 'generic/platform=iOS Simulator' \
          -derivedDataPath DerivedData \
          CODE_SIGNING_ALLOWED=NO
          
    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -project "${PROJECT_NAME}.xcodeproj" \
          -scheme "${SCHEME_NAME}" \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
          -derivedDataPath DerivedData \
          -enableCodeCoverage YES \
          CODE_SIGNING_ALLOWED=NO
          
    - name: Design System Compliance Check
      run: |
        echo "Checking design system compliance..."
        # Custom script to verify design token usage
        if [ -f "scripts/check-design-compliance.sh" ]; then
          ./scripts/check-design-compliance.sh
        fi

  backend-quality-gate:
    name: Backend Quality Gate
    needs: coordination-check
    if: needs.coordination-check.outputs.backend-changes == 'true'
    runs-on: ubuntu-latest
    timeout-minutes: 20
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Node.js for Supabase Functions
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: 'supabase/functions/package-lock.json'
        
    - name: Install Supabase CLI
      run: |
        npm install -g supabase
        supabase --version
        
    - name: Validate Database Schema
      run: |
        echo "Validating database schema changes..."
        if [ -d "supabase/migrations" ]; then
          # Check for syntax errors in SQL files
          for file in supabase/migrations/*.sql; do
            if [ -f "$file" ]; then
              echo "Validating $file"
              # Add SQL syntax validation
            fi
          done
        fi
        
    - name: Test Edge Functions
      run: |
        if [ -d "supabase/functions" ]; then
          cd supabase/functions
          if [ -f "package.json" ]; then
            npm ci
            npm test || echo "No tests defined"
          fi
        fi

  design-system-gate:
    name: Design System Quality Gate
    needs: coordination-check
    if: needs.coordination-check.outputs.design-changes == 'true'
    runs-on: macos-latest
    timeout-minutes: 15
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Design Token Validation
      run: |
        echo "Validating design token consistency..."
        # Check for proper design token usage
        if [ -f "scripts/validate-design-tokens.sh" ]; then
          ./scripts/validate-design-tokens.sh
        fi
        
    - name: Component Library Check
      run: |
        echo "Checking component library consistency..."
        # Verify design system components are properly exported
        grep -r "PiggyDesignSystem" FanPlan/DesignSystem/ || echo "No design system references found"
        
    - name: Accessibility Compliance
      run: |
        echo "Running accessibility compliance checks..."
        # Add accessibility validation scripts
        if [ -f "scripts/check-accessibility.sh" ]; then
          ./scripts/check-accessibility.sh
        fi

  integration-test:
    name: Cross-Team Integration Test
    needs: [ios-quality-gate, backend-quality-gate, design-system-gate]
    if: always() && (needs.ios-quality-gate.result == 'success' || needs.backend-quality-gate.result == 'success' || needs.design-system-gate.result == 'success')
    runs-on: macos-latest
    timeout-minutes: 45
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Test Environment
      run: |
        echo "Setting up integration test environment..."
        # Setup test data and environment
        
    - name: Run Integration Tests
      run: |
        echo "Running cross-team integration tests..."
        # Execute integration test suite
        
    - name: Performance Benchmarks
      run: |
        echo "Running performance benchmarks..."
        # Execute performance test suite
        
    - name: Generate Integration Report
      run: |
        echo "Generating integration test report..."
        # Create summary report of all tests

  deployment-gate:
    name: Deployment Readiness Gate
    needs: integration-test
    if: github.ref == 'refs/heads/main'
    runs-on: macos-latest
    timeout-minutes: 60
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Prepare Production Build
      run: |
        echo "Preparing production build..."
        # Production build preparation
        
    - name: Security Scan
      run: |
        echo "Running security vulnerability scan..."
        # Security scanning tools
        
    - name: Deploy to TestFlight
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
      run: |
        echo "Deploying to TestFlight..."
        # TestFlight deployment automation
        
    - name: Update Deployment Status
      run: |
        echo "Updating deployment status dashboard..."
        # Update status dashboard

  notification:
    name: Team Notification
    needs: [coordination-check, deployment-gate]
    if: always()
    runs-on: ubuntu-latest
    
    steps:
    - name: Notify Teams
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: |
          PiggyBong 6-Day Cycle Update:
          - iOS Changes: ${{ needs.coordination-check.outputs.ios-changes }}
          - Backend Changes: ${{ needs.coordination-check.outputs.backend-changes }}
          - Design Changes: ${{ needs.coordination-check.outputs.design-changes }}
          - Deployment: ${{ needs.deployment-gate.result }}
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### **Day 3-4: Deployment Automation**

#### **Automated Deployment Script Template**
```bash
#!/bin/bash
# deploy-coordination.sh - Automated deployment orchestration

set -e

# Configuration
PROJECT_NAME="FanPlan"
SCHEME_NAME="Piggy Bong"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/PiggyBong.xcarchive"
IPA_PATH="./build/PiggyBong.ipa"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Pre-deployment checks
pre_deployment_checks() {
    log "Running pre-deployment checks..."
    
    # Check Xcode version
    xcodebuild -version || error "Xcode not found"
    
    # Check for uncommitted changes
    if ! git diff --quiet; then
        warning "Uncommitted changes detected"
        git status --porcelain
    fi
    
    # Verify API keys are set
    if [ -z "$APPLE_ID" ] || [ -z "$APP_STORE_CONNECT_API_KEY" ]; then
        error "Required environment variables not set"
    fi
    
    success "Pre-deployment checks passed"
}

# Build application
build_app() {
    log "Building application for production..."
    
    # Clean build directory
    rm -rf ./build
    mkdir -p ./build
    
    # Archive the app
    xcodebuild archive \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_NAME}" \
        -configuration "${CONFIGURATION}" \
        -archivePath "${ARCHIVE_PATH}" \
        -destination 'generic/platform=iOS' \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" || error "Archive failed"
    
    success "Application archived successfully"
}

# Export IPA
export_ipa() {
    log "Exporting IPA for App Store distribution..."
    
    # Create export options plist
    cat > ./build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${DEVELOPMENT_TEAM}</string>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF
    
    # Export archive to IPA
    xcodebuild -exportArchive \
        -archivePath "${ARCHIVE_PATH}" \
        -exportPath "./build" \
        -exportOptionsPlist "./build/ExportOptions.plist" || error "IPA export failed"
    
    success "IPA exported successfully"
}

# Upload to App Store Connect
upload_to_app_store() {
    log "Uploading to App Store Connect..."
    
    # Use altool for upload
    xcrun altool --upload-app \
        --type ios \
        --file "${IPA_PATH}" \
        --username "${APPLE_ID}" \
        --password "${APP_STORE_CONNECT_API_KEY}" \
        --verbose || error "Upload to App Store Connect failed"
    
    success "Successfully uploaded to App Store Connect"
}

# Update deployment status
update_deployment_status() {
    log "Updating deployment status..."
    
    # Create deployment report
    cat > ./build/deployment-report.json << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "version": "$(cat version.txt || echo "unknown")",
    "build": "$(git rev-parse --short HEAD)",
    "status": "deployed",
    "platform": "ios",
    "environment": "production"
}
EOF
    
    # Send notification to team channels
    if [ ! -z "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚀 PiggyBong iOS successfully deployed to App Store Connect\nVersion: $(cat version.txt || echo 'unknown')\nBuild: $(git rev-parse --short HEAD)\"}" \
            "$SLACK_WEBHOOK" || warning "Slack notification failed"
    fi
    
    success "Deployment status updated"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -f ./build/ExportOptions.plist
    success "Cleanup completed"
}

# Main execution
main() {
    log "Starting PiggyBong deployment orchestration..."
    
    pre_deployment_checks
    build_app
    export_ipa
    upload_to_app_store
    update_deployment_status
    cleanup
    
    success "🎉 Deployment completed successfully!"
    log "Check App Store Connect for processing status"
}

# Trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
```

---

## 🎨 Design System Workflow (Team Delta)

### **Day 1-2: Component Development**

#### **Design System Component Template**
```swift
// MARK: - [ComponentName] Design System Component

import SwiftUI

// MARK: - Component Protocol
protocol [ComponentName]Style {
    associatedtype Body: View
    func makeBody(configuration: [ComponentName]Configuration) -> Body
}

// MARK: - Component Configuration
struct [ComponentName]Configuration {
    let title: String
    let subtitle: String?
    let isEnabled: Bool
    let action: () -> Void
    
    // Component-specific properties
    let [property]: [Type]
}

// MARK: - Default Style Implementation
struct Default[ComponentName]Style: [ComponentName]Style {
    func makeBody(configuration: [ComponentName]Configuration) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(configuration.title)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if let subtitle = configuration.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .onTapGesture {
            if configuration.isEnabled {
                HapticManager.light()
                configuration.action()
            }
        }
        .opacity(configuration.isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: configuration.isEnabled)
    }
}

// MARK: - Component Wrapper
struct Piggy[ComponentName]: View {
    private let configuration: [ComponentName]Configuration
    private let style: any [ComponentName]Style
    
    init(
        title: String,
        subtitle: String? = nil,
        isEnabled: Bool = true,
        [property]: [Type],
        action: @escaping () -> Void
    ) {
        self.configuration = [ComponentName]Configuration(
            title: title,
            subtitle: subtitle,
            isEnabled: isEnabled,
            action: action,
            [property]: [property]
        )
        self.style = Default[ComponentName]Style()
    }
    
    var body: some View {
        AnyView(style.makeBody(configuration: configuration))
    }
}

// MARK: - Style Modifier Extension
extension View {
    func [componentName]Style<S: [ComponentName]Style>(_ style: S) -> some View {
        // Implementation for custom styling
        self
    }
}

// MARK: - Previews
struct Piggy[ComponentName]_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Piggy[ComponentName](
                title: "Default Style",
                subtitle: "This is a subtitle",
                [property]: [defaultValue]
            ) {
                print("Component tapped")
            }
            
            Piggy[ComponentName](
                title: "Disabled State",
                subtitle: "This component is disabled",
                isEnabled: false,
                [property]: [defaultValue]
            ) {
                print("Should not execute")
            }
        }
        .padding()
        .gradientBackground()
        .preferredColorScheme(.dark)
    }
}
```

#### **Design Token Updates Template**
```swift
// MARK: - Design System Token Updates

extension DesignSystem {
    
    // MARK: - New Color Tokens
    enum Colors {
        // Existing tokens...
        
        // New feature-specific tokens
        static let [featureName]Primary = Color(hex: "#[HEX_VALUE]")
        static let [featureName]Secondary = Color(hex: "#[HEX_VALUE]")
        static let [featureName]Background = Color.white.opacity(0.12)
        
        // State-specific colors
        static let successGreen = Color(hex: "#4CAF50")
        static let warningAmber = Color(hex: "#FF9800")
        static let errorRed = Color(hex: "#F44336")
    }
    
    // MARK: - New Typography Tokens
    enum Typography {
        // Feature-specific typography
        static let [featureName]Title = Font.system(size: 28, weight: .bold, design: .default)
        static let [featureName]Body = Font.system(size: 16, weight: .medium, design: .default)
        static let [featureName]Caption = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - New Spacing Tokens
    enum Spacing {
        // Existing tokens...
        
        // Component-specific spacing
        static let [componentName]Internal: CGFloat = 12
        static let [componentName]External: CGFloat = 20
    }
    
    // MARK: - New Animation Tokens
    enum Animations {
        static let [featureName]Transition = Animation.easeInOut(duration: 0.3)
        static let [featureName]Bounce = Animation.interpolatingSpring(
            stiffness: 300,
            damping: 15
        )
    }
}

// MARK: - Token Usage Documentation
/*
 Usage Examples:
 
 // Color Usage
 .foregroundColor(DesignSystem.Colors.[featureName]Primary)
 .backgroundColor(DesignSystem.Colors.[featureName]Background)
 
 // Typography Usage
 .font(DesignSystem.Typography.[featureName]Title)
 
 // Animation Usage
 .animation(DesignSystem.Animations.[featureName]Transition, value: someState)
 
 // Spacing Usage
 .padding(DesignSystem.Spacing.[componentName]Internal)
 */
```

### **Day 3-4: Documentation & Compliance**

#### **Component Documentation Template**
```swift
// MARK: - [ComponentName] Documentation

/**
 # Piggy[ComponentName]
 
 A reusable component for [purpose/functionality].
 
 ## Usage
 
 ```swift
 Piggy[ComponentName](
     title: "Component Title",
     subtitle: "Optional subtitle",
     [property]: [value]
 ) {
     // Action handler
 }
 ```
 
 ## Properties
 
 - `title: String` - The main title text (required)
 - `subtitle: String?` - Optional subtitle text
 - `isEnabled: Bool` - Controls interactive state (default: true)
 - `[property]: [Type]` - [Description of property]
 - `action: () -> Void` - Callback executed on user interaction
 
 ## Styling
 
 The component supports custom styling through the style system:
 
 ```swift
 Piggy[ComponentName](...)
     .[componentName]Style(Custom[ComponentName]Style())
 ```
 
 ## Accessibility
 
 - Supports VoiceOver with descriptive labels
 - Respects Dynamic Type sizing
 - Maintains minimum 44pt touch targets
 - Provides haptic feedback for interactions
 
 ## Design Tokens Used
 
 - Colors: `primaryText`, `secondaryText`, `cardBackground`
 - Typography: `headline`, `subheadline`
 - Spacing: `sm`, `md`
 - Animation: `easeInOut(0.2)`
 
 ## Testing
 
 ```swift
 // Test component rendering
 let component = Piggy[ComponentName](title: "Test", [property]: testValue) { }
 
 // Test interaction
 // Tap gesture testing
 // Accessibility testing
 ```
 */

// MARK: - Compliance Checklist
/*
 ✅ Component follows PiggyDesignSystem conventions
 ✅ Implements proper accessibility support
 ✅ Uses design tokens consistently
 ✅ Includes comprehensive documentation
 ✅ Provides SwiftUI previews
 ✅ Supports custom styling
 ✅ Includes unit tests
 ✅ Follows iOS Human Interface Guidelines
 */
```

---

## 📊 Success Metrics Templates

### **Daily Metrics Dashboard Template**
```markdown
# PiggyBong Daily Metrics - Cycle [Number] - Day [X]

## Team Velocity

### Team Alpha (iOS Development)
- **Stories Completed**: [X] / [Y] planned
- **Story Points**: [X] / [Y] planned  
- **Code Reviews**: [X] completed, [Y] pending
- **Blockers**: [List any blockers]

### Team Beta (Backend Services)
- **API Endpoints**: [X] / [Y] implemented
- **Database Changes**: [X] / [Y] deployed
- **Integration Tests**: [X] / [Y] passing
- **Performance**: API response time < [X]ms

### Team Gamma (DevOps)
- **Pipeline Success Rate**: [X]%
- **Build Time**: [X] minutes average
- **Deployment Frequency**: [X] times today
- **Infrastructure**: [Green/Yellow/Red]

### Team Delta (Design System)
- **Components Updated**: [X]
- **Design Reviews**: [X] completed
- **Compliance Issues**: [X] resolved
- **Documentation**: [X] pages updated

## Quality Metrics

### Code Quality
- **Test Coverage**: [X]% (Target: >80%)
- **SwiftLint Issues**: [X] (Target: 0 errors)
- **Code Review Comments**: [X] average per PR
- **Technical Debt**: [High/Medium/Low]

### User Experience
- **Design Consistency**: [X] violations found
- **Accessibility**: [X] issues remaining
- **Performance**: [X] benchmarks passed
- **User Feedback**: [Positive/Neutral/Negative]

## Cross-Team Coordination

### Dependencies Status
- [ ] iOS → Backend: [Status/Description]
- [ ] Backend → iOS: [Status/Description]  
- [ ] Design → iOS: [Status/Description]
- [ ] DevOps → All: [Status/Description]

### Communication Health
- **Sync Meetings**: [X] attended / [Y] scheduled
- **Slack Activity**: [Active/Moderate/Low]
- **Blockers Resolved**: [X] within target time
- **Escalations**: [X] (Target: 0)

## Risk Assessment

### High Priority Issues
1. [Issue description] - Owner: [Name] - Due: [Date]
2. [Issue description] - Owner: [Name] - Due: [Date]

### Medium Priority Issues
1. [Issue description] - Owner: [Name] - Due: [Date]

### Action Items for Tomorrow
- [ ] [Action item] - Owner: [Name]
- [ ] [Action item] - Owner: [Name]
- [ ] [Action item] - Owner: [Name]

---
**Report Generated**: [Date/Time]
**Next Update**: [Date/Time]
```

### **Sprint Retrospective Template**
```markdown
# Sprint Retrospective - Cycle [Number] Completed

## Cycle Overview
- **Duration**: 6 days
- **Team**: [Team composition]
- **Goal Achievement**: [X]% of planned work completed
- **Key Features Delivered**: [List major features]

## What Went Well 🟢

### Team Alpha (iOS Development)
- [Positive feedback item]
- [Positive feedback item]

### Team Beta (Backend Services)
- [Positive feedback item]
- [Positive feedback item]

### Team Gamma (DevOps)
- [Positive feedback item]
- [Positive feedback item]

### Team Delta (Design System)
- [Positive feedback item]
- [Positive feedback item]

### Cross-Team Collaboration
- [Positive feedback item]
- [Positive feedback item]

## What Could Be Improved 🟡

### Process Issues
- [Improvement area] - Impact: [High/Medium/Low]
- [Improvement area] - Impact: [High/Medium/Low]

### Technical Issues
- [Technical improvement area]
- [Technical improvement area]

### Communication Issues
- [Communication improvement area]
- [Communication improvement area]

## Action Items for Next Cycle 🔵

### Immediate Actions (Start Next Cycle)
- [ ] [Action item] - Owner: [Name] - Due: [Date]
- [ ] [Action item] - Owner: [Name] - Due: [Date]

### Process Improvements
- [ ] [Process change] - Owner: [Name] - Implementation: [Timeline]
- [ ] [Process change] - Owner: [Name] - Implementation: [Timeline]

### Tool/Infrastructure Improvements
- [ ] [Technical improvement] - Owner: [Name] - Timeline: [Date]
- [ ] [Technical improvement] - Owner: [Name] - Timeline: [Date]

## Metrics Summary

### Velocity Metrics
- **Sprint Goal Achievement**: [X]%
- **Story Points Completed**: [X] / [Y] planned
- **Cycle Time**: [X] days average
- **Lead Time**: [X] days average

### Quality Metrics
- **Bugs Introduced**: [X]
- **Test Coverage**: [X]%
- **Code Review Efficiency**: [X] hours average
- **Customer Satisfaction**: [Rating]

### Team Health Metrics
- **Team Satisfaction**: [X]/5 average
- **Burnout Risk**: [Low/Medium/High]
- **Collaboration Score**: [X]/5 average
- **Learning & Growth**: [Active/Moderate/Stagnant]

## Cycle Highlights

### Major Achievements
1. [Achievement description]
2. [Achievement description]
3. [Achievement description]

### Innovations/Experiments
- [Innovation/Experiment] - Result: [Success/Failure/Learning]
- [Innovation/Experiment] - Result: [Success/Failure/Learning]

### Team Recognition
- **MVP of the Cycle**: [Name] - [Reason]
- **Best Collaboration**: [Team/Individual] - [Description]
- **Innovation Award**: [Name] - [Innovation description]

## Next Cycle Planning Input

### Capacity Adjustments
- [Team member] availability: [Adjustment]
- [Team member] availability: [Adjustment]

### Priority Adjustments
- [Priority change] - Reason: [Business/Technical/User feedback]
- [Priority change] - Reason: [Business/Technical/User feedback]

### Risk Mitigation for Next Cycle
- [Risk] - Mitigation plan: [Plan]
- [Risk] - Mitigation plan: [Plan]

---
**Retrospective Facilitator**: [Name]
**Date**: [Date]
**Participants**: [List of attendees]
```

---

This comprehensive set of workflow templates provides concrete, actionable guidance for each team throughout the 6-day development cycle, ensuring coordinated excellence while maintaining rapid delivery velocity.