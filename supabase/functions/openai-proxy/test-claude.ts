import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

// Test with environment variable API key
const CLAUDE_API_KEY = Deno.env.get('CLAUDE_API_KEY') || "YOUR_CLAUDE_API_KEY_HERE"

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('=== DIRECT API KEY TEST ===')
    console.log('Using hardcoded key, length:', CLAUDE_API_KEY.length)
    
    // Minimal test payload
    const testPayload = {
      model: 'claude-3-haiku-20240307',
      max_tokens: 50,
      messages: [
        {
          role: 'user',
          content: 'Hello'
        }
      ]
    }
    
    console.log('Test payload:', JSON.stringify(testPayload, null, 2))

    console.log('Making Claude request...')
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': CLAUDE_API_KEY,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify(testPayload)
    })

    console.log('Claude response status:', response.status)
    console.log('Claude response headers:', Object.fromEntries(response.headers.entries()))
    
    const responseText = await response.text()
    console.log('Claude response body:', responseText)
    
    if (!response.ok) {
      throw new Error(`Claude API error: ${response.status} - ${responseText}`)
    }

    const data = JSON.parse(responseText)
    
    const openAIFormat = {
      choices: [{
        message: {
          role: 'assistant',
          content: data.content[0]?.text || 'No response available'
        }
      }]
    }

    return new Response(JSON.stringify(openAIFormat), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.log('=== ERROR ===')
    console.log('Error message:', error.message)
    console.log('Error stack:', error.stack)
    
    const errorResponse = {
      error: error.message,
      choices: [{
        message: {
          role: 'assistant',
          content: 'Test failed - check logs'
        }
      }]
    }
    
    return new Response(JSON.stringify(errorResponse), { 
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})