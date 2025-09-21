#!/bin/bash

# PiggyBong Resend Email Test Script
# Test your Resend SMTP configuration

echo "🐷 Testing PiggyBong Resend Email Setup..."
echo "======================================="

# Test 1: Check if Resend API key is set
echo "📧 Testing Resend API connection..."
curl -X POST 'https://api.resend.com/emails' \
  -H 'Authorization: Bearer YOUR_RESEND_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "from": "PiggyBong <noreply@piggybong.com>",
    "to": ["test@example.com"],
    "subject": "PiggyBong Test Email 🐷",
    "html": "<h1>Hello from PiggyBong!</h1><p>Your K-pop spending tracker is ready! 🎤</p>"
  }'

echo ""
echo "🧪 Testing Supabase Auth Email..."

# Test 2: Test Supabase Auth email sending
curl -X POST "https://lxnenbhkmdvjsmnripax.supabase.co/auth/v1/recover" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4bmVuYmhrbWR2anNtbnJpcGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNzYyODQsImV4cCI6MjA2ODg1MjI4NH0.ykqeirIevUiJLWOMDznw7Sw0H1EZRqqXETrT23_VOv0" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

echo ""
echo "✅ Test complete! Check your inbox for test emails."
echo "🎯 Next steps:"
echo "   1. Replace YOUR_RESEND_API_KEY with your actual API key"
echo "   2. Replace test@example.com with your email"
echo "   3. Verify domain in Resend dashboard"
echo "   4. Update Supabase SMTP settings"