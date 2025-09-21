#!/bin/bash
# Component Similarity Analysis
# Detects similar SwiftUI components that might be duplicates

echo "🧩 Component Similarity Analysis"
echo "================================"

FANPLAN_DIR="FanPlan"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to extract component signatures
extract_component_signature() {
    local file=$1
    local component_name=$2
    
    # Extract the component's body to analyze structure
    awk "
    /struct $component_name.*View/ { in_struct=1; brace_count=0; }
    in_struct && /{/ { brace_count++ }
    in_struct && /}/ { brace_count--; if(brace_count==0) in_struct=0; }
    in_struct { 
        # Extract key elements: @State vars, functions, View properties
        if (/var.*:/ || /@State/ || /@Binding/ || /func /) print \$0
    }
    " "$file" | sed 's/^[[:space:]]*//' | sort
}

# Function to compare component signatures
compare_components() {
    local file1=$1
    local comp1=$2
    local file2=$3
    local comp2=$4
    
    sig1=$(extract_component_signature "$file1" "$comp1")
    sig2=$(extract_component_signature "$file2" "$comp2")
    
    # Calculate similarity (simple line-based comparison)
    common_lines=$(comm -12 <(echo "$sig1") <(echo "$sig2") | wc -l)
    total_lines1=$(echo "$sig1" | wc -l)
    total_lines2=$(echo "$sig2" | wc -l)
    
    if [ "$total_lines1" -eq 0 ] || [ "$total_lines2" -eq 0 ]; then
        echo "0"
        return
    fi
    
    avg_lines=$(( (total_lines1 + total_lines2) / 2 ))
    if [ "$avg_lines" -eq 0 ]; then
        echo "0"
        return
    fi
    
    similarity=$(( (common_lines * 100) / avg_lines ))
    echo "$similarity"
}

# Function to find potentially duplicate components
find_duplicate_components() {
    echo -e "${BLUE}Scanning for similar components...${NC}"
    
    # Get all SwiftUI components
    components=$(grep -r "struct.*: View" $FANPLAN_DIR/ 2>/dev/null | grep -v Preview | grep -v "//")
    
    # Convert to arrays for comparison
    declare -a files
    declare -a names
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            file=$(echo "$line" | cut -d: -f1)
            struct_line=$(echo "$line" | cut -d: -f3-)
            name=$(echo "$struct_line" | sed -n 's/.*struct \([A-Za-z0-9_]*\).*/\1/p')
            
            if [ -n "$name" ]; then
                files+=("$file")
                names+=("$name")
            fi
        fi
    done <<< "$components"
    
    # Compare each component with every other component
    for ((i=0; i<${#files[@]}; i++)); do
        for ((j=i+1; j<${#files[@]}; j++)); do
            file1="${files[$i]}"
            name1="${names[$i]}"
            file2="${files[$j]}"
            name2="${names[$j]}"
            
            # Skip if same file
            if [ "$file1" = "$file2" ]; then
                continue
            fi
            
            # Skip if obviously different (like Card vs Button)
            if [[ "$name1" == *"Card"* ]] && [[ "$name2" == *"Button"* ]]; then
                continue
            fi
            
            similarity=$(compare_components "$file1" "$name1" "$file2" "$name2")
            
            if [ "$similarity" -gt 70 ]; then
                echo -e "❌ ${RED}HIGH SIMILARITY ($similarity%): $name1 ↔ $name2${NC}"
                echo -e "   ${YELLOW}File 1:${NC} $file1"
                echo -e "   ${YELLOW}File 2:${NC} $file2"
                echo -e "   ${BLUE}→ Consider consolidating these components${NC}"
                echo ""
            elif [ "$similarity" -gt 50 ]; then
                echo -e "⚠️  ${YELLOW}MODERATE SIMILARITY ($similarity%): $name1 ↔ $name2${NC}"
                echo -e "   $file1"
                echo -e "   $file2"
                echo ""
            fi
        done
    done
}

# Function to find components with similar names
find_similar_names() {
    echo -e "\n${BLUE}Checking for similar component names...${NC}"
    
    components=$(grep -r "struct.*: View" $FANPLAN_DIR/ 2>/dev/null | grep -v Preview)
    
    declare -a names
    declare -a files
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            file=$(echo "$line" | cut -d: -f1)
            struct_line=$(echo "$line" | cut -d: -f3-)
            name=$(echo "$struct_line" | sed -n 's/.*struct \([A-Za-z0-9_]*\).*/\1/p')
            
            if [ -n "$name" ]; then
                names+=("$name")
                files+=("$file")
            fi
        fi
    done <<< "$components"
    
    # Check for similar patterns
    for ((i=0; i<${#names[@]}; i++)); do
        for ((j=i+1; j<${#names[@]}; j++)); do
            name1="${names[$i]}"
            name2="${names[$j]}"
            
            # Check for common patterns that might indicate duplicates
            if [[ "$name1" == *"Card" ]] && [[ "$name2" == *"Card" ]]; then
                if [[ ${#name1} -lt 15 ]] && [[ ${#name2} -lt 15 ]]; then
                    echo -e "🔍 ${BLUE}Similar Card components: $name1, $name2${NC}"
                    echo -e "   ${files[$i]}"
                    echo -e "   ${files[$j]}"
                fi
            elif [[ "$name1" == *"Button" ]] && [[ "$name2" == *"Button" ]]; then
                echo -e "🔍 ${BLUE}Similar Button components: $name1, $name2${NC}"
                echo -e "   ${files[$i]}"
                echo -e "   ${files[$j]}"
            elif [[ "$name1" == *"View" ]] && [[ "$name2" == *"View" ]]; then
                # Only flag if names are very similar
                base1=$(echo "$name1" | sed 's/View$//')
                base2=$(echo "$name2" | sed 's/View$//')
                if [[ ${#base1} -gt 3 ]] && [[ "$base1" == *"$base2"* ]] || [[ "$base2" == *"$base1"* ]]; then
                    echo -e "🔍 ${BLUE}Similar View components: $name1, $name2${NC}"
                    echo -e "   ${files[$i]}"
                    echo -e "   ${files[$j]}"
                fi
            fi
        done
    done
}

# Function to analyze component complexity
analyze_component_complexity() {
    echo -e "\n${BLUE}Component Complexity Analysis${NC}"
    echo "============================="
    
    components=$(grep -r "struct.*: View" $FANPLAN_DIR/ 2>/dev/null | grep -v Preview)
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            file=$(echo "$line" | cut -d: -f1)
            line_num=$(echo "$line" | cut -d: -f2)
            struct_line=$(echo "$line" | cut -d: -f3-)
            name=$(echo "$struct_line" | sed -n 's/.*struct \([A-Za-z0-9_]*\).*/\1/p')
            
            if [ -n "$name" ] && [ -f "$file" ]; then
                # Count lines in the component
                component_lines=$(awk "
                /struct $name.*View/ { in_struct=1; brace_count=0; start_line=NR }
                in_struct && /{/ { brace_count++ }
                in_struct && /}/ { brace_count--; if(brace_count==0) { print NR-start_line; in_struct=0; } }
                " "$file")
                
                if [ -n "$component_lines" ] && [ "$component_lines" -gt 0 ]; then
                    if [ "$component_lines" -gt 100 ]; then
                        echo -e "❌ ${RED}Complex component ($component_lines lines): $name${NC}"
                        echo -e "   $file:$line_num"
                        echo -e "   ${BLUE}→ Consider breaking into smaller components${NC}"
                    elif [ "$component_lines" -gt 50 ]; then
                        echo -e "⚠️  ${YELLOW}Large component ($component_lines lines): $name${NC}"
                        echo -e "   $file:$line_num"
                    fi
                fi
            fi
        fi
    done <<< "$components"
}

# Function to suggest refactoring opportunities
suggest_refactoring() {
    echo -e "\n${BLUE}Refactoring Suggestions${NC}"
    echo "======================"
    
    # Find repeated patterns in components
    echo -e "${BLUE}Common patterns that could be extracted:${NC}"
    
    # Look for repeated HStack/VStack patterns
    common_layouts=$(grep -r "HStack\|VStack\|ZStack" $FANPLAN_DIR/ | grep -v "import" | cut -d: -f3- | sort | uniq -c | sort -nr | head -5)
    
    echo -e "\n${BLUE}Most common layout patterns:${NC}"
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            count=$(echo "$line" | awk '{print $1}')
            pattern=$(echo "$line" | cut -d' ' -f2-)
            
            if [ "$count" -gt 3 ]; then
                echo -e "   ${YELLOW}$count occurrences:${NC} $pattern"
                echo -e "   ${BLUE}→ Consider creating reusable layout component${NC}"
            fi
        fi
    done <<< "$common_layouts"
}

# Main execution
find_duplicate_components
find_similar_names
analyze_component_complexity
suggest_refactoring

echo -e "\n${GREEN}✅ Component analysis complete!${NC}"