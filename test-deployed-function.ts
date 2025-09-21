#!/usr/bin/env -S deno run --allow-net

/**
 * Quick test for your deployed Ticketmaster function
 */

const FUNCTION_URL = "https://lxnenbhkmdvjsmnripax.supabase.co/functions/v1/get-upcoming-events"
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bmVuYmhrbWR2anNtbnJpcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzYyODQsImV4cCI6MjA2ODg1MjI4NH0.ykqeirIevUiJLWOMDznw7Sw0H1EZRqqXETrT23_VOv0"

async function testFunction() {
  console.log("🎫 Testing your deployed Ticketmaster function...")
  console.log(`📡 URL: ${FUNCTION_URL}`)

  try {
    console.log("\n1️⃣ Testing K-pop artist search...")
    const startTime = Date.now()

    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "apikey": ANON_KEY,
        "Authorization": `Bearer ${ANON_KEY}`
      },
      body: JSON.stringify({
        genres: ["music"],
        artists: ["BTS", "BLACKPINK"],
        location: "Los Angeles",
        limit: 10
      })
    })

    const duration = Date.now() - startTime
    console.log(`⏱️  Response time: ${duration}ms`)
    console.log(`📊 Status: ${response.status}`)

    const responseData = await response.json()
    console.log(`📋 Response structure:`)
    console.log(`   - Has events: ${Array.isArray(responseData.events)}`)
    console.log(`   - Event count: ${responseData.events?.length || 0}`)
    console.log(`   - Total count: ${responseData.total_count || 0}`)
    console.log(`   - Has error: ${!!responseData.error}`)

    if (responseData.error) {
      console.log(`❌ Error: ${responseData.error}`)

      if (responseData.error.includes("API key not configured")) {
        console.log("\n🔧 SOLUTION: API key not set in Supabase environment")
        console.log("1. Go to Supabase Dashboard → Settings → Environment Variables")
        console.log("2. Add: TICKETMASTER_API_KEY = QKRduVoS0LTTeNeADNQsPlrtoaphAoG7")
        console.log("3. Redeploy function")
      } else if (responseData.error.includes("401") || responseData.error.includes("unauthorized")) {
        console.log("\n🔧 SOLUTION: Invalid API key")
        console.log("1. Check your Ticketmaster Developer Console")
        console.log("2. Verify API key: QKRduVoS0LTTeNeADNQsPlrtoaphAoG7")
        console.log("3. Make sure it's the Consumer Key, not Consumer Secret")
      }
    } else if (responseData.events && responseData.events.length > 0) {
      console.log("✅ SUCCESS! Function is working")
      console.log(`📝 Sample event:`)
      const sampleEvent = responseData.events[0]
      console.log(`   - Name: ${sampleEvent.name}`)
      console.log(`   - Artist: ${sampleEvent.artist}`)
      console.log(`   - Venue: ${sampleEvent.venue}`)
      console.log(`   - City: ${sampleEvent.city}`)
      console.log(`   - Date: ${sampleEvent.date}`)
    } else {
      console.log("⚠️  No events found, but no error either")
      console.log("This could mean:")
      console.log("- No K-pop events in Los Angeles currently")
      console.log("- API key works but search is too specific")
    }

    return responseData

  } catch (error) {
    console.log(`💥 Network Error: ${error.message}`)
    console.log("This could mean:")
    console.log("- Function not deployed")
    console.log("- Network connectivity issue")
    console.log("- CORS configuration problem")
    return null
  }
}

// Test without artist filter
async function testGeneral() {
  console.log("\n2️⃣ Testing general music events...")

  try {
    const response = await fetch(FUNCTION_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "apikey": ANON_KEY,
        "Authorization": `Bearer ${ANON_KEY}`
      },
      body: JSON.stringify({
        genres: ["music"],
        location: "New York",
        limit: 5
      })
    })

    const responseData = await response.json()
    console.log(`📊 General music events: ${responseData.events?.length || 0}`)

    if (responseData.events && responseData.events.length > 0) {
      console.log("✅ Ticketmaster API is working for general events")
    }

    return responseData
  } catch (error) {
    console.log(`❌ General test failed: ${error.message}`)
    return null
  }
}

// Main execution
if (import.meta.main) {
  console.log("🔍 Quick Ticketmaster Function Test")
  console.log("=" .repeat(50))

  const kpopResult = await testFunction()
  const generalResult = await testGeneral()

  console.log("\n📊 SUMMARY:")
  if (kpopResult?.events || generalResult?.events) {
    console.log("✅ Ticketmaster integration is working!")
    console.log("✅ API key is configured correctly")
    console.log("✅ Function deployed successfully")

    console.log("\n🎯 Next steps:")
    console.log("1. Test in your iOS app Events tab")
    console.log("2. Check app console logs for detailed debugging")
    console.log("3. Verify user authentication for getFanIdols")
  } else if (kpopResult?.error || generalResult?.error) {
    console.log("❌ Function has configuration issues")
    console.log("❌ Check API key setup in Supabase")
  } else {
    console.log("❓ Unclear results - check network and deployment")
  }
}