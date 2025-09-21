# n8n Integration for Real-time Artist Updates

## Overview
This setup replaces polling-based artist monitoring with an efficient n8n workflow that provides real-time updates when users follow artists.

## Architecture

```
iOS App → Supabase → n8n Workflow → Social APIs → AI Processing → Database → Push Notifications
```

## Setup Steps

### 1. Deploy Supabase Functions
```bash
./deploy-functions.sh
```

### 2. Set Supabase Environment Variables
```bash
# Required for n8n integration
supabase secrets set N8N_WEBHOOK_URL=https://your-n8n-instance.com/webhook/artist-subscription
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 3. Run Database Schema
Execute `n8n_integration_schema.sql` in your Supabase SQL editor to create the required tables.

### 4. n8n Workflow Configuration

#### Workflow Structure:
1. **Webhook Trigger** - Receives artist subscription requests
2. **Social Media Monitor** - Twitter/Instagram/YouTube APIs
3. **Content Filter** - Remove spam/irrelevant content
4. **AI Enhancement** - Process content with OpenAI
5. **Database Store** - Save to Supabase
6. **Push Notification** - Notify subscribers

#### Sample n8n Workflow Nodes:

**Node 1: Webhook**
```json
{
  "httpMethod": "POST",
  "path": "artist-subscription",
  "responseMode": "responseNode"
}
```

**Node 2: Switch (Action Type)**
```json
{
  "conditions": {
    "options": {
      "caseSensitive": true,
      "leftValue": "={{$json.action}}",
      "typeValidation": "strict"
    },
    "conditions": [
      {
        "leftValue": "={{$json.action}}",
        "rightValue": "start_monitoring",
        "operator": {
          "type": "string",
          "operation": "equals"
        }
      },
      {
        "leftValue": "={{$json.action}}",
        "rightValue": "stop_monitoring",
        "operator": {
          "type": "string",
          "operation": "equals"
        }
      }
    ]
  }
}
```

**Node 3: Twitter API Monitor**
```json
{
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "twitterOAuth2Api",
  "resource": "search",
  "operation": "search",
  "query": "={{$json.artist_name}}",
  "additionalFields": {
    "result_type": "recent",
    "count": 10
  }
}
```

**Node 4: Content Filter (JavaScript)**
```javascript
// Filter out retweets, replies, and spam
const tweets = $input.all();
const filtered = tweets.filter(tweet => {
  const text = tweet.json.text || '';
  return !text.startsWith('@') && 
         !text.startsWith('RT') && 
         text.length > 50 &&
         !text.includes('spam_indicator');
});

return filtered.map(tweet => ({
  json: {
    artist_name: $('Webhook').first().json.artist_name,
    update_type: 'social_media',
    content: tweet.json.text,
    source_url: `https://twitter.com/user/status/${tweet.json.id}`,
    timestamp: tweet.json.created_at,
    priority: 'normal'
  }
}));
```

**Node 5: AI Content Enhancement**
```json
{
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "openAiApi",
  "resource": "chat",
  "operation": "message",
  "model": "gpt-4o-mini",
  "messages": {
    "values": [
      {
        "role": "system",
        "content": "Enhance this social media update for K-pop fans. Make it engaging but keep the original meaning. Max 200 chars."
      },
      {
        "role": "user", 
        "content": "={{$json.content}}"
      }
    ]
  }
}
```

**Node 6: Send to Supabase Webhook**
```json
{
  "url": "https://your-project.supabase.co/functions/v1/n8n-artist-webhook",
  "sendHeaders": true,
  "headerParameters": {
    "parameters": [
      {
        "name": "apikey",
        "value": "your_supabase_anon_key"
      },
      {
        "name": "Content-Type",
        "value": "application/json"
      }
    ]
  },
  "sendBody": true,
  "bodyParameters": {
    "parameters": [
      {
        "name": "artist_name",
        "value": "={{$json.artist_name}}"
      },
      {
        "name": "update_type", 
        "value": "={{$json.update_type}}"
      },
      {
        "name": "content",
        "value": "={{$json.enhanced_content || $json.content}}"
      },
      {
        "name": "source_url",
        "value": "={{$json.source_url}}"
      },
      {
        "name": "priority",
        "value": "={{$json.priority}}"
      }
    ]
  }
}
```

## iOS App Integration

### 1. Add Artist Subscription Service
The `ArtistSubscriptionService.swift` is already created and handles:
- Subscribe/unsubscribe to artists
- Manage notification preferences
- Fetch real-time updates

### 2. Update Your Views
```swift
// Example: Artist follow button
Button(action: {
    Task {
        if subscriptionService.isSubscribedTo(artist.name) {
            await subscriptionService.unsubscribeFromArtist(artist.name)
        } else {
            await subscriptionService.subscribeToArtist(artist.name)
        }
    }
}) {
    Text(subscriptionService.isSubscribedTo(artist.name) ? "Following" : "Follow")
}
.environmentObject(ArtistSubscriptionService.shared)
```

### 3. Display Updates
```swift
// In your news feed view
List(subscriptionService.updates) { update in
    ArtistUpdateRow(update: update)
}
.task {
    await subscriptionService.fetchUpdatesForSubscribedArtists()
}
```

## Benefits vs Current Approach

| Feature | Current (Polling) | n8n Workflow |
|---------|------------------|--------------|
| **Real-time** | ❌ 15min delay | ✅ Instant |
| **API Efficiency** | ❌ Constant polling | ✅ Event-driven |
| **Scalability** | ❌ Linear cost | ✅ Pay per event |
| **Reliability** | ❌ Rate limiting | ✅ Robust queuing |
| **Maintenance** | ❌ Complex iOS code | ✅ Visual workflow |

## Monitoring & Debugging

1. **n8n Dashboard** - Monitor workflow executions
2. **Supabase Logs** - Check edge function calls
3. **Database Tables** - Verify data flow
4. **iOS App** - Test subscription flows

## Next Steps

1. **Set up n8n instance** (cloud or self-hosted)
2. **Configure API credentials** (Twitter, Instagram, YouTube)
3. **Import workflow** using the nodes above
4. **Test with a popular artist** (e.g., "BTS")
5. **Monitor performance** and adjust thresholds

This architecture will dramatically improve your app's performance and user experience! 🚀