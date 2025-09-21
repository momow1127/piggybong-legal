#!/usr/bin/env -S deno run --allow-net --allow-env

/**
 * Test script for the enhanced Ticketmaster Edge Function
 * Run with: deno run --allow-net --allow-env test-ticketmaster-function.ts
 */

const FUNCTION_URL = "http://localhost:54321/functions/v1/get-upcoming-events"
const PRODUCTION_URL = "https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/get-upcoming-events"

// Test scenarios
const testCases = [
  {
    name: "Valid K-pop artist search",
    payload: {
      genres: ["music"],
      artists: ["BTS", "BLACKPINK"],
      location: "Los Angeles",
      limit: 10
    },
    expectSuccess: true
  },
  {
    name: "No artist filter",
    payload: {
      genres: ["music"],
      location: "New York",
      limit: 5
    },
    expectSuccess: true
  },
  {
    name: "Invalid limit (too high)",
    payload: {
      genres: ["music"],
      limit: 500 // Should be capped at 200
    },
    expectSuccess: true
  },
  {
    name: "Invalid JSON payload",
    payload: "invalid-json",
    expectSuccess: false,
    expectedErrorCode: "INVALID_JSON"
  },
  {
    name: "Invalid limit (negative)",
    payload: {
      limit: -5
    },
    expectSuccess: false,
    expectedErrorCode: "INVALID_REQUEST"
  },
  {
    name: "Non-array artists",
    payload: {
      artists: "not-an-array"
    },
    expectSuccess: false,
    expectedErrorCode: "INVALID_REQUEST"
  }
]

async function testFunction(url: string) {
  console.log(`\n🧪 Testing Ticketmaster function at: ${url}`)
  console.log("=" .repeat(80))

  let passed = 0
  let failed = 0

  for (const testCase of testCases) {
    console.log(`\n📝 Test: ${testCase.name}`)
    console.log(`   Payload:`, JSON.stringify(testCase.payload, null, 2))

    try {
      const startTime = Date.now()

      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": "your-anon-key-here" // Replace with actual anon key if testing production
        },
        body: testCase.payload === "invalid-json" ? "invalid-json" : JSON.stringify(testCase.payload)
      })

      const duration = Date.now() - startTime
      const responseData = await response.json()

      console.log(`   ⏱️  Duration: ${duration}ms`)
      console.log(`   📊 Status: ${response.status}`)
      console.log(`   📋 Response:`, JSON.stringify(responseData, null, 2).slice(0, 300) + "...")

      // Validate response structure
      const hasRequiredFields = responseData.hasOwnProperty('success') &&
                               responseData.hasOwnProperty('events') &&
                               responseData.hasOwnProperty('total_count')

      if (!hasRequiredFields) {
        console.log(`   ❌ Missing required response fields`)
        failed++
        continue
      }

      // Check if test result matches expectation
      if (testCase.expectSuccess && responseData.success) {
        console.log(`   ✅ PASS - Expected success, got success`)
        console.log(`   📈 Events returned: ${responseData.events.length}`)
        passed++
      } else if (!testCase.expectSuccess && !responseData.success) {
        if (testCase.expectedErrorCode && responseData.error_code === testCase.expectedErrorCode) {
          console.log(`   ✅ PASS - Expected error code ${testCase.expectedErrorCode}, got ${responseData.error_code}`)
          passed++
        } else if (!testCase.expectedErrorCode) {
          console.log(`   ✅ PASS - Expected failure, got failure`)
          passed++
        } else {
          console.log(`   ❌ FAIL - Expected error code ${testCase.expectedErrorCode}, got ${responseData.error_code}`)
          failed++
        }
      } else {
        console.log(`   ❌ FAIL - Expected ${testCase.expectSuccess ? 'success' : 'failure'}, got ${responseData.success ? 'success' : 'failure'}`)
        failed++
      }

    } catch (error) {
      console.log(`   💥 ERROR: ${error.message}`)
      failed++
    }
  }

  console.log(`\n📊 Test Results:`)
  console.log(`✅ Passed: ${passed}`)
  console.log(`❌ Failed: ${failed}`)
  console.log(`📈 Success Rate: ${Math.round((passed / (passed + failed)) * 100)}%`)

  return { passed, failed }
}

async function checkEnvironment() {
  console.log("🔍 Environment Check:")

  // Check if running locally with Supabase
  try {
    const healthResponse = await fetch("http://localhost:54321/health")
    if (healthResponse.ok) {
      console.log("✅ Local Supabase instance detected")
      return "local"
    }
  } catch {
    console.log("⚠️  Local Supabase instance not running")
  }

  console.log("🌐 Will test against production (limited functionality)")
  return "production"
}

// Main execution
if (import.meta.main) {
  console.log("🎫 Ticketmaster Edge Function Test Suite")
  console.log("=" .repeat(50))

  const environment = await checkEnvironment()
  const url = environment === "local" ? FUNCTION_URL : PRODUCTION_URL

  if (environment === "production") {
    console.log("\n⚠️  Testing against production:")
    console.log("• Some tests may fail due to CORS or auth restrictions")
    console.log("• API key validation tests will be limited")
    console.log("• For full testing, run: supabase start")
  }

  await testFunction(url)

  console.log("\n🎯 Next Steps:")
  console.log("1. If API key tests fail, check your .env.local file")
  console.log("2. Deploy function: supabase functions deploy get-upcoming-events")
  console.log("3. Test in your iOS app Events tab")
  console.log("4. Check Supabase logs for detailed error messages")
}