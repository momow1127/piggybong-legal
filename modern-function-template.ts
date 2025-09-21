// Modern Supabase Edge Function Template (2025)
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

// Standard CORS headers for all responses
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE'
};

// Environment validation
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
for (const envVar of requiredEnvVars) {
  if (!Deno.env.get(envVar)) {
    console.error(`❌ Missing required environment variable: ${envVar}`);
  }
}

serve(async (req) => {
  const startTime = Date.now();
  const requestId = crypto.randomUUID().slice(0, 8);

  console.log(`📝 [${requestId}] ${req.method} ${req.url} - ${new Date().toISOString()}`);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    console.log(`✅ [${requestId}] CORS preflight handled`);
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Parse request body safely
    let requestBody = {};
    try {
      if (req.body) {
        requestBody = await req.json();
        console.log(`📋 [${requestId}] Request body:`, JSON.stringify(requestBody, null, 2));
      }
    } catch (parseError) {
      console.error(`❌ [${requestId}] Invalid JSON in request body:`, parseError);
      return createErrorResponse('Invalid JSON in request body', 400, requestId);
    }

    // TODO: Add your business logic here
    const result = {
      message: 'Success',
      data: requestBody,
      requestId,
      timestamp: new Date().toISOString()
    };

    console.log(`✅ [${requestId}] Success - Duration: ${Date.now() - startTime}ms`);

    return new Response(JSON.stringify(result), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
        'X-Request-ID': requestId
      }
    });

  } catch (error) {
    console.error(`💥 [${requestId}] Function error:`, error);
    console.error(`📍 [${requestId}] Error stack:`, error.stack);

    return createErrorResponse(
      error.message || 'Internal server error',
      500,
      requestId
    );
  }
});

// Helper function for consistent error responses
function createErrorResponse(message: string, status: number = 500, requestId?: string) {
  const errorResponse = {
    error: message,
    status,
    requestId,
    timestamp: new Date().toISOString()
  };

  return new Response(JSON.stringify(errorResponse), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      'X-Request-ID': requestId || 'unknown'
    }
  });
}

// Helper function for consistent success responses
function createSuccessResponse(data: any, requestId?: string) {
  const response = {
    data,
    success: true,
    requestId,
    timestamp: new Date().toISOString()
  };

  return new Response(JSON.stringify(response), {
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      'X-Request-ID': requestId || 'unknown'
    }
  });
}