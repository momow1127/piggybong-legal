// FIXES for delete-fan-idol Edge Function
// Apply these changes to your delete-fan-idol/index.ts

// 1. Replace the Supabase client initialization:
// OLD:
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// NEW:
// Initialize Supabase client with validation
const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing required environment variables')
  return new Response(
    JSON.stringify({ success: false, message: 'Service configuration error' }),
    { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}

const supabase = createClient(supabaseUrl, supabaseServiceKey)

// 2. Replace the JSON parsing:
// OLD:
const body = await req.json();
const { idolId, artistId } = body;

// NEW:
// Parse request body with error handling
let body: any
try {
  body = await req.json()
} catch (parseError) {
  return new Response(
    JSON.stringify({ success: false, message: 'Invalid JSON in request body' }),
    { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}

const { idolId, artistId } = body