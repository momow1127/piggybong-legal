import { serve } from "https://deno.land/std@0.224.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
}

const CLAUDE_API_KEY = Deno.env.get('CLAUDE_API_KEY')

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('=== DEBUG START ===')
    console.log('Claude API Key exists:', CLAUDE_API_KEY ? 'YES' : 'NO')
    console.log('Claude API Key length:', CLAUDE_API_KEY ? CLAUDE_API_KEY.length : 0)
    console.log('Claude API Key prefix:', CLAUDE_API_KEY ? CLAUDE_API_KEY.substring(0, 20) : 'NONE')
    
    if (!CLAUDE_API_KEY) {
      throw new Error('Claude API key not configured')
    }

    const { messages, temperature, max_tokens } = await req.json()

    if (!messages || !Array.isArray(messages)) {
      throw new Error('Messages array is required')
    }

    const userMessage = messages[messages.length - 1]?.content || 'Hello'
    console.log('User message:', userMessage.substring(0, 50))

    console.log('Making Claude request...')
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': CLAUDE_API_KEY,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-3-haiku-20240307',
        max_tokens: max_tokens || 100,
        messages: [
          {
            role: 'user',
            content: userMessage
          }
        ]
      })
    })

    console.log('Claude response status:', response.status)
    
    if (!response.ok) {
      const errorText = await response.text()
      console.log('Claude error response:', errorText)
      throw new Error(`Claude API error: ${response.status}`)
    }

    const data = await response.json()
    console.log('Claude response success!')

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
    
    const errorResponse = {
      error: 'Service temporarily unavailable',
      choices: [{
        message: {
          role: 'assistant',
          content: 'Having connection issues right now!'
        }
      }]
    }
    
    return new Response(JSON.stringify(errorResponse), { 
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})