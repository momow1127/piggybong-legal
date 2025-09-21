import { serve } from "https://deno.land/std@0.224.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface APNServiceRequest {
  device_tokens: string[]
  title: string
  body: string
  badge?: number
  sound?: string
  category?: string
  data?: Record<string, any>
  environment?: 'development' | 'production'
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  try {
    const {
      device_tokens,
      title,
      body,
      badge = 1,
      sound = 'default',
      category,
      data,
      environment = 'development'
    } = await req.json() as APNServiceRequest

    console.log(`🍎 APN Service - Sending to ${device_tokens.length} devices (${environment})`)

    // Create JWT token for Apple Push Notification service authentication
    // This would use your .p12 certificates converted to JWT format
    const apnJWT = await createAPNJWT(environment)

    const results = await Promise.allSettled(
      device_tokens.map(token => sendToDevice(token, {
        title,
        body,
        badge,
        sound,
        category,
        data
      }, apnJWT, environment))
    )

    const successful = results.filter(r => r.status === 'fulfilled').length
    const failed = results.filter(r => r.status === 'rejected').length

    console.log(`📊 APN Results: ${successful} sent, ${failed} failed`)

    return new Response(
      JSON.stringify({
        success: true,
        sent_count: successful,
        failed_count: failed,
        total_devices: device_tokens.length
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('❌ APN Service error:', error)
    return new Response(
      JSON.stringify({
        error: 'APN service failed',
        details: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function createAPNJWT(environment: string): Promise<string> {
  console.log(`🔐 Creating APN JWT for ${environment} environment`)

  try {
    // Get base64 certificate from environment variables
    const certEnvVar = environment === 'production' ? 'APN_PRODUCTION_CERT_BASE64' : 'APN_DEVELOPMENT_CERT_BASE64'
    const certificateBase64 = Deno.env.get(certEnvVar)

    if (!certificateBase64) {
      throw new Error(`Certificate not found in environment variable: ${certEnvVar}`)
    }

    const teamId = Deno.env.get('APN_TEAM_ID')
    const bundleId = Deno.env.get('APN_BUNDLE_ID')

    if (!teamId || !bundleId) {
      throw new Error('Missing APN_TEAM_ID or APN_BUNDLE_ID environment variables')
    }

    // For now, we'll use the certificate directly
    // In a full implementation, you'd create a proper JWT token here
    // Decode base64 certificate
    const certificateBuffer = Uint8Array.from(atob(certificateBase64), c => c.charCodeAt(0))

    console.log(`✅ Certificate loaded for ${environment}`)
    console.log(`📱 Bundle ID: ${bundleId}`)
    console.log(`🏢 Team ID: ${teamId}`)
    console.log(`📊 Certificate size: ${certificateBuffer.length} bytes`)

    return `CERT_LOADED_${environment.toUpperCase()}`
  } catch (error) {
    console.error(`❌ Failed to load certificate for ${environment}:`, error)
    throw error
  }
}

async function sendToDevice(
  deviceToken: string,
  payload: {
    title: string
    body: string
    badge: number
    sound: string
    category?: string
    data?: Record<string, any>
  },
  jwt: string,
  environment: string
): Promise<boolean> {

  const apnUrl = environment === 'production'
    ? `https://api.push.apple.com/3/device/${deviceToken}`
    : `https://api.development.push.apple.com/3/device/${deviceToken}`

  const apnPayload = {
    aps: {
      alert: {
        title: payload.title,
        body: payload.body
      },
      badge: payload.badge,
      sound: payload.sound,
      'content-available': 1
    },
    ...payload.data
  }

  if (payload.category) {
    apnPayload.aps.category = payload.category
  }

  try {
    console.log(`📱 Sending to device: ${deviceToken.substring(0, 8)}...`)
    console.log(`📦 Payload:`, JSON.stringify(apnPayload, null, 2))

    // Check if we have a valid JWT (certificate loaded)
    if (!jwt.startsWith('CERT_LOADED_')) {
      console.error(`❌ Invalid certificate for ${environment}`)
      return false
    }

    // Get certificate from environment
    const certEnvVar = environment === 'production' ? 'APN_PRODUCTION_CERT' : 'APN_DEVELOPMENT_CERT'
    const certificate = Deno.env.get(certEnvVar)
    const bundleId = Deno.env.get('APN_BUNDLE_ID')

    if (!certificate || !bundleId) {
      console.error(`❌ Missing certificate or bundle ID`)
      return false
    }

    // Make HTTP/2 request to Apple Push Notification service
    const response = await fetch(apnUrl, {
      method: 'POST',
      headers: {
        'apns-topic': bundleId,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        'Content-Type': 'application/json',
        // Note: In production, you'd use proper certificate-based authentication
        // For now, we're using the certificate content as verification
      },
      body: JSON.stringify(apnPayload)
    })

    if (response.ok) {
      console.log(`✅ Successfully sent to device: ${deviceToken.substring(0, 8)}...`)
      return true
    } else {
      const errorText = await response.text()
      console.error(`❌ APN request failed: ${response.status} ${response.statusText}`)
      console.error(`Error details: ${errorText}`)
      return false
    }

  } catch (error) {
    console.error(`❌ Failed to send to device ${deviceToken}:`, error)
    return false
  }
}

/*
PRODUCTION SETUP INSTRUCTIONS:

1. Export your certificates as .p12 files from Keychain:
   - PiggyBong_Development_Push.p12
   - PiggyBong_Production_Push.p12

2. Convert .p12 to PEM format:
   openssl pkcs12 -in PiggyBong_Development_Push.p12 -out development_key.pem -nodes -clcerts

3. Create environment variables in Supabase:
   - APN_DEVELOPMENT_KEY (PEM content)
   - APN_PRODUCTION_KEY (PEM content)
   - APN_TEAM_ID (Your Apple Developer Team ID: 4V55KN5U7M)
   - APN_KEY_ID (From Apple Developer Console)

4. Update createAPNJWT() function to use actual certificates
5. Enable HTTP/2 requests to Apple's push servers
6. Add proper error handling for different APN response codes

For more details, see Apple's documentation:
https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server
*/