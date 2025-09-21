#!/bin/bash

# ============================================================
# PiggyBong FanCategory Enum Update Script
# Updates all deprecated FanCategory references to new simplified enum
# ============================================================

echo "🔧 Starting FanCategory enum update across all Swift files..."

# Define the replacement mappings
declare -A replacements=(
    # Old enum cases -> New enum cases
    ["\.concertsShows"]=".concerts"
    ["\.albumsPhotocards"]=".albums" 
    ["\.officialMerch"]=".merch"
    ["\.fanEvents"]=".events"
    ["\.subscriptionsApps"]=".subs"
    ["\.other"]=".merch"  # Map other to merch as fallback
    
    # Legacy deprecated cases -> New enum cases
    ["\.concertPrep"]=".concerts"
    ["\.concert([^s])"]=".concerts\1"  # .concert -> .concerts (but not .concerts)
    ["\.albumHunting"]=".albums"
    ["\.album([^s])"]=".albums\1"      # .album -> .albums (but not .albums)  
    ["\.merchHaul"]=".merch"
    ["\.merchandise"]=".merch"
    ["\.photocardCollecting"]=".albums"  # Map to albums
    ["\.digitalContent"]=".subs"
    ["\.experience"]=".subs"
    ["\.fanmeetPrep"]=".events"
    ["\.fanmeet"]=".events"
)

# Count total files to update
total_files=$(find . -name "*.swift" -exec grep -l "\.concertsShows\|\.albumsPhotocards\|\.officialMerch\|\.fanEvents\|\.subscriptionsApps\|\.other\|\.concertPrep\|\.concert[^s]\|\.albumHunting\|\.album[^s]\|\.merchHaul\|\.merchandise\|\.photocardCollecting\|\.digitalContent\|\.experience\|\.fanmeetPrep\|\.fanmeet" {} \; | wc -l)

echo "📊 Found $total_files Swift files with deprecated FanCategory references"

# Apply replacements
count=0
for pattern in "${!replacements[@]}"; do
    replacement="${replacements[$pattern]}"
    echo "🔄 Replacing $pattern -> $replacement"
    
    # Use sed to replace across all Swift files
    find . -name "*.swift" -exec sed -i '' -E "s/$pattern/$replacement/g" {} \;
    
    ((count++))
done

echo "✅ Applied $count replacement patterns across all Swift files"

# Verify results
remaining=$(find . -name "*.swift" -exec grep -l "\.concertsShows\|\.albumsPhotocards\|\.officialMerch\|\.fanEvents\|\.subscriptionsApps\|\.concertPrep\|\.albumHunting\|\.merchHaul\|\.merchandise\|\.photocardCollecting\|\.digitalContent\|\.experience\|\.fanmeetPrep\|\.fanmeet" {} \; 2>/dev/null | wc -l)

echo "📈 Remaining files with deprecated references: $remaining"

if [ "$remaining" -eq 0 ]; then
    echo "🎉 SUCCESS: All FanCategory references updated!"
else
    echo "⚠️  Some files may need manual review"
    echo "Files still containing deprecated references:"
    find . -name "*.swift" -exec grep -l "\.concertsShows\|\.albumsPhotocards\|\.officialMerch\|\.fanEvents\|\.subscriptionsApps\|\.concertPrep\|\.albumHunting\|\.merchHaul\|\.merchandise\|\.photocardCollecting\|\.digitalContent\|\.experience\|\.fanmeetPrep\|\.fanmeet" {} \; 2>/dev/null
fi

echo "🔧 FanCategory enum update complete!"