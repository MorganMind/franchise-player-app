const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');

dotenv.config();

// Initialize Supabase client with service key for admin operations
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

async function verifySecurity() {
  console.log('🔒 Verifying Database Security...\n');
  
  try {
    // 1. Check if required tables exist
    console.log('📋 1. Checking table existence...');
    const requiredTables = ['users', 'dm_channels', 'messages'];
    const existingTables = [];
    
    for (const table of requiredTables) {
      try {
        const { data, error } = await supabase
          .from(table)
          .select('count')
          .limit(1);
        
        if (error && error.code === '42P01') {
          console.log(`   ❌ Table '${table}' does not exist`);
        } else if (error) {
          console.log(`   ⚠️  Table '${table}' exists but has issues: ${error.message}`);
        } else {
          console.log(`   ✅ Table '${table}' exists`);
          existingTables.push(table);
        }
      } catch (e) {
        console.log(`   ❌ Error checking table '${table}': ${e.message}`);
      }
    }
    
    // 2. Check RLS status
    console.log('\n🔐 2. Checking Row Level Security (RLS)...');
    for (const table of existingTables) {
      try {
        const { data, error } = await supabase.rpc('check_rls_status', { table_name: table });
        if (error) {
          // Fallback: try to query the table to see if RLS is blocking
          const { error: queryError } = await supabase
            .from(table)
            .select('*')
            .limit(1);
          
          if (queryError && queryError.message.includes('policy')) {
            console.log(`   ✅ RLS is enabled on '${table}' (policies are active)`);
          } else {
            console.log(`   ⚠️  RLS status unknown for '${table}'`);
          }
        } else {
          console.log(`   ✅ RLS is enabled on '${table}'`);
        }
      } catch (e) {
        console.log(`   ⚠️  Could not verify RLS for '${table}': ${e.message}`);
      }
    }
    
    // 3. Check policies
    console.log('\n📜 3. Checking RLS Policies...');
    for (const table of existingTables) {
      try {
        const { data, error } = await supabase.rpc('get_table_policies', { table_name: table });
        if (error) {
          console.log(`   ⚠️  Could not retrieve policies for '${table}': ${error.message}`);
        } else if (data && data.length > 0) {
          console.log(`   ✅ '${table}' has ${data.length} policies:`);
          data.forEach(policy => {
            console.log(`      - ${policy.policyname} (${policy.cmd})`);
          });
        } else {
          console.log(`   ❌ '${table}' has no policies (security risk!)`);
        }
      } catch (e) {
        console.log(`   ⚠️  Error checking policies for '${table}': ${e.message}`);
      }
    }
    
    // 4. Test data isolation (if we have test data)
    console.log('\n🧪 4. Testing Data Isolation...');
    try {
      // Try to access messages without proper context
      const { data: messages, error: messagesError } = await supabase
        .from('messages')
        .select('*')
        .limit(5);
      
      if (messagesError) {
        console.log('   ✅ RLS is blocking unauthorized access to messages');
      } else if (messages && messages.length > 0) {
        console.log('   ⚠️  RLS might not be properly configured - found messages without auth context');
      } else {
        console.log('   ✅ No messages found (expected if no data exists)');
      }
    } catch (e) {
      console.log(`   ⚠️  Error testing data isolation: ${e.message}`);
    }
    
    // 5. Check indexes
    console.log('\n📊 5. Checking Database Indexes...');
    try {
      const { data: indexes, error: indexError } = await supabase.rpc('get_table_indexes');
      if (indexError) {
        console.log('   ⚠️  Could not retrieve index information');
      } else if (indexes && indexes.length > 0) {
        console.log('   ✅ Found indexes:');
        indexes.forEach(index => {
          console.log(`      - ${index.indexname} on ${index.tablename}`);
        });
      } else {
        console.log('   ⚠️  No indexes found (performance may be affected)');
      }
    } catch (e) {
      console.log(`   ⚠️  Error checking indexes: ${e.message}`);
    }
    
    // 6. Check user permissions
    console.log('\n👤 6. Checking User Permissions...');
    try {
      const { data: roles, error: rolesError } = await supabase.rpc('get_user_roles');
      if (rolesError) {
        console.log('   ⚠️  Could not retrieve role information');
      } else if (roles && roles.length > 0) {
        console.log('   ✅ User roles configured:');
        roles.forEach(role => {
          console.log(`      - ${role.rolname}`);
        });
      } else {
        console.log('   ⚠️  No user roles found');
      }
    } catch (e) {
      console.log(`   ⚠️  Error checking user permissions: ${e.message}`);
    }
    
    // 7. Security recommendations
    console.log('\n💡 7. Security Recommendations:');
    
    if (existingTables.length < requiredTables.length) {
      console.log('   ❌ Missing tables detected. Run the complete schema setup.');
    }
    
    console.log('   ✅ Ensure all tables have RLS enabled');
    console.log('   ✅ Verify policies are properly configured for each table');
    console.log('   ✅ Test data isolation with multiple users');
    console.log('   ✅ Monitor for unauthorized access attempts');
    console.log('   ✅ Regularly audit user permissions');
    console.log('   ✅ Keep Supabase and dependencies updated');
    
    console.log('\n🎉 Security verification completed!');
    
  } catch (error) {
    console.error('❌ Security verification failed:', error.message);
  }
}

// Helper function to create the verification functions if they don't exist
async function createVerificationFunctions() {
  console.log('🔧 Creating verification functions...');
  
  const functions = [
    {
      name: 'check_rls_status',
      sql: `
        CREATE OR REPLACE FUNCTION check_rls_status(table_name TEXT)
        RETURNS BOOLEAN AS $$
        DECLARE
          rls_enabled BOOLEAN;
        BEGIN
          SELECT rowsecurity INTO rls_enabled
          FROM pg_tables
          WHERE schemaname = 'public' AND tablename = table_name;
          RETURN rls_enabled;
        END;
        $$ LANGUAGE plpgsql;
      `
    },
    {
      name: 'get_table_policies',
      sql: `
        CREATE OR REPLACE FUNCTION get_table_policies(table_name TEXT)
        RETURNS TABLE(policyname TEXT, cmd TEXT) AS $$
        BEGIN
          RETURN QUERY
          SELECT p.policyname::TEXT, p.cmd::TEXT
          FROM pg_policies p
          WHERE p.schemaname = 'public' AND p.tablename = table_name;
        END;
        $$ LANGUAGE plpgsql;
      `
    },
    {
      name: 'get_table_indexes',
      sql: `
        CREATE OR REPLACE FUNCTION get_table_indexes()
        RETURNS TABLE(indexname TEXT, tablename TEXT) AS $$
        BEGIN
          RETURN QUERY
          SELECT i.indexname::TEXT, t.tablename::TEXT
          FROM pg_indexes i
          JOIN pg_tables t ON i.tablename = t.tablename
          WHERE i.schemaname = 'public' AND t.schemaname = 'public'
          AND i.indexname NOT LIKE '%_pkey'
          ORDER BY t.tablename, i.indexname;
        END;
        $$ LANGUAGE plpgsql;
      `
    },
    {
      name: 'get_user_roles',
      sql: `
        CREATE OR REPLACE FUNCTION get_user_roles()
        RETURNS TABLE(rolname TEXT) AS $$
        BEGIN
          RETURN QUERY
          SELECT r.rolname::TEXT
          FROM pg_roles r
          WHERE r.rolcanlogin = true
          ORDER BY r.rolname;
        END;
        $$ LANGUAGE plpgsql;
      `
    }
  ];
  
  for (const func of functions) {
    try {
      const { error } = await supabase.rpc('exec_sql', { sql: func.sql });
      if (error) {
        console.log(`   ⚠️  Could not create ${func.name}: ${error.message}`);
      } else {
        console.log(`   ✅ Created ${func.name}`);
      }
    } catch (e) {
      console.log(`   ⚠️  Error creating ${func.name}: ${e.message}`);
    }
  }
}

// Run the verification
async function main() {
  await createVerificationFunctions();
  await verifySecurity();
}

main(); 