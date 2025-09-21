# Real Event Data Integration Setup

This guide explains how to set up the real event data integration for PiggyBong, replacing hardcoded events with live data from Ticketmaster and other sources.

## Overview

The integration includes:
- ✅ **Ticketmaster API** for real concert/show events
- ✅ **RSS Feeds** for K-pop news and updates  
- ✅ **Database Caching** to avoid API rate limits
- ✅ **User Artist Filtering** to show relevant events only
- ✅ **Fallback System** for when APIs are unavailable

## Setup Steps

### 1. Database Schema Setup

Run the events schema in your Supabase SQL Editor:

```bash
# Apply the events table schema
cat events_schema.sql | supabase db reset --db-url "your-supabase-db-url"
```

Or manually execute the SQL in Supabase Dashboard > SQL Editor:
- Copy contents from `events_schema.sql`
- This creates `events` and `user_event_subscriptions` tables

### 2. Deploy Supabase Edge Functions

```bash
# Deploy the event fetching functions
supabase functions deploy get-upcoming-events
supabase functions deploy get-user-events  
supabase functions deploy manage-event-subscriptions

# Set environment variables
supabase secrets set TICKETMASTER_API_KEY="your_ticketmaster_api_key"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="your_service_role_key"
```

### 3. Get Ticketmaster API Key

1. Go to [Ticketmaster Developer Portal](https://developer.ticketmaster.com/)
2. Create an account and get your API key
3. Add it to your `.env` file:
   ```
   TICKETMASTER_API_KEY=your_actual_api_key_here
   ```

### 4. Test the Integration

The app will automatically:
1. ✅ **Sync user's artists** from their idol selections
2. ✅ **Cache events** in the database for offline access
3. ✅ **Show real concert dates** from Ticketmaster
4. ✅ **Display RSS news** filtered by user's artists
5. ✅ **Fall back** to cached data if APIs fail

## Features

### Real-Time Events
- Live concert data from Ticketmaster API
- K-pop news from RSS feeds (Soompi)
- Automatic deduplication and sorting

### Smart Caching
- Events cached in Supabase for 24 hours
- Reduces API calls and improves performance  
- Works offline with cached data

### Artist Filtering
- Only shows events for user's selected artists
- Syncs with user's idol preferences
- Fallback to popular K-pop artists if no selection

### Connection Status
- Visual indicators for API availability
- Graceful degradation when APIs are down
- Retry logic with exponential backoff

## File Changes

### New Files
- ✅ `events_schema.sql` - Database schema for event caching
- ✅ `supabase/functions/get-upcoming-events/index.ts` - Ticketmaster API integration
- ✅ `supabase/functions/get-user-events/index.ts` - Cached event retrieval
- ✅ `supabase/functions/manage-event-subscriptions/index.ts` - Artist subscription management
- ✅ `FanPlan/RealTimeEventService.swift` - Real-time event fetching service

### Updated Files
- ✅ `FanPlan/EventService.swift` - Integrated database caching and API calls
- ✅ `FanPlan/EventsView.swift` - Added connection status and real-time updates
- ✅ `FanPlan/EventModels.swift` - Extended with new API response models

## Benefits

### For Users
- **Real Concert Dates**: See actual upcoming concerts for their favorite artists
- **Breaking News**: Get the latest K-pop news and updates
- **Personalized**: Only events relevant to their selected artists
- **Reliable**: Works offline with cached data

### For Developers
- **Scalable**: Database caching reduces API costs
- **Maintainable**: Clean separation between data sources
- **Robust**: Multiple fallback layers prevent empty states
- **Extensible**: Easy to add more event sources (Spotify, Bandsintown, etc.)

## Future Enhancements

### Additional Data Sources
- [ ] **Spotify API** for new releases and artist updates
- [ ] **Bandsintown API** for additional concert data
- [ ] **Artist Social Media** feeds for real-time updates

### Advanced Features
- [ ] **Push Notifications** for breaking news about user's artists
- [ ] **Event Reminders** with calendar integration
- [ ] **Price Alerts** for concert tickets
- [ ] **Location-Based Filtering** for nearby events

## Troubleshooting

### No Events Showing
1. Check if user has selected artists in onboarding
2. Verify Ticketmaster API key is set correctly
3. Check Supabase functions are deployed and working
4. Look at connection status indicator in the app

### API Errors
- The app automatically falls back to cached data
- Check Supabase function logs for detailed error messages
- Verify environment variables are set in Supabase

### Database Issues
- Run the events_schema.sql to ensure tables exist
- Check Row Level Security policies are applied
- Verify service role key has proper permissions

## Development Testing

To test locally without API keys:
1. The app will show connection status as "API not configured"
2. Sample events will be used as fallback
3. Database caching will still work for any manual test data

The integration is designed to work gracefully even without API keys, making development and testing easier.