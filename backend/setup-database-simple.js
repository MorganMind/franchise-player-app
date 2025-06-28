const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');

dotenv.config();

// Initialize Supabase client with service key for admin operations
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

async function setupDatabase() {
  console.log('🚀 Setting up Franchise Player database...');
  
  try {
    // Test connection first by checking if we can access the auth schema
    console.log('🔗 Testing Supabase connection...');
    
    // Try to access a system table to test connection
    const { data: testData, error: testError } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public')
      .limit(1);
    
    if (testError) {
      console.error('❌ Connection test failed:', testError.message);
      console.log('📋 Please check your SUPABASE_URL and SUPABASE_SERVICE_KEY in .env file');
      return;
    }
    
    console.log('✅ Supabase connection successful');
    
    // Check if json_uploads table exists
    console.log('📋 Checking if json_uploads table exists...');
    
    const { data: checkData, error: checkError } = await supabase
      .from('json_uploads')
      .select('count')
      .limit(1);
    
    if (checkError && checkError.code === '42P01') {
      console.log('❌ Table does not exist. Please create it manually in Supabase dashboard.');
      console.log('📋 Instructions:');
      console.log('   1. Go to your Supabase dashboard');
      console.log('   2. Click on "SQL Editor" in the left sidebar');
      console.log('   3. Create a new query');
      console.log('   4. Copy and paste the contents of setup-database.sql');
      console.log('   5. Click "Run"');
      return;
    }
    
    if (checkError) {
      console.log('⚠️  Table check error:', checkError.message);
    } else {
      console.log('✅ json_uploads table exists');
    }
    
    // Test inserting a record
    console.log('🧪 Testing table insert...');
    
    const testRecord = {
      payload: { test: 'data', message: 'Database setup test' },
      uploaded_at: new Date().toISOString()
    };
    
    const { data: insertData, error: insertError } = await supabase
      .from('json_uploads')
      .insert([testRecord])
      .select();
    
    if (insertError) {
      console.error('❌ Insert test failed:', insertError.message);
      console.log('📋 This might be due to:');
      console.log('   • Missing RLS policies');
      console.log('   • Incorrect table schema');
      console.log('   • Missing user_id field');
      console.log('📋 Please run the SQL setup manually in Supabase dashboard');
    } else {
      console.log('✅ Insert test successful');
      console.log('📝 Test record ID:', insertData[0].id);
      
      // Clean up test record
      const { error: deleteError } = await supabase
        .from('json_uploads')
        .delete()
        .eq('id', insertData[0].id);
      
      if (deleteError) {
        console.log('⚠️  Could not clean up test record:', deleteError.message);
      } else {
        console.log('🧹 Test record cleaned up');
      }
    }
    
    console.log('\n🎉 Database setup verification completed!');
    
  } catch (error) {
    console.error('❌ Setup failed:', error.message);
    console.log('📋 Please run the SQL commands from setup-database.sql manually in your Supabase SQL Editor');
  }
}

// Run the setup
setupDatabase(); 