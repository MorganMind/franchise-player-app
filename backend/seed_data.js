const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'your-service-role-key';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function seedData() {
  console.log('🌱 Starting database seeding...');

  try {
    // 1. Create sample servers
    console.log('📡 Creating servers...');
    const servers = [
      {
        name: 'Franchise Player League',
        description: 'The official Madden X franchise league',
        icon_url: 'https://via.placeholder.com/150/FF6B35/FFFFFF?text=FP',
        owner_id: null, // Will be set to first user
      },
      {
        name: 'AFC East Division',
        description: 'AFC East team discussions and coordination',
        icon_url: 'https://via.placeholder.com/150/1E3A8A/FFFFFF?text=AE',
        owner_id: null,
      },
      {
        name: 'NFC West Division',
        description: 'NFC West team discussions and coordination',
        icon_url: 'https://via.placeholder.com/150/DC2626/FFFFFF?text=NW',
        owner_id: null,
      },
      {
        name: 'Trade Discussions',
        description: 'League-wide trade discussions and negotiations',
        icon_url: 'https://via.placeholder.com/150/059669/FFFFFF?text=TD',
        owner_id: null,
      },
      {
        name: 'Draft Planning',
        description: 'Draft strategy and player discussions',
        icon_url: 'https://via.placeholder.com/150/7C3AED/FFFFFF?text=DP',
        owner_id: null,
      }
    ];

    // Insert servers
    const { data: serverData, error: serverError } = await supabase
      .from('servers')
      .insert(servers)
      .select();

    if (serverError) {
      console.error('Error creating servers:', serverError);
      return;
    }

    console.log(`✅ Created ${serverData.length} servers`);

    // 2. Create sample user profiles (if they don't exist)
    console.log('👥 Creating user profiles...');
    
    // Get all auth users
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
    
    if (authError) {
      console.error('Error fetching auth users:', authError);
      return;
    }

    const userProfiles = authUsers.users.map(user => ({
      id: user.id,
      username: user.email?.split('@')[0] || `user_${user.id.substring(0, 8)}`,
      display_name: user.user_metadata?.full_name || user.email?.split('@')[0] || 'User',
      avatar_url: user.user_metadata?.avatar_url || null,
      status: 'online'
    }));

    // Insert user profiles (upsert to avoid conflicts)
    const { data: profileData, error: profileError } = await supabase
      .from('user_profiles')
      .upsert(userProfiles, { onConflict: 'id' })
      .select();

    if (profileError) {
      console.error('Error creating user profiles:', profileError);
      return;
    }

    console.log(`✅ Created/updated ${profileData.length} user profiles`);

    // 3. Create server memberships
    console.log('👥 Creating server memberships...');
    
    const serverMembers = [];
    const firstUserId = profileData[0]?.id;

    for (const server of serverData) {
      // Add all users to the main league server
      for (const profile of profileData) {
        serverMembers.push({
          server_id: server.id,
          user_id: profile.id,
          nickname: profile.display_name,
          joined_at: new Date().toISOString(),
        });
      }
    }

    const { data: memberData, error: memberError } = await supabase
      .from('server_members')
      .upsert(serverMembers, { onConflict: 'server_id,user_id' })
      .select();

    if (memberError) {
      console.error('Error creating server members:', memberError);
      return;
    }

    console.log(`✅ Created ${memberData.length} server memberships`);

    // 4. Create channel categories
    console.log('📂 Creating channel categories...');
    
    const categories = [
      { server_id: serverData[0].id, name: 'General', position: 0 },
      { server_id: serverData[0].id, name: 'Announcements', position: 1 },
      { server_id: serverData[0].id, name: 'Game Discussion', position: 2 },
      { server_id: serverData[0].id, name: 'Trades', position: 3 },
      { server_id: serverData[0].id, name: 'Draft', position: 4 },
      { server_id: serverData[0].id, name: 'Voice Channels', position: 5 },
    ];

    const { data: categoryData, error: categoryError } = await supabase
      .from('channel_categories')
      .insert(categories)
      .select();

    if (categoryError) {
      console.error('Error creating categories:', categoryError);
      return;
    }

    console.log(`✅ Created ${categoryData.length} channel categories`);

    // 5. Create channels
    console.log('📺 Creating channels...');
    
    const channels = [
      { server_id: serverData[0].id, category_id: categoryData[0].id, name: 'general', description: 'General discussion', type: 'text', position: 0 },
      { server_id: serverData[0].id, category_id: categoryData[1].id, name: 'announcements', description: 'League announcements', type: 'text', position: 0 },
      { server_id: serverData[0].id, category_id: categoryData[2].id, name: 'game-discussion', description: 'Game strategy and discussion', type: 'text', position: 0 },
      { server_id: serverData[0].id, category_id: categoryData[3].id, name: 'trades', description: 'Trade discussions', type: 'text', position: 0 },
      { server_id: serverData[0].id, category_id: categoryData[4].id, name: 'draft', description: 'Draft planning and strategy', type: 'text', position: 0 },
      { server_id: serverData[0].id, category_id: categoryData[5].id, name: 'General Voice', description: 'Voice chat for general discussion', type: 'voice', position: 0, voice_enabled: true },
      { server_id: serverData[0].id, category_id: categoryData[5].id, name: 'Game Night', description: 'Voice chat during games', type: 'voice', position: 1, voice_enabled: true },
    ];

    const { data: channelData, error: channelError } = await supabase
      .from('channels')
      .insert(channels)
      .select();

    if (channelError) {
      console.error('Error creating channels:', channelError);
      return;
    }

    console.log(`✅ Created ${channelData.length} channels`);

    // 6. Create self-DM conversations for all users
    console.log('💬 Creating self-DM conversations...');
    
    const dmChannels = [];
    const dmParticipants = [];
    const welcomeMessages = [];

    for (const profile of profileData) {
      // Create DM channel
      const dmChannel = {
        id: `self-dm-${profile.id}`,
        created_at: new Date().toISOString(),
      };
      dmChannels.push(dmChannel);

      // Add participant (self)
      dmParticipants.push({
        dm_channel_id: dmChannel.id,
        user_id: profile.id,
        joined_at: new Date().toISOString(),
      });

      // Add welcome message
      welcomeMessages.push({
        dm_channel_id: dmChannel.id,
        author_id: profile.id,
        content: `Welcome to your personal DM space, ${profile.display_name}! You can use this to save notes, draft messages, or just chat with yourself.`,
        created_at: new Date().toISOString(),
      });
    }

    // Insert DM channels
    const { data: dmChannelData, error: dmChannelError } = await supabase
      .from('dm_channels')
      .upsert(dmChannels, { onConflict: 'id' })
      .select();

    if (dmChannelError) {
      console.error('Error creating DM channels:', dmChannelError);
      return;
    }

    // Insert DM participants
    const { data: dmParticipantData, error: dmParticipantError } = await supabase
      .from('dm_participants')
      .upsert(dmParticipants, { onConflict: 'dm_channel_id,user_id' })
      .select();

    if (dmParticipantError) {
      console.error('Error creating DM participants:', dmParticipantError);
      return;
    }

    // Insert welcome messages
    const { data: messageData, error: messageError } = await supabase
      .from('messages')
      .insert(welcomeMessages)
      .select();

    if (messageError) {
      console.error('Error creating welcome messages:', messageError);
      return;
    }

    console.log(`✅ Created ${dmChannelData.length} self-DM conversations with welcome messages`);

    // 7. Create some sample messages in general channel
    console.log('💬 Creating sample messages...');
    
    const sampleMessages = [
      {
        channel_id: channelData[0].id, // general channel
        author_id: profileData[0]?.id,
        content: 'Welcome to the Franchise Player League! 🏈',
        created_at: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
      },
      {
        channel_id: channelData[0].id,
        author_id: profileData[1]?.id,
        content: 'Excited to be here! Looking forward to some great games.',
        created_at: new Date(Date.now() - 82800000).toISOString(), // 23 hours ago
      },
      {
        channel_id: channelData[0].id,
        author_id: profileData[0]?.id,
        content: 'Don\'t forget to check the rules channel for league guidelines.',
        created_at: new Date(Date.now() - 79200000).toISOString(), // 22 hours ago
      },
      {
        channel_id: channelData[3].id, // trades channel
        author_id: profileData[2]?.id,
        content: 'Anyone interested in trading for a running back?',
        created_at: new Date(Date.now() - 72000000).toISOString(), // 20 hours ago
      },
    ];

    const { data: sampleMessageData, error: sampleMessageError } = await supabase
      .from('messages')
      .insert(sampleMessages)
      .select();

    if (sampleMessageError) {
      console.error('Error creating sample messages:', sampleMessageError);
      return;
    }

    console.log(`✅ Created ${sampleMessageData.length} sample messages`);

    console.log('🎉 Database seeding completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - ${serverData.length} servers created`);
    console.log(`   - ${profileData.length} user profiles created/updated`);
    console.log(`   - ${memberData.length} server memberships created`);
    console.log(`   - ${categoryData.length} channel categories created`);
    console.log(`   - ${channelData.length} channels created`);
    console.log(`   - ${dmChannelData.length} self-DM conversations created`);
    console.log(`   - ${sampleMessageData.length} sample messages created`);

  } catch (error) {
    console.error('❌ Error during seeding:', error);
  }
}

// Run the seeding function
seedData(); 