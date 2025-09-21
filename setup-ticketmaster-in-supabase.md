# Fix: Set Ticketmaster API Key in Supabase

## The Problem
Your app is failing to fetch events because the Ticketmaster API key is not set in your Supabase Edge Function environment variables.

## Solution Steps

### Option 1: Via Supabase Dashboard (Recommended)

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/YOUR-PROJECT-REF

2. Navigate to: **Edge Functions** → **get-upcoming-events** → **Settings**

3. Add Environment Variable:
   - Key: `TICKETMASTER_API_KEY`
   - Value: Your actual Ticketmaster API key

4. If you don't have a Ticketmaster API key:
   - Go to https://developer.ticketmaster.com/
   - Sign up for a free account
   - Get your API key from the dashboard
   - Common free tier key format: `GkB8Z37ZfqbLCjPuN1E5tyivk6Ala5vR` (example)

5. Save and redeploy the function

### Option 2: Via Supabase CLI

```bash
# Login to Supabase (if not already)
supabase login

# Set the secret
supabase secrets set TICKETMASTER_API_KEY="YOUR_ACTUAL_API_KEY" --project-ref YOUR-PROJECT-REF

# Redeploy the function
supabase functions deploy get-upcoming-events --project-ref YOUR-PROJECT-REF
```

### Option 3: Test with Mock Data (Temporary)

If you want to test the app without real API keys, modify the Edge Function to return mock data:

```typescript
// In supabase/functions/get-upcoming-events/index.ts
// Add this mock data response when API key is missing:

if (!TICKETMASTER_API_KEY || TICKETMASTER_API_KEY === 'your_ticketmaster_api_key_here') {
  return new Response(JSON.stringify({
    events: [
      {
        name: "BTS World Tour",
        artist: "BTS",
        venue: "Madison Square Garden",
        city: "New York",
        date: "2025-10-15T19:00:00Z",
        url: "https://example.com/bts-tour",
        image_url: "https://picsum.photos/400/300"
      },
      {
        name: "BLACKPINK Concert",
        artist: "BLACKPINK",
        venue: "Staples Center",
        city: "Los Angeles",
        date: "2025-11-20T20:00:00Z",
        url: "https://example.com/blackpink",
        image_url: "https://picsum.photos/400/300"
      }
    ],
    total_count: 2
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status: 200
  })
}
```

## Verify the Fix

After setting the API key, test it:

```bash
curl -X POST "https://YOUR-PROJECT.supabase.co/functions/v1/get-upcoming-events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{"artists": ["BTS"], "limit": 5}'
```

You should see real events returned instead of an empty array.

## Other API Keys to Set (Optional)

While you're in the Supabase dashboard, you might also want to set:

- `OPENAI_API_KEY`: For AI features
- `SPOTIFY_CLIENT_ID`: For Spotify integration
- `SPOTIFY_CLIENT_SECRET`: For Spotify integration

## Note
The RSS feeds (Soompi) work without API keys, so you're getting some news content. But for actual concert/event data from Ticketmaster, you need to set the API key in Supabase.