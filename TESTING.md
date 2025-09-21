# PiggyBong iOS App - Testing Guide

This document provides comprehensive testing strategies and guidelines for the PiggyBong iOS app to ensure production readiness and prevent regression issues.

## Table of Contents

1. [Overview](#overview)
2. [Testing Architecture](#testing-architecture)
3. [Test Types](#test-types)
4. [Running Tests](#running-tests)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Test Configuration](#test-configuration)
7. [Writing Tests](#writing-tests)
8. [Performance Testing](#performance-testing)
9. [Troubleshooting](#troubleshooting)

## Overview

The PiggyBong testing suite includes comprehensive unit tests, integration tests, UI tests, and performance tests designed to ensure app reliability and catch regressions early in the development cycle.

### Test Coverage Goals

- **Unit Tests**: 80%+ code coverage for business logic
- **Integration Tests**: Critical user flows and third-party service integration
- **UI Tests**: End-to-end user scenarios
- **Performance Tests**: Response times and resource usage benchmarks

## Testing Architecture

### Test Structure

```
FanPlanTests/                    # Unit & Integration Tests
├── Unit Tests/
│   ├── AuthenticationServiceTests.swift
│   ├── SupabaseServiceTests.swift
│   ├── RevenueCatManagerTests.swift
│   └── PerformanceTests.swift
├── Integration Tests/
│   ├── SupabaseIntegrationTests.swift
│   └── RevenueCatIntegrationTests.swift
└── TestConfiguration.swift     # Test utilities and configuration

FanPlanUITests/                  # UI Tests
├── OnboardingUITests.swift
├── DashboardUITests.swift
└── PaywallUITests.swift
```

### Test Configuration

The app uses environment-based test configuration to handle different testing scenarios:

- **Mock Data**: Used in unit tests and CI environments
- **Test Database**: Separate database for integration tests
- **UI Test Mode**: Special app state for UI testing

## Test Types

### 1. Unit Tests

**Purpose**: Test individual components in isolation
**Target**: Business logic, data models, utilities
**Speed**: Fast (< 100ms per test)

**Key Test Files**:
- `AuthenticationServiceTests.swift` - Authentication logic and validation
- `SupabaseServiceTests.swift` - Database operations and API calls  
- `RevenueCatManagerTests.swift` - Subscription management

**Example**:
```swift
func testEmailValidation() {
    XCTAssertNil(authService.validateEmail("valid@email.com"))
    XCTAssertNotNil(authService.validateEmail("invalid-email"))
}
```

### 2. Integration Tests

**Purpose**: Test component interaction and third-party services
**Target**: Database operations, API integration, service coordination
**Speed**: Medium (< 5s per test)

**Key Test Files**:
- `SupabaseIntegrationTests.swift` - End-to-end database workflows
- `RevenueCatIntegrationTests.swift` - Subscription flow integration

**Example**:
```swift
func testCompleteUserOnboardingFlow() async throws {
    let userId = try await supabaseService.createUser(...)
    let artists = try await supabaseService.getArtists()
    // ... complete workflow test
}
```

### 3. UI Tests

**Purpose**: Test user interface and user flows
**Target**: Critical user journeys, screen interactions
**Speed**: Slow (< 30s per test)

**Key Test Files**:
- `OnboardingUITests.swift` - First-time user experience
- `DashboardUITests.swift` - Main app functionality
- `PaywallUITests.swift` - Subscription purchase flow

**Example**:
```swift
func testOnboardingFlow() throws {
    app.buttons["Get Started"].tap()
    let nameField = app.textFields["Enter your name"]
    nameField.tap()
    nameField.typeText("Test User")
    app.buttons["Continue"].tap()
    // ... continue flow verification
}
```

### 4. Performance Tests

**Purpose**: Benchmark performance and resource usage
**Target**: Database queries, network operations, memory usage
**Speed**: Variable (depends on operations)

**Key Areas**:
- Database operation performance
- Network request timing
- Memory usage during data loading
- CPU usage for intensive operations

## Running Tests

### Local Development

Use the provided test runner script:

```bash
# Run all tests
./scripts/run-tests.sh all

# Run specific test types
./scripts/run-tests.sh unit
./scripts/run-tests.sh integration
./scripts/run-tests.sh ui
./scripts/run-tests.sh performance

# Run with options
./scripts/run-tests.sh all --clean --device "iPhone 15 Pro"

# Run tests with coverage
./scripts/run-tests.sh coverage
```

### Xcode

1. **Unit Tests**: ⌘U or Product → Test
2. **Specific Test**: Click the diamond icon next to test method
3. **Test Class**: Click the diamond icon next to test class
4. **Performance Tests**: Use Test Navigator to run specific performance tests

### Command Line

```bash
# Unit tests only
xcodebuild -scheme "Piggy Bong" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing FanPlanTests/AuthenticationServiceTests \
    test

# All tests with coverage
xcodebuild -scheme "Piggy Bong" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -enableCodeCoverage YES \
    test
```

## CI/CD Pipeline

### GitHub Actions Workflow

The app uses a comprehensive GitHub Actions workflow (`.github/workflows/ios-ci.yml`) that runs:

1. **Unit Tests** - Fast feedback on business logic
2. **Integration Tests** - Database and service integration
3. **UI Tests** - Critical user flow validation
4. **Performance Tests** - Performance regression detection
5. **Code Coverage** - Coverage reporting
6. **Static Analysis** - Code quality checks
7. **Build Archive** - Production build verification

### Pipeline Triggers

- **Push to main/develop** - Full test suite
- **Pull Requests** - Full test suite with results posted to PR
- **Scheduled** - Daily test runs at 6 AM UTC
- **Manual** - On-demand pipeline execution

### Environment Variables

```bash
# CI Environment Detection
CI=true
GITHUB_ACTIONS=true

# Test Configuration
RUNNING_UNIT_TESTS=true
USE_MOCK_DATA=true
TEST_SUPABASE_URL=https://test.supabase.co
TEST_SUPABASE_ANON_KEY=test-key
```

## Test Configuration

### Environment Setup

The test suite automatically detects and configures based on the environment:

```swift
class TestConfiguration {
    var isRunningInCI: Bool {
        return ProcessInfo.processInfo.environment["CI"] == "true"
    }
    
    var shouldUseMockData: Bool {
        return ProcessInfo.processInfo.environment["USE_MOCK_DATA"] == "true" || isRunningInCI
    }
}
```

### Mock Data

For consistent testing, the app provides comprehensive mock data:

```swift
// Generate test data
let mockUser = TestUtilities.generateMockUser(name: "Test User")
let mockArtist = TestUtilities.generateMockArtist(name: "Test Artist")
let mockGoal = TestUtilities.generateMockGoal(name: "Concert Tickets")
```

### Test Database

Integration tests use a separate test database to avoid affecting production data:

- **Local**: Configure test database URL in `.env.test`
- **CI**: Uses GitHub Secrets for test database credentials

## Writing Tests

### Best Practices

1. **Test Structure**: Use Arrange-Act-Assert pattern
2. **Naming**: Use descriptive test names that explain behavior
3. **Independence**: Tests should not depend on each other
4. **Speed**: Keep unit tests fast, use mocks for external dependencies
5. **Assertions**: One logical assertion per test
6. **Error Cases**: Test both success and failure scenarios

### Test Templates

**Unit Test Template**:
```swift
func testFeatureBehavior() {
    // Arrange
    let input = "test data"
    
    // Act
    let result = service.processInput(input)
    
    // Assert
    XCTAssertEqual(result, expectedOutput)
}
```

**Async Test Template**:
```swift
func testAsyncOperation() async throws {
    // Arrange
    let expectation = XCTestExpectation(description: "Async operation")
    
    // Act
    let result = try await service.performAsyncOperation()
    
    // Assert
    XCTAssertNotNil(result)
    expectation.fulfill()
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

**UI Test Template**:
```swift
func testUserInterface() throws {
    // Arrange
    app.launch()
    
    // Act
    app.buttons["Action Button"].tap()
    
    // Assert
    XCTAssertTrue(app.staticTexts["Expected Result"].waitForExistence(timeout: 5.0))
}
```

### Custom Assertions

The test suite provides custom assertions for common patterns:

```swift
// Async assertions
await XCTAssertAsyncNoThrow {
    try await service.performOperation()
}

// Accuracy assertions for floating point
XCTAssertEqualWithAccuracy(actualValue, expectedValue, accuracy: 0.01)
```

## Performance Testing

### Metrics

The performance tests measure:

- **Time**: Operation completion time
- **Memory**: Memory usage during operations
- **CPU**: CPU utilization
- **Disk I/O**: Storage operations

### Benchmarks

**Target Performance Standards**:
- Database queries: < 2s
- Authentication operations: < 1s
- UI interactions: < 0.5s
- App launch: < 3s

### Running Performance Tests

```bash
# Run performance tests
./scripts/run-tests.sh performance

# Measure specific operations
measure {
    // Operation to benchmark
}
```

## Troubleshooting

### Common Issues

**Build Failures**:
```bash
# Clean derived data
./scripts/run-tests.sh clean

# Rebuild and test
./scripts/run-tests.sh build
./scripts/run-tests.sh unit
```

**Simulator Issues**:
```bash
# List available simulators
./scripts/run-tests.sh simulators

# Use specific simulator
./scripts/run-tests.sh unit --device "iPhone 15 Pro" --os "17.0"
```

**Network Test Failures**:
- Check test database credentials
- Verify network connectivity
- Use mock data for unreliable connections

**UI Test Timeouts**:
- Increase timeout values in CI environments
- Check for proper app state setup
- Verify element accessibility identifiers

### Debug Commands

```bash
# Verbose test output
./scripts/run-tests.sh unit --verbose

# Generate detailed test report
./scripts/run-tests.sh report

# Check test results
open unit-test-results.xml
```

### Environment Issues

**Missing Dependencies**:
```bash
# Install xcpretty
gem install xcpretty

# Install SwiftLint
brew install swiftlint
```

**Configuration Problems**:
```bash
# Setup test environment
./scripts/run-tests.sh setup

# Check environment variables
env | grep TEST_
```

## Test Maintenance

### Regular Tasks

1. **Weekly**: Review test results and performance trends
2. **Per Release**: Update UI tests for interface changes
3. **Monthly**: Review and update performance benchmarks
4. **Quarterly**: Audit test coverage and add missing tests

### Code Coverage

Maintain minimum coverage standards:
- **Services**: 85%+
- **Models**: 70%+
- **View Models**: 80%+
- **Utilities**: 90%+

### Test Data Management

- Keep mock data updated with schema changes
- Regularly refresh test database with representative data
- Maintain test user accounts for integration testing

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure new code meets coverage requirements
3. Add performance tests for critical operations
4. Update UI tests for interface changes
5. Run full test suite before submitting PR

### Test Review Checklist

- [ ] All tests pass locally
- [ ] Tests cover both success and error cases
- [ ] Performance tests within acceptable limits
- [ ] UI tests use proper accessibility identifiers
- [ ] Mock data represents realistic scenarios
- [ ] Tests are properly documented
- [ ] CI pipeline passes completely

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [UI Testing Documentation](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Performance Testing Guide](https://developer.apple.com/documentation/xctest/performance_tests)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift)