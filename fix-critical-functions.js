#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 FIXING CRITICAL EDGE FUNCTION ISSUES\n');

const functionsDir = '/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main/supabase/functions';

// Functions that need CORS fixes
const missingCORSFunctions = [
  'cache-manager', 'cleanup-expired-codes', 'generate-fan-insights',
  'get-artist-updates', 'handle-subscription-webhook', 'manage-artist-subscription',
  'manage-event-subscriptions', 'manage-goals', 'manage-subscription',
  'n8n-artist-webhook', 'optimized-dashboard', 'search-artists',
  'send-verification-code', 'verify-email-code'
];

// Standard CORS headers template
const corsTemplate = `
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE'
};
`;

// Updated Deno import
const updatedDenoImport = `import { serve } from "https://deno.land/std@0.224.0/http/server.ts"`;

console.log('🎯 PRIORITY 1: Adding CORS headers to critical functions...\n');

missingCORSFunctions.forEach(funcName => {
  const indexPath = path.join(functionsDir, funcName, 'index.ts');

  if (fs.existsSync(indexPath)) {
    let content = fs.readFileSync(indexPath, 'utf8');

    // Check if function already has CORS
    if (!content.includes('Access-Control-Allow-Origin')) {
      console.log(`🔧 Fixing ${funcName}...`);

      // Add CORS headers after imports
      const lines = content.split('\n');
      let insertIndex = 0;

      // Find the line after imports
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith('import ') || lines[i].trim().startsWith('//')) {
          insertIndex = i + 1;
        } else if (lines[i].trim() === '') {
          continue;
        } else {
          break;
        }
      }

      lines.splice(insertIndex, 0, corsTemplate);

      // Update OPTIONS handling
      if (!content.includes('OPTIONS')) {
        const serveIndex = lines.findIndex(line => line.includes('serve('));
        if (serveIndex !== -1) {
          lines.splice(serveIndex + 1, 0,
            '  if (req.method === \'OPTIONS\') {',
            '    return new Response(\'ok\', { headers: corsHeaders });',
            '  }',
            ''
          );
        }
      }

      // Update response headers
      content = lines.join('\n');

      // Add CORS to JSON responses
      content = content.replace(
        /new Response\(JSON\.stringify\((.*?)\),\s*{[\s\S]*?headers:\s*{[\s\S]*?}/g,
        (match) => {
          if (!match.includes('corsHeaders')) {
            return match.replace(
              /headers:\s*{([\s\S]*?)}/,
              'headers: { ...corsHeaders, $1 }'
            );
          }
          return match;
        }
      );

      // Save updated file
      const backupPath = indexPath + '.backup';
      fs.writeFileSync(backupPath, fs.readFileSync(indexPath));
      fs.writeFileSync(indexPath, content);

      console.log(`   ✅ Fixed CORS for ${funcName} (backup saved)`);
    } else {
      console.log(`   ⚠️  ${funcName} already has CORS`);
    }
  }
});

console.log('\n🎯 PRIORITY 2: Updating Deno std imports...\n');

// Update Deno std version for all functions
const outdatedFunctions = [
  'apn-service', 'cache-manager', 'generate-fan-insights', 'get-artist-updates',
  'get-artists-events', 'get-upcoming-events', 'get-user-artists', 'get-user-events',
  'global-artist-monitor', 'handle-subscription-webhook', 'manage-artist-subscription',
  'manage-artists', 'manage-goals', 'manage-subscription', 'n8n-artist-webhook',
  'openai-proxy', 'optimized-dashboard', 'realtime-orchestrator', 'search-artists',
  'send-concert-notification', 'send-push-notification'
];

outdatedFunctions.forEach(funcName => {
  const indexPath = path.join(functionsDir, funcName, 'index.ts');

  if (fs.existsSync(indexPath)) {
    let content = fs.readFileSync(indexPath, 'utf8');

    if (content.includes('@0.177.0')) {
      console.log(`🔧 Updating Deno std for ${funcName}...`);

      content = content.replace(
        /@0\.177\.0/g,
        '@0.224.0'
      );

      fs.writeFileSync(indexPath, content);
      console.log(`   ✅ Updated Deno std version for ${funcName}`);
    }
  }
});

console.log('\n✅ CRITICAL FIXES COMPLETED!');
console.log('\n📋 NEXT STEPS:');
console.log('1. Review the backup files created (.backup extension)');
console.log('2. Test functions locally before deploying');
console.log('3. Deploy updated functions: supabase functions deploy <function-name>');
console.log('4. Consider refactoring large functions (21 functions >200 lines)');
console.log('5. Add proper logging to functions missing it');

console.log('\n🚨 DEPLOYMENT PRIORITY ORDER:');
console.log('1. auth-* functions (authentication critical)');
console.log('2. user-management & send-verification-code (user onboarding)');
console.log('3. get-upcoming-events & manage-event-subscriptions (core features)');
console.log('4. cache-manager & optimized-dashboard (performance)');
console.log('5. Others based on usage frequency');