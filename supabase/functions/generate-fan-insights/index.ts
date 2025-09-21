import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { corsHeaders } from '../_shared/cors.ts'

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (!ANTHROPIC_API_KEY) {
      throw new Error('Anthropic API key not configured')
    }

    const { user_id, event_history, preferences, artist_id, artist_name } = await req.json()

    if (!user_id) {
      throw new Error('User ID is required')
    }

    // Dynamic temperature based on artist popularity
    const popularArtists = ['BTS', 'BLACKPINK', 'TWICE', 'ITZY', 'aespa', 'NewJeans', 'LE SSERAFIM', 'NMIXX', 'IVE', 'STRAY KIDS']
    const isPopularArtist = artist_name && popularArtists.some(artist =>
      artist_name.toLowerCase().includes(artist.toLowerCase())
    )
    const temperature = isPopularArtist ? 0.6 : 0.85

    // Create prompt for generating fan insights
    const prompt = `
You are a K-pop fan analyst. Analyze the following user data and provide personalized insights and recommendations.

User Event History: ${event_history?.join(', ') || 'No events attended yet'}
User Preferences: ${preferences?.join(', ') || 'No preferences specified'}

Please provide:
1. 3-5 personalized insights about their fan journey
2. 3-5 recommendations for future events or activities

Format your response as JSON with this structure:
{
  "insights": [
    {
      "type": "spending_pattern" | "event_preference" | "artist_affinity" | "growth_opportunity",
      "title": "Brief title",
      "description": "Detailed insight",
      "value": numerical_value_if_applicable
    }
  ],
  "recommendations": [
    "Recommendation 1",
    "Recommendation 2",
    ...
  ]
}
`

    // Call Anthropic Claude API
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${ANTHROPIC_API_KEY}`,
        'Content-Type': 'application/json',
        'x-api-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 1500,
        temperature: temperature,
        messages: [
          {
            role: 'user',
            content: `You are a helpful K-pop fan analyst who provides personalized insights.\n\n${prompt}`
          }
        ]
      })
    })

    if (!response.ok) {
      throw new Error(`Anthropic API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.content[0]?.text

    if (!content) {
      throw new Error('No insights generated')
    }

    // Try to parse JSON response, fallback to structured data if parsing fails
    let insights
    try {
      insights = JSON.parse(content)
    } catch {
      // Fallback if AI doesn't return valid JSON
      insights = {
        insights: [
          {
            type: "growth_opportunity",
            title: "Your Fan Journey",
            description: content.substring(0, 200) + "...",
            value: null
          }
        ],
        recommendations: [
          "Explore new artists in your favorite genres",
          "Join fan communities for better concert experiences",
          "Set up budget alerts for upcoming events"
        ]
      }
    }

    return new Response(
      JSON.stringify(insights),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Generate insights error:', error)
    
    // Return fallback insights on error
    const fallbackInsights = {
      insights: [
        {
          type: "growth_opportunity",
          title: "Welcome to Your Fan Journey!",
          description: "Start exploring K-pop events and building your preferences to get personalized insights.",
          value: null
        }
      ],
      recommendations: [
        "Set up your favorite artists and genres",
        "Browse upcoming K-pop events in your area", 
        "Create a concert budget to track your spending",
        "Join fan communities for tips and recommendations"
      ]
    }
    
    return new Response(
      JSON.stringify(fallbackInsights),
      { 
        status: 200, // Return 200 with fallback data instead of error
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})