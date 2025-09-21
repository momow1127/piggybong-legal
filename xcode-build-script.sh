#!/bin/bash
# Xcode Build Phase Script
# Add this as a "Run Script Phase" in Xcode before "Compile Sources"

echo "🚀 Pre-Build Analysis Starting..."

# Change to project root
cd "${SRCROOT}"

# Run comprehensive pre-build check
if [ -f "./pre-build-check.sh" ]; then
    ./pre-build-check.sh
    BUILD_CHECK_EXIT=$?
    
    if [ $BUILD_CHECK_EXIT -ne 0 ]; then
        echo "⚠️ Pre-build check returned warnings/errors"
        
        # In Xcode, you can choose to continue or fail
        # For development, we'll warn but continue
        # For CI/CD, you might want to fail the build
        
        if [ "$CONFIGURATION" = "Release" ]; then
            echo "❌ Failing Release build due to code quality issues"
            exit 1
        else
            echo "⚠️ Continuing Debug build with warnings"
        fi
    fi
else
    echo "⚠️ Pre-build check script not found"
fi

# Optional: Run component analysis (less frequent)
if [ "$RUN_COMPONENT_ANALYSIS" = "1" ]; then
    if [ -f "./component-analyzer.sh" ]; then
        echo "🧩 Running component analysis..."
        ./component-analyzer.sh
    fi
fi

echo "✅ Pre-build analysis complete"