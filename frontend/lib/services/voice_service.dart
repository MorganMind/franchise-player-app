import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isConnecting = false;
  bool _isAudioEnabled = false;
  bool _isDeafened = false;
  
  // LiveKit configuration - UPDATE THIS WITH YOUR LIVEKIT URL
  static const String _livekitUrl = 'wss://franchiseplayer-2cumzrgv.livekit.cloud';
  
  // Render token service URL
  static const String _tokenServiceUrl = 'https://livekit-edge.onrender.com';
  
  // Getters
  Room? get room => _room;
  bool get isConnected => _room?.connectionState == ConnectionState.connected;
  bool get isConnecting => _isConnecting || _room?.connectionState == ConnectionState.connecting;
  bool get isDisconnected => _room?.connectionState == ConnectionState.disconnected;
  bool get isMuted => !(_room?.localParticipant?.isMicrophoneEnabled() ?? false);
  bool get isDeafened => _isDeafened;
  bool get isAudioEnabled => _isAudioEnabled;
  List<RemoteParticipant> get participants => _room?.participants.values.whereType<RemoteParticipant>().toList() ?? [];
  LocalParticipant? get localParticipant => _room?.localParticipant;

  // Initialize audio system - simplified for this version
  Future<void> initializeAudio() async {
    try {
      // For this version, we'll skip permission requests and just mark as enabled
      // The browser will handle permissions when we try to access the microphone
      developer.log('Audio system initialized (permissions will be requested on join)');
      _isAudioEnabled = true;
      notifyListeners();
    } catch (e) {
      developer.log('Error initializing audio: $e');
      rethrow;
    }
  }

  Future<void> joinChannel(String channelId, String channelName) async {
    if (_isConnecting) return;
    
    try {
      _isConnecting = true;
      notifyListeners();

      // Initialize audio if not already done
      if (!_isAudioEnabled) {
        await initializeAudio();
      }

      // Get LiveKit token from Render service
      final tokenResponse = await _getTokenFromRenderService(channelId);

      final token = tokenResponse['token'];
      if (token == null || token is! String) {
        throw Exception('No token returned from backend');
      }
      final roomId = tokenResponse['roomId'];
      if (roomId == null || roomId is! String) {
        throw Exception('No roomId returned from backend');
      }

      // Connect to LiveKit room using the roomId from the response
      await _connectToRoom(roomId, token, channelName);
      
      // Update voice participant record
      await _updateVoiceParticipant(channelId, false);

    } catch (e) {
      developer.log('Error joining channel: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _getTokenFromRenderService(String channelId) async {
    try {
      // Get the current user's access token
      final session = _supabase.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.post(
        Uri.parse('$_tokenServiceUrl/generate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session!.accessToken}',
        },
        body: jsonEncode({
          'channelId': channelId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Token generation failed: ${response.statusCode} - ${response.body}');
      }

      final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
      if (tokenData['error'] != null) {
        throw Exception(tokenData['error']);
      }

      return tokenData;
    } catch (e) {
      developer.log('Error getting token from Render service: $e');
      rethrow;
    }
  }

  Future<void> _connectToRoom(String roomName, String token, String channelName) async {
    try {
      const connectOptions = ConnectOptions(
        autoSubscribe: true,
      );

      _room = Room();
      
      // Set up room event listeners before connecting
      _setupEventListeners();
      
      await _room!.connect(
        _livekitUrl,
        token,
        connectOptions: connectOptions,
      );

      // Enable microphone by default when joining
      if (_room?.localParticipant != null) {
        await _room!.localParticipant!.setMicrophoneEnabled(true);
      }
      
      developer.log('Connected to voice channel: $channelName');
      notifyListeners();
    } catch (e) {
      developer.log('Error connecting to room: $e');
      rethrow;
    }
  }

  void _setupEventListeners() {
    if (_room == null) return;

    _listener = _room!.createListener();
    
    _listener?.on<ParticipantConnectedEvent>((event) {
      developer.log('Participant connected: ${event.participant.identity}');
      notifyListeners();
    });
    
    _listener?.on<ParticipantDisconnectedEvent>((event) {
      developer.log('Participant disconnected: ${event.participant.identity}');
      notifyListeners();
    });
    
    _listener?.on<RoomDisconnectedEvent>((event) {
      developer.log('Room disconnected: ${event.reason}');
      notifyListeners();
    });
    
    _listener?.on<DataReceivedEvent>((event) {
      developer.log('Data received from ${event.participant?.identity ?? 'unknown'}');
    });
  }

  Future<void> _updateVoiceParticipant(String channelId, bool isMuted) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Upsert voice participant record
      await _supabase.from('voice_participants').upsert({
        'channel_id': channelId,
        'user_id': userId,
        'is_muted': isMuted,
        'is_deafened': false,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('Error updating voice participant: $e');
    }
  }

  Future<void> leaveChannel() async {
    try {
      if (_room != null) {
        await _room!.disconnect();
        _room = null;
      }
      
      if (_listener != null) {
        _listener!.dispose();
        _listener = null;
      }
      
      developer.log('Left voice channel');
      notifyListeners();
    } catch (e) {
      developer.log('Error leaving channel: $e');
    }
  }

  Future<void> toggleMute() async {
    try {
      if (_room?.localParticipant == null) return;
      
      final currentlyEnabled = _room!.localParticipant!.isMicrophoneEnabled();
      await _room!.localParticipant!.setMicrophoneEnabled(!currentlyEnabled);
      
      developer.log('Microphone ${!currentlyEnabled ? 'enabled' : 'disabled'}');
      
      // Update voice participant record
      if (_room?.name != null) {
        final channelId = _room!.name!.replaceFirst('channel_', '');
        await _updateVoiceParticipant(channelId, !currentlyEnabled);
      }
      
      notifyListeners();
    } catch (e) {
      developer.log('Error toggling mute: $e');
    }
  }

  Future<void> toggleDeafen() async {
    try {
      if (_room?.localParticipant == null) return;
      
      _isDeafened = !_isDeafened;
      
      if (_isDeafened) {
        // Mute microphone and disable audio output
        await _room!.localParticipant!.setMicrophoneEnabled(false);
        // Note: LiveKit doesn't have a direct "deafen" method, 
        // so we mute the microphone and could add audio output control
      } else {
        // Re-enable microphone
        await _room!.localParticipant!.setMicrophoneEnabled(true);
      }
      
      developer.log('Deafened ${_isDeafened ? 'enabled' : 'disabled'}');
      notifyListeners();
    } catch (e) {
      developer.log('Error toggling deafen: $e');
    }
  }

  Future<void> startScreenShare() async {
    try {
      if (_room?.localParticipant == null) return;
      
      // Simplified screen sharing for this version
      await _room!.localParticipant!.setScreenShareEnabled(true);
      developer.log('Screen share started');
      notifyListeners();
    } catch (e) {
      developer.log('Error starting screen share: $e');
      rethrow;
    }
  }

  Future<void> stopScreenShare() async {
    try {
      if (_room?.localParticipant == null) return;
      await _room!.localParticipant!.setScreenShareEnabled(false);
      developer.log('Screen share stopped');
      notifyListeners();
    } catch (e) {
      developer.log('Error stopping screen share: $e');
    }
  }

  // Get available audio devices (simplified for this version)
  Future<List<MediaDevice>> getAudioDevices() async {
    try {
      // For this version, we'll return an empty list as enumerateDevices may not be available
      return [];
    } catch (e) {
      developer.log('Error getting audio devices: $e');
      return [];
    }
  }

  // Switch audio device (simplified for this version)
  Future<void> switchAudioDevice(String deviceId) async {
    try {
      // For this version, we'll just log the attempt
      developer.log('Audio device switching not supported in this version');
    } catch (e) {
      developer.log('Error switching audio device: $e');
    }
  }

  // Get speaking participants
  List<Participant> getSpeakingParticipants() {
    if (_room == null) return [];
    
    final allParticipants = <Participant>[];
    if (_room!.localParticipant != null) {
      allParticipants.add(_room!.localParticipant!);
    }
    allParticipants.addAll(_room!.participants.values);
    
    // For this version, we'll use a simplified speaking detection
    return allParticipants.where((p) => p.isSpeaking).toList();
  }

  @override
  void dispose() {
    leaveChannel();
    super.dispose();
  }
} 