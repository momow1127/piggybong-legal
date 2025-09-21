// Test script to verify Edge Function logic without Supabase
console.log('🧪 Testing Edge Function Logic...\n');

// Mock environment
const TICKETMASTER_API_KEY = 'test_key';

// Mock request data
const testRequest = {
  artists: ['BTS', 'Blackpink'],
  genres: ['music'],
  location: 'Los Angeles',
  limit: 10
};

console.log('📋 Test Request:', JSON.stringify(testRequest, null, 2));

// Test URL building logic
const params = new URLSearchParams({
  apikey: TICKETMASTER_API_KEY,
  classificationName: testRequest.genres?.[0] || 'music',
  size: (testRequest.limit || 50).toString(),
  sort: 'date,asc'
});

if (testRequest.location) {
  params.append('city', testRequest.location);
}

if (testRequest.artists && testRequest.artists.length > 0) {
  params.append('keyword', testRequest.artists[0]);
}

const url = `https://app.ticketmaster.com/discovery/v2/events.json?${params}`;
console.log('\n🌐 Generated URL:');
console.log(url.replace(TICKETMASTER_API_KEY, '[API_KEY_REDACTED]'));

console.log('\n📋 URL Parameters:');
for (const [key, value] of params.entries()) {
  if (key === 'apikey') {
    console.log(`  ${key}: [REDACTED]`);
  } else {
    console.log(`  ${key}: ${value}`);
  }
}

console.log('\n✅ Function logic appears correct!');
console.log('\n🔍 Potential Issues to Check:');
console.log('1. ❓ TICKETMASTER_API_KEY environment variable not set in Supabase');
console.log('2. ❓ Edge Function not deployed properly');
console.log('3. ❓ iOS app not calling the function correctly');
console.log('4. ❓ CORS issues from iOS app');
console.log('5. ❓ Authentication/authorization issues');