#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 FIXING DUPLICATE CORS HEADERS\\n');

const functionsDir = '/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main/supabase/functions';

// Get all function directories (excluding backup files and shared)
const functionDirs = fs.readdirSync(functionsDir)
  .filter(name => {
    const dirPath = path.join(functionsDir, name);
    return fs.statSync(dirPath).isDirectory() &&
           name !== '_shared' &&
           !name.endsWith('.backup');
  });

console.log(`📋 Checking ${functionDirs.length} functions for duplicate CORS headers...\\n`);

let fixedCount = 0;

functionDirs.forEach(funcName => {
  const indexPath = path.join(functionsDir, funcName, 'index.ts');

  if (fs.existsSync(indexPath)) {
    const content = fs.readFileSync(indexPath, 'utf8');

    // Check if function imports corsHeaders AND has local declaration
    const hasImport = content.includes('import.*corsHeaders.*from.*_shared') ||
                     content.includes('corsHeaders,') && content.includes('from \'../_shared');
    const hasLocalDecl = content.includes('const corsHeaders = {');

    if (hasImport && hasLocalDecl) {
      console.log(`🔧 Fixing duplicate CORS in ${funcName}...`);

      // Remove the local corsHeaders declaration
      const lines = content.split('\\n');
      let inCorsDeclaration = false;
      let braceCount = 0;
      const filteredLines = [];

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];

        // Start of CORS declaration
        if (line.includes('const corsHeaders = {') && !inCorsDeclaration) {
          inCorsDeclaration = true;
          braceCount = (line.match(/\\{/g) || []).length - (line.match(/\\}/g) || []).length;
          // Skip this line
          continue;
        }

        // Continue skipping lines until we close the CORS object
        if (inCorsDeclaration) {
          braceCount += (line.match(/\\{/g) || []).length - (line.match(/\\}/g) || []).length;

          if (braceCount <= 0) {
            inCorsDeclaration = false;
            // Skip the closing line too
            continue;
          }
          // Skip lines inside the CORS declaration
          continue;
        }

        filteredLines.push(line);
      }

      const fixedContent = filteredLines.join('\\n');

      // Create backup
      const backupPath = indexPath + '.cors-backup';
      fs.writeFileSync(backupPath, content);

      // Write fixed content
      fs.writeFileSync(indexPath, fixedContent);

      console.log(`   ✅ Fixed ${funcName} (backup: ${path.basename(backupPath)})`);
      fixedCount++;
    }
  }
});

console.log(`\\n✅ DUPLICATE CORS FIXES COMPLETED!`);
console.log(`📊 Fixed ${fixedCount} functions with duplicate CORS headers`);
console.log(`\\n📋 NEXT: Retry deployment of all functions`);