import jwt, datetime

# Your Apple Developer credentials
TEAM_ID = "4V55KN5U7M"                    # Apple Team ID
CLIENT_ID = "carmenwong.PiggyBong"        # Your Service ID (correct one!)
KEY_ID = "YZ46W47739"                     # Key ID from your .p8 file
PRIVATE_KEY_FILE = "/Users/momow1127/Downloads/AuthKey_YZ46W47739.p8"

# Read the private key
with open(PRIVATE_KEY_FILE, "r") as f:
    private_key = f.read()

# JWT headers
headers = {
    "kid": KEY_ID,
    "alg": "ES256"
}

# JWT payload
payload = {
    "iss": TEAM_ID,
    "iat": datetime.datetime.utcnow(),
    "exp": datetime.datetime.utcnow() + datetime.timedelta(days=180),  # valid 6 months
    "aud": "https://appleid.apple.com",
    "sub": CLIENT_ID
}

# Generate the client secret JWT
client_secret = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)

print("🍎 Apple Sign-In Configuration for Supabase:")
print("=" * 50)
print(f"Client IDs: {CLIENT_ID}")
print(f"Secret Key: {client_secret}")
print("=" * 50)
print("\n📋 Instructions:")
print("1. Copy the Client IDs value into the 'Client IDs' field in Supabase")
print("2. Copy the Secret Key value into the 'Secret Key (for OAuth)' field in Supabase")
print("3. Save the configuration")
print("\n⚠️  Note: This secret expires in 6 months and will need to be regenerated")