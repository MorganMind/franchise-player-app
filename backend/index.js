const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { createClient } = require('@supabase/supabase-js');

dotenv.config();
const app = express();

// Middleware
app.use(cors({
  origin: ['http://localhost:4000', 'http://192.168.1.164:3000'],
  credentials: true,
}));
app.use(express.json({ limit: '50mb' }));

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// Authentication middleware
const authenticateUser = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ 
      error: 'Authentication required',
      message: 'Please provide a valid Bearer token' 
    });
  }

  const token = authHeader.substring(7); // Remove 'Bearer ' prefix

  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      return res.status(401).json({ 
        error: 'Invalid token',
        message: 'Please provide a valid authentication token' 
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Auth error:', error);
    return res.status(401).json({ 
      error: 'Authentication failed',
      message: 'Invalid authentication token' 
    });
  }
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    message: 'Franchise Player API is running',
    timestamp: new Date().toISOString()
  });
});

// JSON upload endpoint (requires authentication)
app.post('/upload', authenticateUser, async (req, res) => {
  try {
    const json = req.body;
    const userId = req.user.id;
    
    if (!json) {
      return res.status(400).json({ 
        error: 'No JSON data received',
        message: 'Please provide JSON data in the request body'
      });
    }

    // Validate that it's actually JSON
    if (typeof json !== 'object') {
      return res.status(400).json({ 
        error: 'Invalid JSON format',
        message: 'Request body must be a valid JSON object'
      });
    }

    // Insert into Supabase with user association
    const { data, error } = await supabase
      .from('json_uploads')
      .insert([{ 
        payload: json,
        user_id: userId,
        uploaded_at: new Date().toISOString()
      }])
      .select();

    if (error) {
      console.error('Supabase error:', error);
      return res.status(500).json({ 
        error: error.message || error.details || error.toString() || 'Database error',
        details: error
      });
    }

    res.status(200).json({ 
      message: 'Upload successful',
      id: data[0]?.id,
      uploaded_at: data[0]?.uploaded_at,
      user_id: data[0]?.user_id
    });

  } catch (error) {
    console.error('Server error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Get user's uploads (requires authentication)
app.get('/uploads', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const { data, error } = await supabase
      .from('json_uploads')
      .select('*')
      .eq('user_id', userId)
      .order('uploaded_at', { ascending: false });

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.status(200).json({
      uploads: data,
      count: data.length,
      user_id: userId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get specific upload by ID (requires authentication)
app.get('/uploads/:id', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const uploadId = req.params.id;
    
    const { data, error } = await supabase
      .from('json_uploads')
      .select('*')
      .eq('id', uploadId)
      .eq('user_id', userId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({ error: 'Upload not found' });
      }
      return res.status(500).json({ error: error.message });
    }

    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete upload by ID (requires authentication)
app.delete('/uploads/:id', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const uploadId = req.params.id;
    
    const { error } = await supabase
      .from('json_uploads')
      .delete()
      .eq('id', uploadId)
      .eq('user_id', userId);

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.status(200).json({ 
      message: 'Upload deleted successfully',
      id: uploadId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(`🚀 Franchise Player API server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`📤 Upload endpoint: http://localhost:${PORT}/upload`);
  console.log(`📋 Get uploads: http://localhost:${PORT}/uploads`);
  console.log(`🔐 Authentication required for data endpoints`);
}); 