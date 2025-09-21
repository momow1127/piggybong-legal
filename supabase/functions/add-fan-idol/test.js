// Test script for add-fan-idol Edge Function
const SUPABASE_URL = "https://lxnenbhkmdvjsmnripax.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bmVuYmhrbWR2anNtbnJpcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzYyODQsImV4cCI6MjA2ODg1MjI4NH0.ykqeirIevUiJLWOMDznw7Sw0H1EZRqqXETrT23_VOv0";

async function testAddIdol() {
  try {
    // First, let's test if the function endpoint is accessible
    console.log("Testing add-fan-idol Edge Function...");

    const response = await fetch(`${SUPABASE_URL}/functions/v1/add-fan-idol`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}` // Using anon key as placeholder
      },
      body: JSON.stringify({
        artistId: "550e8400-e29b-41d4-a716-446655440000" // Test UUID
      })
    });

    console.log("Response status:", response.status);
    console.log("Response headers:", Object.fromEntries(response.headers.entries()));

    const responseText = await response.text();
    console.log("Response body:", responseText);

    if (response.ok) {
      console.log("✅ Function is accessible and responding");
    } else {
      console.log("❌ Function returned error:", response.status);
    }

  } catch (error) {
    console.error("❌ Error testing function:", error.message);
  }
}

testAddIdol();