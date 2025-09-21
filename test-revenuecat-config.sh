#!/bin/bash

echo "🔧 PiggyBong RevenueCat Configuration Test"
echo "========================================"

# Check if .env file exists
if [ -f ".env" ]; then
    echo "✅ .env file found"
    if grep -q "REVENUECAT_API_KEY" .env; then
        echo "✅ REVENUECAT_API_KEY found in .env"
        KEY=$(grep "REVENUECAT_API_KEY" .env | cut -d'=' -f2)
        echo "🔑 API Key: ${KEY:0:15}..."
    else
        echo "❌ REVENUECAT_API_KEY not found in .env"
    fi
else
    echo "❌ .env file not found"
fi

# Check environment variable
if [ ! -z "$REVENUECAT_API_KEY" ]; then
    echo "✅ REVENUECAT_API_KEY environment variable is set"
    echo "🔑 API Key: ${REVENUECAT_API_KEY:0:15}..."
else
    echo "⚠️  REVENUECAT_API_KEY environment variable not set"
fi

# Check Secrets.swift
if [ -f "FanPlan/Secrets.swift" ]; then
    echo "✅ Secrets.swift found"
    if grep -q "appl_aXABVpZnhojTFHMskeYPUsIzXuX" FanPlan/Secrets.swift; then
        echo "✅ Valid development API key configured in Secrets.swift"
    else
        echo "⚠️  Development API key may not be configured in Secrets.swift"
    fi
else
    echo "❌ Secrets.swift not found"
fi

# Check RevenueCatConfig.swift
if [ -f "FanPlan/RevenueCatConfig.swift" ]; then
    echo "✅ RevenueCatConfig.swift found"
else
    echo "❌ RevenueCatConfig.swift not found"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Run: export REVENUECAT_API_KEY=appl_aXABVpZnhojTFHMskeYPUsIzXuX"
echo "2. Or update your Xcode environment variables"
echo "3. Build and run the app to test RevenueCat integration"
echo ""
echo "🔗 Get your production API key from:"
echo "   https://app.revenuecat.com/apps/YOUR_APP/api-keys"