import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/franchise.dart';
import '../supabase_client.dart';

// Provider for the franchise repository
final franchiseRepositoryProvider = Provider<FranchiseRepository>((ref) {
  return FranchiseRepository();
});

// Provider for all franchises in a server
final franchisesProvider = StreamProvider.family<List<Franchise>, String>((ref, serverId) {
  print('FranchisesProvider: Loading franchises for serverId: $serverId');
  return supabase
      .from('franchises')
      .stream(primaryKey: ['id'])
      .eq('server_id', serverId)
      .order('name')
      .map((event) {
        print('FranchisesProvider: Received event: $event');
        try {
          if (event.isEmpty) {
            print('FranchisesProvider: No franchises found for serverId: $serverId');
            return <Franchise>[];
          }
          
          return event.map((json) {
            print('FranchisesProvider: Processing franchise JSON: $json');
            try {
              final franchise = Franchise.fromJson(json);
              print('FranchisesProvider: Successfully created franchise: ${franchise.name}');
              return franchise;
            } catch (parseError) {
              print('FranchisesProvider: Error parsing franchise: $parseError');
              print('FranchisesProvider: Failed JSON: $json');
              rethrow;
            }
          }).toList();
        } catch (e) {
          print('Error parsing franchises: $e');
          print('Raw data: $event');
          rethrow;
        }
      });
});

// Provider for a specific franchise
final franchiseProvider = StreamProvider.family<Franchise?, String>((ref, franchiseId) {
  return supabase
      .from('franchises')
      .stream(primaryKey: ['id'])
      .eq('id', franchiseId)
      .limit(1)
      .map((event) {
        if (event.isEmpty) return null;
        return Franchise.fromJson(event.first);
      });
});

// Provider for all franchise channels in a franchise
final franchiseChannelsProvider = StreamProvider.family<List<FranchiseChannel>, String>((ref, franchiseId) {
  return supabase
      .from('franchise_channels')
      .stream(primaryKey: ['id'])
      .eq('franchise_id', franchiseId)
      .order('name')
      .map((event) {
        try {
          return event.map((json) {
            return FranchiseChannel.fromJson(json);
          }).toList();
        } catch (e) {
          print('Error parsing franchise channels: $e');
          print('Raw data: $event');
          rethrow;
        }
      });
});

// Provider for a specific franchise channel
final franchiseChannelProvider = StreamProvider.family<FranchiseChannel?, String>((ref, channelId) {
  return supabase
      .from('franchise_channels')
      .stream(primaryKey: ['id'])
      .eq('id', channelId)
      .limit(1)
      .map((event) {
        if (event.isEmpty) return null;
        return FranchiseChannel.fromJson(event.first);
      });
});

// Provider for franchise channels by type (using FutureProvider for filtering)
final franchiseChannelsByTypeProvider = FutureProvider.family<List<FranchiseChannel>, Map<String, String>>((ref, params) async {
  final franchiseId = params['franchiseId']!;
  final channelType = params['channelType']!;
  
  final response = await supabase
      .from('franchise_channels')
      .select()
      .eq('franchise_id', franchiseId)
      .eq('type', channelType)
      .order('name');
  
  return response.map((json) => FranchiseChannel.fromJson(json)).toList();
});

// Provider for all franchises across all servers
final allFranchisesProvider = StreamProvider<List<Franchise>>((ref) {
  return supabase
      .from('franchises')
      .stream(primaryKey: ['id'])
      .order('name')
      .map((event) => event.map((json) => Franchise.fromJson(json)).toList());
});

// Fallback provider that returns empty list on error
final safeFranchisesProvider = StreamProvider.family<List<Franchise>, String>((ref, serverId) {
  return ref.watch(franchisesProvider(serverId)).when(
    data: (franchises) => Stream.value(franchises),
    loading: () => Stream.value(<Franchise>[]),
    error: (error, stack) {
      print('SafeFranchisesProvider: Error loading franchises: $error');
      return Stream.value(<Franchise>[]);
    },
  );
});

// Provider to find franchise by name across all servers
final franchiseByNameProvider = FutureProvider.family<Franchise?, String>((ref, franchiseName) async {
  try {
    // Search for franchise by name across all servers
    final response = await supabase
        .from('franchises')
        .select()
        .ilike('name', franchiseName)
        .limit(1);
    
    if (response.isNotEmpty) {
      return Franchise.fromJson(response.first);
    }
    
    // If not found by exact name, try with spaces replaced by dashes
    final dashedName = franchiseName.replaceAll(' ', '-');
    final response2 = await supabase
        .from('franchises')
        .select()
        .ilike('name', dashedName)
        .limit(1);
    
    if (response2.isNotEmpty) {
      return Franchise.fromJson(response2.first);
    }
    
    return null;
  } catch (e) {
    print('Error finding franchise by name: $e');
    return null;
  }
});

// Provider for all franchise channels across all franchises
final allFranchiseChannelsProvider = StreamProvider<List<FranchiseChannel>>((ref) {
  return supabase
      .from('franchise_channels')
      .stream(primaryKey: ['id'])
      .order('name')
      .map((event) => event.map((json) => FranchiseChannel.fromJson(json)).toList());
});

// Functions for franchise management
class FranchiseRepository {
  // Create a new franchise with default channels
  static Future<String> createFranchise({
    required String serverId,
    required String name,
    String? externalId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await supabase.rpc('create_franchise_with_default_channels', params: {
      'p_server_id': serverId,
      'p_name': name,
      'p_external_id': externalId,
      'p_metadata': metadata ?? {},
    });
    
    if (response == null) {
      throw Exception('Failed to create franchise');
    }
    
    return response as String;
  }

  // Create a custom franchise without default channels
  static Future<Franchise> createCustomFranchise({
    required String serverId,
    required String name,
    String? externalId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await supabase
        .from('franchises')
        .insert({
          'server_id': serverId,
          'name': name,
          'external_id': externalId,
          'metadata': metadata ?? {},
        })
        .select()
        .single();
    
    return Franchise.fromJson(response);
  }

  // Update a franchise
  static Future<void> updateFranchise({
    required String franchiseId,
    String? name,
    String? externalId,
    Map<String, dynamic>? metadata,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (externalId != null) updates['external_id'] = externalId;
    if (metadata != null) updates['metadata'] = metadata;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await supabase
        .from('franchises')
        .update(updates)
        .eq('id', franchiseId);
  }

  // Delete a franchise (this will cascade delete all channels)
  static Future<void> deleteFranchise(String franchiseId) async {
    await supabase
        .from('franchises')
        .delete()
        .eq('id', franchiseId);
  }

  // Create a franchise channel
  static Future<FranchiseChannel> createFranchiseChannel({
    required String franchiseId,
    required String name,
    required String type,
    int position = 0,
    String? livekitRoomId,
    bool voiceEnabled = false,
    bool videoEnabled = false,
    bool isPrivate = false,
    int maxParticipants = 0,
  }) async {
    final response = await supabase
        .from('franchise_channels')
        .insert({
          'franchise_id': franchiseId,
          'name': name,
          'type': type,
          'position': position,
          'livekit_room_id': livekitRoomId,
          'voice_enabled': voiceEnabled,
          'video_enabled': videoEnabled,
          'is_private': isPrivate,
          'max_participants': maxParticipants,
        })
        .select()
        .single();
    
    return FranchiseChannel.fromJson(response);
  }

  // Update a franchise channel
  static Future<void> updateFranchiseChannel({
    required String channelId,
    String? name,
    String? type,
    int? position,
    String? livekitRoomId,
    bool? voiceEnabled,
    bool? videoEnabled,
    bool? isPrivate,
    int? maxParticipants,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (position != null) updates['position'] = position;
    if (livekitRoomId != null) updates['livekit_room_id'] = livekitRoomId;
    if (voiceEnabled != null) updates['voice_enabled'] = voiceEnabled;
    if (videoEnabled != null) updates['video_enabled'] = videoEnabled;
    if (isPrivate != null) updates['is_private'] = isPrivate;
    if (maxParticipants != null) updates['max_participants'] = maxParticipants;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await supabase
        .from('franchise_channels')
        .update(updates)
        .eq('id', channelId);
  }

  // Delete a franchise channel
  static Future<void> deleteFranchiseChannel(String channelId) async {
    await supabase
        .from('franchise_channels')
        .delete()
        .eq('id', channelId);
  }

  // Reorder franchise channels
  static Future<void> reorderFranchiseChannels({
    required String franchiseId,
    required List<String> channelIds,
  }) async {
    for (int i = 0; i < channelIds.length; i++) {
      await supabase
          .from('franchise_channels')
          .update({'position': i})
          .eq('id', channelIds[i])
          .eq('franchise_id', franchiseId);
    }
  }
} 