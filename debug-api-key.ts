import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const CLAUDE_API_KEY = Deno.env.get('CLAUDE_API_KEY')
    const expectedKey = "YOUR_CLAUDE_API_KEY_HERE"
    
    console.log('=== API KEY DEBUG ===')
    console.log('Key exists:', CLAUDE_API_KEY ? 'YES' : 'NO')
    console.log('Key length:', CLAUDE_API_KEY ? CLAUDE_API_KEY.length : 0)
    console.log('Expected length:', expectedKey.length)
    console.log('Keys match:', CLAUDE_API_KEY === expectedKey)
    
    if (CLAUDE_API_KEY) {
      console.log('First 30 chars:', JSON.stringify(CLAUDE_API_KEY.substring(0, 30)))
      console.log('Last 30 chars:', JSON.stringify(CLAUDE_API_KEY.substring(-30)))
      
      // Check for invisible characters
      const keyBytes = new TextEncoder().encode(CLAUDE_API_KEY)
      console.log('Key bytes length:', keyBytes.length)
      console.log('First 10 bytes:', Array.from(keyBytes.slice(0, 10)))
      console.log('Last 10 bytes:', Array.from(keyBytes.slice(-10)))
    }
    
    return new Response(JSON.stringify({
      keyExists: CLAUDE_API_KEY ? true : false,
      keyLength: CLAUDE_API_KEY ? CLAUDE_API_KEY.length : 0,
      expectedLength: expectedKey.length,
      keysMatch: CLAUDE_API_KEY === expectedKey
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.log('Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})