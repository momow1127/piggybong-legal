# PiggyBong Database Setup Guide

## Option 1: Using Supabase Cloud (Recommended for Production)

1. **Create a Supabase Project**
   - Go to https://app.supabase.com/
   - Click "New Project"
   - Choose your organization
   - Enter project name: "PiggyBong"
   - Choose a region close to your users
   - Generate a strong password

2. **Get Your Credentials**
   - Go to Settings > API
   - Copy your Project URL and Project API Key (anon key)
   - Set environment variables or update Config.swift:
     ```bash
     export SUPABASE_URL="https://your-project-id.supabase.co"
     export SUPABASE_ANON_KEY="your-anon-key-here"
     ```

3. **Set Up the Database Schema**
   - Go to SQL Editor in your Supabase dashboard
   - Copy the contents of `database_schema.sql`
   - Run the script to create all tables, functions, and sample data

## Option 2: Using Local Development (Requires Docker)

1. **Start Local Supabase**
   ```bash
   cd "/Users/momow1127/Desktop/Desktop/Portfolio/My Project/AI/PiggyBong-main"
   supabase start
   ```

2. **Apply Database Schema**
   ```bash
   supabase db reset
   ```

3. **The Local URLs will be:**
   - API URL: http://127.0.0.1:54321
   - Studio: http://127.0.0.1:54323
   - Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

## Current Status

✅ **Completed:**
- Database schema created (database_schema.sql)
- SupabaseService updated with HTTP client
- Config.swift updated with environment variable support
- Fallback to mock data if database unavailable

⏳ **Next Steps:**
- Set up actual Supabase project (cloud or local)
- Update environment variables with real credentials
- Test database connection
- Implement real user authentication

## Testing the Connection

The app will automatically fall back to mock data if the database is unavailable, so you can:

1. Run the app with placeholder credentials → Uses mock data
2. Set up real Supabase project → Uses real database
3. Switch between mock and real data seamlessly

## Database Tables Created

- `users` - User profiles and budget settings
- `artists` - K-pop artists/groups (pre-populated with popular groups)
- `purchases` - User purchase tracking
- `budgets` - Monthly budget management
- `artist_budget_allocations` - Budget allocation per artist

## Features Included

- Row Level Security (RLS) for data protection
- Automatic budget calculations via triggers
- Sample K-pop artist data
- User spending analytics view
- Proper indexing for performance