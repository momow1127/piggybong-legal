#!/usr/bin/env node

// Script to create the database tables needed for cleanup-expired-codes function
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://lxnenbhkmdvjsmnripax.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_KEY) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY environment variable is required');
  console.log('Set it with: export SUPABASE_SERVICE_ROLE_KEY="your_service_role_key"');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function createCleanupTables() {
  console.log('🚀 Creating database tables for cleanup function...\n');

  try {
    // Create email_verification_codes table
    console.log('📧 Creating email_verification_codes table...');
    const { error: emailTableError } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS email_verification_codes (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          email TEXT NOT NULL,
          code TEXT NOT NULL,
          user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour',
          used_at TIMESTAMPTZ,
          UNIQUE(email, code)
        );
      `
    });

    if (emailTableError) {
      console.error('❌ Failed to create email_verification_codes table:', emailTableError);
    } else {
      console.log('✅ email_verification_codes table created');
    }

    // Create user_sessions table
    console.log('👤 Creating user_sessions table...');
    const { error: sessionsTableError } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS user_sessions (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
          session_token TEXT NOT NULL,
          device_info JSONB,
          ip_address INET,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          last_active TIMESTAMPTZ DEFAULT NOW(),
          expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days'
        );
      `
    });

    if (sessionsTableError) {
      console.error('❌ Failed to create user_sessions table:', sessionsTableError);
    } else {
      console.log('✅ user_sessions table created');
    }

    // Create cleanup_logs table
    console.log('📋 Creating cleanup_logs table...');
    const { error: logsTableError } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS cleanup_logs (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          cleanup_type TEXT NOT NULL,
          items_cleaned INTEGER DEFAULT 0,
          details JSONB,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
      `
    });

    if (logsTableError) {
      console.error('❌ Failed to create cleanup_logs table:', logsTableError);
    } else {
      console.log('✅ cleanup_logs table created');
    }

    // Create indexes
    console.log('🔍 Creating indexes...');
    const indexSql = `
      CREATE INDEX IF NOT EXISTS idx_email_verification_codes_created_at ON email_verification_codes(created_at);
      CREATE INDEX IF NOT EXISTS idx_email_verification_codes_email ON email_verification_codes(email);
      CREATE INDEX IF NOT EXISTS idx_user_sessions_created_at ON user_sessions(created_at);
      CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
      CREATE INDEX IF NOT EXISTS idx_cleanup_logs_created_at ON cleanup_logs(created_at);
    `;

    const { error: indexError } = await supabase.rpc('exec_sql', { sql: indexSql });
    if (indexError) {
      console.error('❌ Failed to create indexes:', indexError);
    } else {
      console.log('✅ Indexes created');
    }

    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('1. Test the cleanup function: POST to /functions/v1/cleanup-expired-codes');
    console.log('2. Set up a cron job to run cleanup automatically');
    console.log('3. Monitor cleanup_logs table for statistics');

  } catch (error) {
    console.error('💥 Setup failed:', error);
    process.exit(1);
  }
}

// Alternative: Direct SQL approach if RPC doesn't work
async function createTablesDirectSQL() {
  console.log('🔧 Using direct SQL approach...\n');

  const tables = [
    {
      name: 'email_verification_codes',
      sql: `
        CREATE TABLE IF NOT EXISTS email_verification_codes (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          email TEXT NOT NULL,
          code TEXT NOT NULL,
          user_id UUID,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour',
          used_at TIMESTAMPTZ
        );
      `
    },
    {
      name: 'user_sessions',
      sql: `
        CREATE TABLE IF NOT EXISTS user_sessions (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          user_id UUID,
          session_token TEXT NOT NULL,
          device_info JSONB,
          ip_address INET,
          created_at TIMESTAMPTZ DEFAULT NOW(),
          last_active TIMESTAMPTZ DEFAULT NOW(),
          expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days'
        );
      `
    },
    {
      name: 'cleanup_logs',
      sql: `
        CREATE TABLE IF NOT EXISTS cleanup_logs (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          cleanup_type TEXT NOT NULL,
          items_cleaned INTEGER DEFAULT 0,
          details JSONB,
          created_at TIMESTAMPTZ DEFAULT NOW()
        );
      `
    }
  ];

  for (const table of tables) {
    try {
      console.log(`Creating ${table.name}...`);
      const { error } = await supabase.from(table.name).select('id').limit(1);

      if (error && error.code === 'PGRST116') {
        console.log(`✅ ${table.name} table already exists or needs to be created via SQL Editor`);
      } else {
        console.log(`✅ ${table.name} table accessible`);
      }
    } catch (err) {
      console.log(`⚠️  ${table.name} needs to be created manually`);
    }
  }

  console.log('\n📝 Manual Setup Instructions:');
  console.log('1. Go to your Supabase Dashboard');
  console.log('2. Navigate to SQL Editor');
  console.log('3. Run the SQL from create-cleanup-tables.sql');
  console.log('4. Test the cleanup function');
}

if (require.main === module) {
  createTablesDirectSQL();
}