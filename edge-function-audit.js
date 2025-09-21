#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔍 COMPREHENSIVE EDGE FUNCTION AUDIT\n');

const functionsDir = '/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong2-piggy-bong-main/supabase/functions';

// Get all function directories
const functionDirs = fs.readdirSync(functionsDir, { withFileTypes: true })
  .filter(dirent => dirent.isDirectory())
  .map(dirent => dirent.name)
  .sort();

console.log(`📊 Found ${functionDirs.length} Edge Functions\n`);

const auditResults = {
  total: functionDirs.length,
  outdatedImports: [],
  missingCORS: [],
  noErrorHandling: [],
  duplicates: [],
  largeFunctions: [],
  missingLogging: [],
  deprecatedPatterns: [],
  goodFunctions: []
};

for (const funcName of functionDirs) {
  const indexPath = path.join(functionsDir, funcName, 'index.ts');

  if (!fs.existsSync(indexPath)) {
    console.log(`⚠️  ${funcName}: Missing index.ts`);
    continue;
  }

  const content = fs.readFileSync(indexPath, 'utf8');
  const lines = content.split('\n');

  console.log(`\n📁 ${funcName}:`);

  // Check for common issues
  const issues = [];
  const warnings = [];

  // 1. Check Deno std version
  if (content.includes('@0.177.0')) {
    warnings.push('Using old Deno std version (0.177.0)');
    auditResults.outdatedImports.push(funcName);
  }

  // 2. Check CORS headers
  if (!content.includes('Access-Control-Allow-Origin')) {
    issues.push('Missing CORS headers');
    auditResults.missingCORS.push(funcName);
  }

  // 3. Check error handling
  if (!content.includes('try') || !content.includes('catch')) {
    issues.push('No try/catch error handling');
    auditResults.noErrorHandling.push(funcName);
  }

  // 4. Check function size
  if (lines.length > 200) {
    warnings.push(`Large function (${lines.length} lines)`);
    auditResults.largeFunctions.push({name: funcName, lines: lines.length});
  }

  // 5. Check logging
  if (!content.includes('console.log') && !content.includes('console.error')) {
    warnings.push('No logging statements');
    auditResults.missingLogging.push(funcName);
  }

  // 6. Check for deprecated patterns
  if (content.includes('new Response(JSON.stringify(') && !content.includes('Content-Type')) {
    warnings.push('JSON response without Content-Type header');
    auditResults.deprecatedPatterns.push(funcName);
  }

  // Report status
  if (issues.length === 0 && warnings.length === 0) {
    console.log('  ✅ Good condition');
    auditResults.goodFunctions.push(funcName);
  } else {
    if (issues.length > 0) {
      console.log('  🚨 Issues:');
      issues.forEach(issue => console.log(`    - ${issue}`));
    }
    if (warnings.length > 0) {
      console.log('  ⚠️  Warnings:');
      warnings.forEach(warning => console.log(`    - ${warning}`));
    }
  }
}

// Summary Report
console.log('\n\n📋 AUDIT SUMMARY');
console.log('=' .repeat(50));
console.log(`Total Functions: ${auditResults.total}`);
console.log(`✅ Good Condition: ${auditResults.goodFunctions.length}`);
console.log(`⚠️  Need Updates: ${auditResults.total - auditResults.goodFunctions.length}`);

console.log('\n🔧 ISSUES FOUND:');
console.log(`📦 Outdated Imports: ${auditResults.outdatedImports.length}`);
console.log(`🌐 Missing CORS: ${auditResults.missingCORS.length}`);
console.log(`❌ No Error Handling: ${auditResults.noErrorHandling.length}`);
console.log(`📏 Large Functions: ${auditResults.largeFunctions.length}`);
console.log(`📝 Missing Logging: ${auditResults.missingLogging.length}`);
console.log(`⚰️  Deprecated Patterns: ${auditResults.deprecatedPatterns.length}`);

console.log('\n🎯 PRIORITY FIXES:');

if (auditResults.missingCORS.length > 0) {
  console.log('\n🚨 HIGH PRIORITY - Missing CORS:');
  auditResults.missingCORS.forEach(func => console.log(`   - ${func}`));
}

if (auditResults.noErrorHandling.length > 0) {
  console.log('\n🚨 HIGH PRIORITY - No Error Handling:');
  auditResults.noErrorHandling.forEach(func => console.log(`   - ${func}`));
}

if (auditResults.outdatedImports.length > 0) {
  console.log('\n⚠️  MEDIUM PRIORITY - Outdated Imports:');
  auditResults.outdatedImports.forEach(func => console.log(`   - ${func}`));
}

if (auditResults.largeFunctions.length > 0) {
  console.log('\n📏 REFACTOR - Large Functions:');
  auditResults.largeFunctions.forEach(func => console.log(`   - ${func.name} (${func.lines} lines)`));
}

console.log('\n✅ WELL-MAINTAINED FUNCTIONS:');
if (auditResults.goodFunctions.length > 0) {
  auditResults.goodFunctions.forEach(func => console.log(`   - ${func}`));
} else {
  console.log('   (None - all functions need some updates)');
}

// Save results to file
fs.writeFileSync('function-audit-results.json', JSON.stringify(auditResults, null, 2));
console.log('\n📄 Detailed results saved to: function-audit-results.json');