#!/bin/bash
# Pre-Build Duplicate Detection & Component Analysis
# Runs comprehensive checks before Xcode build

echo "🔍 FanPlan Pre-Build Analysis"
echo "============================="

FANPLAN_DIR="FanPlan"
ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check for duplicates with detailed analysis
check_duplicates() {
    local pattern=$1
    local name=$2
    local max_allowed=${3:-1}
    
    echo -e "\n${BLUE}Checking: $name${NC}"
    
    results=$(grep -r "$pattern" $FANPLAN_DIR/ 2>/dev/null)
    count=$(echo "$results" | grep -c . || echo "0")
    
    if [ $count -gt $max_allowed ]; then
        echo -e "❌ ${RED}Multiple $name found ($count instances):${NC}"
        
        # Show each duplicate with line numbers
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                file=$(echo "$line" | cut -d: -f1)
                line_num=$(echo "$line" | cut -d: -f2)
                content=$(echo "$line" | cut -d: -f3-)
                echo -e "   ${YELLOW}$file:$line_num${NC} - $content"
            fi
        done <<< "$results"
        
        ERRORS=$((ERRORS + 1))
        return 1
    elif [ $count -eq 0 ]; then
        echo -e "   ${YELLOW}⚠️  No instances found${NC}"
        return 0
    else
        echo -e "   ✅ ${GREEN}OK ($count instance)${NC}"
        return 0
    fi
}

# Function to detect duplicate SwiftUI components
detect_duplicate_components() {
    echo -e "\n${BLUE}🧩 Analyzing SwiftUI Components${NC}"
    echo "================================"
    
    # Find all struct declarations that implement View
    view_structs=$(grep -r "struct.*: View" $FANPLAN_DIR/ 2>/dev/null | grep -v "Preview")
    
    # Extract component names and check for duplicates (using temp files for compatibility)
    component_names_file=$(mktemp)
    component_files_file=$(mktemp)
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            file=$(echo "$line" | cut -d: -f1)
            struct_declaration=$(echo "$line" | cut -d: -f3-)
            
            # Extract struct name (between "struct " and ":" or "{")
            struct_name=$(echo "$struct_declaration" | sed -n 's/.*struct \([A-Za-z0-9_]*\).*/\1/p')
            
            if [ -n "$struct_name" ]; then
                if grep -q "^$struct_name$" "$component_names_file"; then
                    existing_file=$(grep -A1 "^$struct_name$" "$component_files_file" | tail -1)
                    echo -e "❌ ${RED}Duplicate component: $struct_name${NC}"
                    echo -e "   ${YELLOW}File 1:${NC} $existing_file"
                    echo -e "   ${YELLOW}File 2:${NC} $file"
                    ERRORS=$((ERRORS + 1))
                else
                    echo "$struct_name" >> "$component_names_file"
                    echo "$file" >> "$component_files_file"
                fi
            fi
        fi
    done <<< "$view_structs"
    
    # Cleanup temp files
    rm -f "$component_names_file" "$component_files_file"
}

# Function to detect similar function signatures
detect_similar_functions() {
    echo -e "\n${BLUE}🔧 Analyzing Function Signatures${NC}"
    echo "=================================="
    
    # Common utility function patterns that might be duplicated
    patterns=(
        "func format.*Currency"
        "func.*Haptic"
        "func validate.*"
        "func calculate.*"
        "func safe.*"
    )
    
    for pattern in "${patterns[@]}"; do
        echo -e "\n${BLUE}Checking pattern: $pattern${NC}"
        results=$(grep -r "$pattern" $FANPLAN_DIR/ 2>/dev/null | grep -v "Utils/")
        
        if [ -n "$results" ]; then
            count=$(echo "$results" | grep -c .)
            if [ $count -gt 0 ]; then
                echo -e "   ${YELLOW}⚠️  Found $count potential duplicates (should be in Utils/):${NC}"
                while IFS= read -r line; do
                    if [ -n "$line" ]; then
                        file=$(echo "$line" | cut -d: -f1)
                        line_num=$(echo "$line" | cut -d: -f2)
                        func_name=$(echo "$line" | cut -d: -f3- | sed 's/.*func \([a-zA-Z0-9_]*\).*/\1/')
                        echo -e "     $file:$line_num - ${func_name}"
                    fi
                done <<< "$results"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    done
}

# Function to analyze file sizes and complexity
analyze_file_complexity() {
    echo -e "\n${BLUE}📊 File Size Analysis${NC}"
    echo "====================="
    
    # Find files over warning thresholds
    large_files=$(find $FANPLAN_DIR -name "*.swift" -exec wc -l {} + | sort -nr | head -10)
    
    echo -e "${BLUE}Top 10 largest files:${NC}"
    while IFS= read -r line; do
        if [ -n "$line" ] && [[ $line == *".swift" ]]; then
            lines=$(echo "$line" | awk '{print $1}')
            file=$(echo "$line" | awk '{print $2}')
            
            if [ "$lines" -gt 800 ]; then
                echo -e "   ❌ ${RED}$lines lines - $file (CRITICAL)${NC}"
                ERRORS=$((ERRORS + 1))
            elif [ "$lines" -gt 500 ]; then
                echo -e "   ⚠️  ${YELLOW}$lines lines - $file (WARNING)${NC}"
                WARNINGS=$((WARNINGS + 1))
            elif [ "$lines" -gt 300 ]; then
                echo -e "   ℹ️  ${BLUE}$lines lines - $file (MONITOR)${NC}"
            else
                echo -e "   ✅ ${GREEN}$lines lines - $file${NC}"
            fi
        fi
    done <<< "$large_files"
}

# Function to check for missing documentation
check_documentation() {
    echo -e "\n${BLUE}📚 Documentation Check${NC}"
    echo "======================"
    
    # Check if Utils/README.md is up to date
    if [ -f "$FANPLAN_DIR/Utils/README.md" ]; then
        echo -e "   ✅ ${GREEN}Utils README exists${NC}"
        
        # Check if all utilities are documented
        utils_files=$(find $FANPLAN_DIR/Utils -name "*.swift" | wc -l)
        documented_utils=$(grep -c "##\|###\|File:" $FANPLAN_DIR/Utils/README.md 2>/dev/null || echo "0")
        
        if [ "$documented_utils" -lt "$utils_files" ]; then
            echo -e "   ⚠️  ${YELLOW}Some utilities might not be documented${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "   ❌ ${RED}Utils README missing${NC}"
        ERRORS=$((ERRORS + 1))
    fi
}

# Function to suggest automatic fixes
suggest_fixes() {
    if [ $ERRORS -gt 0 ] || [ $WARNINGS -gt 0 ]; then
        echo -e "\n${BLUE}🛠️  Suggested Fixes${NC}"
        echo "=================="
        
        if [ $ERRORS -gt 0 ]; then
            echo -e "${RED}Critical Issues (Must Fix):${NC}"
            echo "1. Remove duplicate component declarations"
            echo "2. Move duplicate functions to Utils/ folder"
            echo "3. Refactor large files (>800 lines)"
            echo "4. Update Utils/README.md documentation"
        fi
        
        if [ $WARNINGS -gt 0 ]; then
            echo -e "\n${YELLOW}Warnings (Should Fix):${NC}"
            echo "1. Consider moving utility functions to Utils/"
            echo "2. Break down large files (>500 lines)"
            echo "3. Update documentation for new utilities"
        fi
        
        echo -e "\n${BLUE}Quick Commands:${NC}"
        echo "   ./check-duplicates.sh           # Run basic duplicate check"
        echo "   find FanPlan -name '*.swift' -exec wc -l {} + | sort -nr"
        echo "   grep -r 'func format' FanPlan/  # Find formatting functions"
    fi
}

# Main execution
echo "Starting comprehensive pre-build analysis..."

# Run all checks
echo -e "\n${BLUE}1. DUPLICATE UTILITIES CHECK${NC}"
echo "============================"
check_duplicates "struct HapticManager\|class HapticManager" "HapticManager declarations"
check_duplicates "func formatCurrency" "formatCurrency functions"
check_duplicates "struct ScaleButtonStyle" "ScaleButtonStyle declarations"
check_duplicates "enum TransactionType\s*[:{]" "TransactionType enums"
check_duplicates "enum TransactionCategory\s*[:{]" "TransactionCategory enums"
check_duplicates "enum InsightType\s*[:{]" "InsightType enums"

# Component analysis
detect_duplicate_components

# Function analysis
detect_similar_functions

# File size analysis
analyze_file_complexity

# Documentation check
check_documentation

# Summary
echo -e "\n${BLUE}ANALYSIS SUMMARY${NC}"
echo "================"
echo -e "Errors: ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "\n🎉 ${GREEN}All checks passed! Ready to build.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "\n⚠️  ${YELLOW}Build can proceed with warnings.${NC}"
    suggest_fixes
    exit 0
else
    echo -e "\n💥 ${RED}Critical issues found! Build may fail.${NC}"
    suggest_fixes
    
    # Ask if user wants to proceed anyway
    read -p "Continue with build anyway? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "⚠️  ${YELLOW}Proceeding with build despite errors...${NC}"
        exit 0
    else
        echo -e "🛑 ${RED}Build cancelled. Fix issues and try again.${NC}"
        exit 1
    fi
fi