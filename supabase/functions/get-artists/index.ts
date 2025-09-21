import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
};

console.info('Get artists edge function started');

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Supabase configuration missing');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse query parameters for filtering and pagination
    const url = new URL(req.url);
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const offset = parseInt(url.searchParams.get('offset') || '0');
    const type = url.searchParams.get('type'); // Filter by artist type
    const search = url.searchParams.get('search'); // Search by name

    console.log(`Fetching artists: limit=${limit}, offset=${offset}, type=${type}, search=${search}`);

    // Build the query
    let query = supabase
      .from('artists')
      .select('id, name, type, image_url, genres, created_at')
      .order('name');

    // Apply filters
    if (type) {
      query = query.eq('type', type);
    }

    if (search) {
      query = query.ilike('name', `%${search}%`);
    }

    // Apply pagination
    if (offset > 0) {
      query = query.range(offset, offset + limit - 1);
    } else {
      query = query.limit(limit);
    }

    const { data: artists, error } = await query;

    if (error) {
      console.error('Database query error:', error);
      throw error;
    }

    // Get total count for pagination
    let countQuery = supabase
      .from('artists')
      .select('id', { count: 'exact', head: true });

    if (type) {
      countQuery = countQuery.eq('type', type);
    }

    if (search) {
      countQuery = countQuery.ilike('name', `%${search}%`);
    }

    const { count, error: countError } = await countQuery;

    if (countError) {
      console.warn('Count query error:', countError);
    }

    // Format response data
    const formattedData = {
      artists: artists?.map((artist) => ({
        id: artist.id,
        name: artist.name,
        type: artist.type,
        image_url: artist.image_url,
        genres: artist.genres || [],
        popularity_score: 0
      })) || [],
      pagination: {
        total: count || 0,
        limit,
        offset,
        has_more: (count || 0) > (offset + limit)
      },
      filters: {
        type,
        search
      }
    };

    console.log(`Successfully fetched ${artists?.length || 0} artists`);

    return new Response(
      JSON.stringify(formattedData),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=300' // Cache for 5 minutes
        }
      }
    );

  } catch (error) {
    console.error('Error in get-artists function:', error);

    return new Response(
      JSON.stringify({
        error: 'Failed to fetch artists',
        details: error.message,
        artists: [],
        pagination: {
          total: 0,
          limit: 50,
          offset: 0,
          has_more: false
        }
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    );
  }
});