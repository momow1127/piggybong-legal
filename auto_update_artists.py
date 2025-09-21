import requests
from datetime import datetime
import os

# Your Supabase credentials from environment variables
SUPABASE_URL = os.environ.get('SUPABASE_URL', 'https://your-project.supabase.co')
SUPABASE_KEY = os.environ.get('SUPABASE_ANON_KEY', 'your_anon_key_here')

# New artists to add (update this list monthly)
NEW_ARTISTS_2025 = [
    {"name": "RIIZE", "type": "boy_group", "agency": "SM Entertainment"},
    {"name": "BOYNEXTDOOR", "type": "boy_group", "agency": "HYBE"},
    {"name": "TWS", "type": "boy_group", "agency": "PLEDIS"},
    {"name": "UNIS", "type": "girl_group", "agency": "F&F Entertainment"},
    {"name": "MEOVV", "type": "girl_group", "agency": "THEBLACKLABEL"},
    # Add more as they debut
]

def add_artist_to_supabase(artist):
    """Add a single artist to Supabase"""
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    # Check if artist already exists
    check_url = f'{SUPABASE_URL}/rest/v1/artists?name=eq.{artist["name"]}'
    check_response = requests.get(check_url, headers=headers)
    
    if check_response.json():  # Artist already exists
        print(f"⏭️  {artist['name']} already exists, skipping...")
        return False
    
    # Add new artist
    artist_data = {
        "name": artist["name"],
        "type": artist["type"],
        "agency": artist.get("agency", ""),
        "genres": ["K-pop"],
        "popularity": 50,
        "debut_year": 2025,
        "created_at": datetime.now().isoformat()
    }
    
    response = requests.post(
        f'{SUPABASE_URL}/rest/v1/artists',
        json=artist_data,
        headers=headers
    )
    
    if response.status_code == 201:
        print(f"✅ Added {artist['name']} successfully!")
        return True
    else:
        print(f"❌ Error adding {artist['name']}: {response.text}")
        return False

def update_all_artists():
    """Add all new artists to database"""
    print(f"🎵 Starting artist update - {datetime.now()}")
    print("-" * 40)
    
    added_count = 0
    for artist in NEW_ARTISTS_2025:
        if add_artist_to_supabase(artist):
            added_count += 1
    
    print("-" * 40)
    print(f"✨ Update complete! Added {added_count} new artists.")

if __name__ == "__main__":
    update_all_artists()