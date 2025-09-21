import feedparser
import requests
from datetime import datetime
import time
import os

# Your Supabase credentials from environment variables
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://your-project.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_ANON_KEY', 'your_anon_key_here')

# K-pop RSS feeds
RSS_FEEDS = [
    "https://www.soompi.com/feed",
    "https://www.allkpop.com/feed"
]

# Artists to track
ARTISTS = [
    'BTS', 'BLACKPINK', 'Stray Kids', 'NewJeans', 'SEVENTEEN',
    'aespa', 'IVE', 'TWICE', 'ATEEZ', 'TXT', 'ENHYPEN'
]

def check_rss_feeds():
    """Simple function to check RSS feeds for artist news"""
    
    for feed_url in RSS_FEEDS:
        # Get RSS feed
        feed = feedparser.parse(feed_url)
        
        for entry in feed.entries[:10]:  # Check latest 10 articles
            title = entry.title.lower()
            description = entry.get('description', '').lower()
            
            # Check if any artist is mentioned
            for artist in ARTISTS:
                if artist.lower() in title or artist.lower() in description:
                    # Found artist mention! Save to database
                    save_to_supabase({
                        'artist_name': artist,
                        'title': entry.title,
                        'url': entry.link,
                        'published': entry.published,
                        'source': feed_url
                    })
                    print(f"Found {artist} news: {entry.title}")
                    break

def save_to_supabase(data):
    """Save article to Supabase"""
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Save to your artist_updates table
    response = requests.post(
        f'{SUPABASE_URL}/rest/v1/artist_updates',
        json=data,
        headers=headers
    )
    
    if response.status_code == 201:
        print("✅ Saved to database")
    else:
        print(f"❌ Error: {response.text}")

# Run every hour
if __name__ == "__main__":
    while True:
        print(f"Checking feeds at {datetime.now()}")
        check_rss_feeds()
        time.sleep(3600)  # Wait 1 hour