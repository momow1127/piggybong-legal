#!/bin/bash
# Duplicate Detection Script for FanPlan
# Run this before committing code

echo "🔍 FanPlan Duplicate Detection"
echo "=============================="

FANPLAN_DIR="FanPlan"
ERRORS=0

# Function to check for duplicates
check_duplicates() {
    local pattern=$1
    local name=$2
    local max_allowed=${3:-1}
    
    count=$(grep -r "$pattern" $FANPLAN_DIR/ 2>/dev/null | wc -l | tr -d ' ')
    
    if [ $count -gt $max_allowed ]; then
        echo "❌ Multiple $name found ($count instances):"
        grep -r "$pattern" $FANPLAN_DIR/ | sed 's/^/   /'
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ $name: OK ($count instance)"
    fi
}

echo ""
echo "Checking for duplicate utilities..."

# Check for HapticManager duplicates
check_duplicates "struct HapticManager\|class HapticManager" "HapticManager declarations"

# Check for currency formatting functions
check_duplicates "func formatCurrency" "formatCurrency functions"

# Check for duplicate ScaleButtonStyle specifically
check_duplicates "struct ScaleButtonStyle" "ScaleButtonStyle declarations"

# Check for duplicate extensions on common types
check_duplicates "extension String" "String extensions" 3
check_duplicates "extension Color" "Color extensions" 2

# Check for duplicate enum declarations
check_duplicates "enum TransactionType" "TransactionType enums"
check_duplicates "enum TransactionCategory" "TransactionCategory enums" 
check_duplicates "enum InsightType" "InsightType enums"

echo ""
echo "Checking for naming conflicts..."

# Check for similar function names that might be duplicates
similar_functions=(
    "formatPrice"
    "formatMoney" 
    "currencyFormat"
    "lightHaptic"
    "mediumHaptic"
    "heavyHaptic"
)

for func in "${similar_functions[@]}"; do
    count=$(grep -r "func $func\|func ${func}(" $FANPLAN_DIR/ 2>/dev/null | wc -l | tr -d ' ')
    if [ $count -gt 0 ]; then
        echo "⚠️  Similar function '$func' found - check if duplicate of existing utility"
        grep -r "func $func" $FANPLAN_DIR/ | sed 's/^/   /'
    fi
done

echo ""
echo "Summary:"
echo "========"

if [ $ERRORS -eq 0 ]; then
    echo "🎉 No duplicates detected! Code is clean."
    exit 0
else
    echo "💥 Found $ERRORS duplicate issues!"
    echo ""
    echo "🛠️  How to fix:"
    echo "   1. Remove duplicate declarations"
    echo "   2. Use shared utilities from Utils/ folder"
    echo "   3. Check Utils/README.md for available utilities"
    echo "   4. Run this script again to verify fixes"
    exit 1
fi