#!/bin/bash

# PiggyBong Test Runner Script
# Usage: ./scripts/run-tests.sh [test-type] [options]

set -e

# Configuration
PROJECT_NAME="FanPlan"
SCHEME_NAME="Piggy Bong"
IOS_SIMULATOR_DEVICE="iPhone 16 Pro"
IOS_SIMULATOR_OS="latest"
DERIVED_DATA_PATH="./DerivedData"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if xcodebuild is available
check_xcodebuild() {
    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild could not be found. Please install Xcode."
        exit 1
    fi
}

# Check if xcpretty is available
check_xcpretty() {
    if ! command -v xcpretty &> /dev/null; then
        print_warning "xcpretty not found. Installing..."
        gem install xcpretty
    fi
}

# Get available simulators
list_simulators() {
    print_info "Available iOS Simulators:"
    xcrun simctl list devices iOS | grep -E "iPhone|iPad" | grep -v "unavailable"
}

# Clean derived data
clean_derived_data() {
    print_info "Cleaning derived data..."
    rm -rf "$DERIVED_DATA_PATH"
    rm -rf ~/Library/Developer/Xcode/DerivedData/"$PROJECT_NAME"-*
}

# Build for testing
build_for_testing() {
    print_header "Building for Testing"
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE,OS=$IOS_SIMULATOR_OS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build-for-testing \
        | xcpretty --color
    
    if [ $? -eq 0 ]; then
        print_success "Build for testing completed successfully"
    else
        print_error "Build for testing failed"
        exit 1
    fi
}

# Run unit tests
run_unit_tests() {
    print_header "Running Unit Tests"
    
    export RUNNING_UNIT_TESTS=true
    export USE_MOCK_DATA=true
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE,OS=$IOS_SIMULATOR_OS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing FanPlanTests/AuthenticationServiceTests \
        -only-testing FanPlanTests/SupabaseServiceTests \
        -only-testing FanPlanTests/RevenueCatManagerTests \
        test-without-building \
        | xcpretty --color --report junit --output unit-test-results.xml
    
    if [ $? -eq 0 ]; then
        print_success "Unit tests passed"
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Run integration tests
run_integration_tests() {
    print_header "Running Integration Tests"
    
    export RUNNING_INTEGRATION_TESTS=true
    
    # Check if test credentials are available
    if [ -z "$TEST_SUPABASE_URL" ]; then
        print_warning "TEST_SUPABASE_URL not set. Some integration tests may be skipped."
    fi
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE,OS=$IOS_SIMULATOR_OS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing FanPlanTests/SupabaseIntegrationTests \
        -only-testing FanPlanTests/RevenueCatIntegrationTests \
        test-without-building \
        | xcpretty --color --report junit --output integration-test-results.xml
    
    if [ $? -eq 0 ]; then
        print_success "Integration tests passed"
    else
        print_error "Integration tests failed"
        return 1
    fi
}

# Run UI tests
run_ui_tests() {
    print_header "Running UI Tests"
    
    export RUNNING_UI_TESTS=true
    export UI_TEST_MOCK_DATA=true
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE,OS=$IOS_SIMULATOR_OS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing FanPlanUITests \
        test-without-building \
        | xcpretty --color --report junit --output ui-test-results.xml
    
    if [ $? -eq 0 ]; then
        print_success "UI tests passed"
    else
        print_error "UI tests failed"
        return 1
    fi
}

# Run performance tests
run_performance_tests() {
    print_header "Running Performance Tests"
    
    export RUNNING_PERFORMANCE_TESTS=true
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE,OS=$IOS_SIMULATOR_OS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing FanPlanTests/PerformanceTests \
        test-without-building \
        | xcpretty --color --report junit --output performance-test-results.xml
    
    if [ $? -eq 0 ]; then
        print_success "Performance tests completed"
    else
        print_error "Performance tests failed"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    print_header "Running All Tests"
    
    local failed_tests=()
    
    if ! run_unit_tests; then
        failed_tests+=("Unit Tests")
    fi
    
    if ! run_integration_tests; then
        failed_tests+=("Integration Tests")
    fi
    
    if ! run_ui_tests; then
        failed_tests+=("UI Tests")
    fi
    
    if ! run_performance_tests; then
        failed_tests+=("Performance Tests")
    fi
    
    if [ ${#failed_tests[@]} -eq 0 ]; then
        print_success "All tests passed!"
    else
        print_error "Failed test suites: ${failed_tests[*]}"
        return 1
    fi
}

# Run tests with coverage
run_tests_with_coverage() {
    print_header "Running Tests with Code Coverage"
    
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE,OS=$IOS_SIMULATOR_OS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -enableCodeCoverage YES \
        test \
        | xcpretty --color
    
    if [ $? -eq 0 ]; then
        print_success "Tests with coverage completed"
        
        # Generate coverage report
        print_info "Generating coverage report..."
        xcrun xccov view "$DERIVED_DATA_PATH"/Logs/Test/*.xcresult/*/action_TestSummaries.plist --report --only-targets
    else
        print_error "Tests with coverage failed"
        return 1
    fi
}

# Run static analysis
run_static_analysis() {
    print_header "Running Static Analysis"
    
    # Run SwiftLint if available
    if command -v swiftlint &> /dev/null; then
        print_info "Running SwiftLint..."
        swiftlint --reporter xcode
    else
        print_warning "SwiftLint not found. Install with: brew install swiftlint"
    fi
    
    # Run Xcode static analyzer
    print_info "Running Xcode Static Analyzer..."
    xcodebuild \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$IOS_SIMULATOR_DEVICE,OS=$IOS_SIMULATOR_OS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        analyze \
        | xcpretty --color
    
    if [ $? -eq 0 ]; then
        print_success "Static analysis completed"
    else
        print_error "Static analysis found issues"
        return 1
    fi
}

# Generate test report
generate_test_report() {
    print_header "Generating Test Report"
    
    local report_file="test-report.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>PiggyBong Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        .test-section { margin: 20px 0; padding: 10px; border-left: 3px solid #ccc; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>PiggyBong Test Report</h1>
        <div class="timestamp">Generated: $(date)</div>
    </div>
    
    <div class="test-section">
        <h2>Test Results Summary</h2>
EOF

    # Check for test result files and add status
    if [ -f "unit-test-results.xml" ]; then
        echo '        <p class="success">✅ Unit Tests: Passed</p>' >> "$report_file"
    else
        echo '        <p class="error">❌ Unit Tests: Failed or Not Run</p>' >> "$report_file"
    fi
    
    if [ -f "integration-test-results.xml" ]; then
        echo '        <p class="success">✅ Integration Tests: Passed</p>' >> "$report_file"
    else
        echo '        <p class="error">❌ Integration Tests: Failed or Not Run</p>' >> "$report_file"
    fi
    
    if [ -f "ui-test-results.xml" ]; then
        echo '        <p class="success">✅ UI Tests: Passed</p>' >> "$report_file"
    else
        echo '        <p class="error">❌ UI Tests: Failed or Not Run</p>' >> "$report_file"
    fi
    
    if [ -f "performance-test-results.xml" ]; then
        echo '        <p class="success">✅ Performance Tests: Completed</p>' >> "$report_file"
    else
        echo '        <p class="warning">⚠️ Performance Tests: Skipped or Failed</p>' >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF
    </div>
    
    <div class="test-section">
        <h2>Build Information</h2>
        <p><strong>Scheme:</strong> $SCHEME_NAME</p>
        <p><strong>Simulator:</strong> $IOS_SIMULATOR_DEVICE ($IOS_SIMULATOR_OS)</p>
        <p><strong>Derived Data:</strong> $DERIVED_DATA_PATH</p>
    </div>
</body>
</html>
EOF

    print_success "Test report generated: $report_file"
    
    # Open report if on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$report_file"
    fi
}

# Setup test environment
setup_test_environment() {
    print_header "Setting Up Test Environment"
    
    # Create .env file for local testing if it doesn't exist
    if [ ! -f ".env.test" ]; then
        cat > .env.test << EOF
# Test Environment Variables
RUNNING_UNIT_TESTS=false
RUNNING_INTEGRATION_TESTS=false
RUNNING_UI_TESTS=false
RUNNING_PERFORMANCE_TESTS=false
USE_MOCK_DATA=true

# Test Database URLs (replace with your test instances)
TEST_SUPABASE_URL=https://your-test-project.supabase.co
TEST_SUPABASE_ANON_KEY=your-test-anon-key
TEST_REVENUECAT_API_KEY=your-test-revenuecat-key

# Mock Services
MOCK_SUPABASE_SERVICE=false
MOCK_REVENUECAT_SERVICE=false
EOF
        print_info "Created .env.test file. Please update with your test credentials."
    fi
    
    # Source environment variables if file exists
    if [ -f ".env.test" ]; then
        export $(cat .env.test | grep -v '^#' | xargs)
        print_success "Loaded test environment variables"
    fi
}

# Show help
show_help() {
    echo "PiggyBong Test Runner"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  unit                 Run unit tests only"
    echo "  integration         Run integration tests only"
    echo "  ui                  Run UI tests only"
    echo "  performance         Run performance tests only"
    echo "  all                 Run all tests (default)"
    echo "  coverage            Run all tests with code coverage"
    echo "  analyze             Run static analysis"
    echo "  clean               Clean derived data"
    echo "  build               Build for testing only"
    echo "  setup               Setup test environment"
    echo "  report              Generate test report"
    echo "  simulators          List available simulators"
    echo "  help                Show this help message"
    echo ""
    echo "Options:"
    echo "  --device DEVICE     Use specific simulator device (default: $IOS_SIMULATOR_DEVICE)"
    echo "  --os OS             Use specific iOS version (default: $IOS_SIMULATOR_OS)"
    echo "  --clean             Clean before running tests"
    echo "  --verbose           Verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 unit"
    echo "  $0 all --clean"
    echo "  $0 ui --device 'iPhone 15 Pro'"
    echo "  $0 coverage"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --device)
                IOS_SIMULATOR_DEVICE="$2"
                shift 2
                ;;
            --os)
                IOS_SIMULATOR_OS="$2"
                shift 2
                ;;
            --clean)
                CLEAN_BEFORE_TEST=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                COMMAND="$1"
                shift
                ;;
        esac
    done
}

# Main execution
main() {
    local command="${1:-all}"
    shift 2>/dev/null || true
    
    parse_arguments "$@"
    
    # Check prerequisites
    check_xcodebuild
    check_xcpretty
    
    # Setup test environment
    setup_test_environment
    
    # Clean if requested
    if [ "$CLEAN_BEFORE_TEST" = true ]; then
        clean_derived_data
    fi
    
    # Execute command
    case $command in
        unit)
            build_for_testing
            run_unit_tests
            ;;
        integration)
            build_for_testing
            run_integration_tests
            ;;
        ui)
            build_for_testing
            run_ui_tests
            ;;
        performance)
            build_for_testing
            run_performance_tests
            ;;
        all)
            build_for_testing
            run_all_tests
            ;;
        coverage)
            run_tests_with_coverage
            ;;
        analyze)
            run_static_analysis
            ;;
        clean)
            clean_derived_data
            ;;
        build)
            build_for_testing
            ;;
        setup)
            setup_test_environment
            ;;
        report)
            generate_test_report
            ;;
        simulators)
            list_simulators
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"