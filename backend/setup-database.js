const { createClient } = require('@supabase/supabase-js');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

dotenv.config();

// Initialize Supabase client with service key for admin operations
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

async function setupDatabase() {
  console.log('🚀 Setting up Franchise Player database...');
  
  try {
    // Read the SQL file
    const sqlPath = path.join(__dirname, 'setup-database.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('📝 Executing SQL setup...');
    
    // Execute the SQL commands
    const { data, error } = await supabase.rpc('exec_sql', { sql: sqlContent });
    
    if (error) {
      console.error('❌ Error executing SQL:', error);
      
      // If the RPC method doesn't exist, let's try a different approach
      console.log('🔄 Trying alternative approach...');
      
      // Execute SQL commands one by one
      const commands = sqlContent
        .split(';')
        .map(cmd => cmd.trim())
        .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));
      
      for (const command of commands) {
        if (command.trim()) {
          console.log(`Executing: ${command.substring(0, 50)}...`);
          const { error: cmdError } = await supabase.rpc('exec_sql', { sql: command });
          if (cmdError) {
            console.error(`Error with command: ${cmdError.message}`);
          }
        }
      }
    } else {
      console.log('✅ Database setup completed successfully!');
    }
    
    // Test the setup by trying to create the table manually
    console.log('🧪 Testing table creation...');
    
    const createTableSQL = `
      CREATE TABLE IF NOT EXISTS json_uploads (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        payload JSONB NOT NULL,
        uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `;
    
    const { error: tableError } = await supabase.rpc('exec_sql', { sql: createTableSQL });
    
    if (tableError) {
      console.log('⚠️  Note: Some operations may require manual execution in Supabase dashboard');
      console.log('📋 Please run the SQL commands from setup-database.sql in your Supabase SQL Editor');
    } else {
      console.log('✅ Table created successfully!');
    }
    
  } catch (error) {
    console.error('❌ Setup failed:', error);
    console.log('📋 Please run the SQL commands from setup-database.sql manually in your Supabase SQL Editor');
  }
}

// Run the setup
setupDatabase(); 