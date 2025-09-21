#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 Updating Deno imports and CORS headers in Edge Functions...\n');

const functionsDir = './supabase/functions';
const functionDirs = fs.readdirSync(functionsDir, { withFileTypes: true })
  .filter(dirent => dirent.isDirectory())
  .map(dirent => dirent.name);

const corsTemplate = `const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};`;

let updatedCount = 0;

functionDirs.forEach(functionName => {
  const indexPath = path.join(functionsDir, functionName, 'index.ts');

  if (fs.existsSync(indexPath)) {
    let content = fs.readFileSync(indexPath, 'utf8');
    let hasChanges = false;

    // Update Deno std imports
    const oldImportPattern = /https:\/\/deno\.land\/std@0\.(168|177)\.0\//g;
    if (oldImportPattern.test(content)) {
      content = content.replace(oldImportPattern, 'https://deno.land/std@0.224.0/');
      hasChanges = true;
      console.log(`✓ Updated Deno import in ${functionName}`);
    }

    // Add CORS headers if missing
    if (!content.includes('corsHeaders') && !content.includes('cors.ts')) {
      // Add CORS after imports
      const importLines = content.split('\n').filter(line => line.trim().startsWith('import'));
      const restOfCode = content.split('\n').slice(importLines.length);

      const updatedContent = [
        ...importLines,
        '',
        corsTemplate,
        '',
        ...restOfCode
      ].join('\n');

      content = updatedContent;
      hasChanges = true;
      console.log(`✓ Added CORS headers to ${functionName}`);
    }

    // Add OPTIONS handling if missing
    if (!content.includes("req.method === 'OPTIONS'")) {
      const servePattern = /serve\(async \(req\) => \{/;
      if (servePattern.test(content)) {
        content = content.replace(
          servePattern,
          `serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }`
        );
        hasChanges = true;
        console.log(`✓ Added OPTIONS handling to ${functionName}`);
      }
    }

    if (hasChanges) {
      fs.writeFileSync(indexPath, content);
      updatedCount++;
    }
  }
});

console.log(`\n🎉 Updated ${updatedCount} functions successfully!`);
console.log('\nNext: Deploy functions with: supabase functions deploy');