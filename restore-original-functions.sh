#!/bin/bash

echo "🔄 Restoring all original Edge Function code from backups..."

# Find all backup files and restore them
find "/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main/supabase/functions" -name "*.backup" | while read backup_file; do
    # Get the original file path by removing .backup extension
    original_file="${backup_file%.backup}"

    if [ -f "$backup_file" ]; then
        echo "📄 Restoring $(basename "$original_file") from backup..."
        cp "$backup_file" "$original_file"
        echo "   ✅ Restored: $original_file"
    fi
done

echo ""
echo "✅ All original Edge Function code restored!"
echo "📋 The following functions have been restored to their original sophisticated implementations:"

find "/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main/supabase/functions" -name "*.backup" | while read backup_file; do
    original_file="${backup_file%.backup}"
    function_name=$(basename "$(dirname "$backup_file")")
    echo "   - $function_name"
done