import 'package:supabase_flutter/supabase_flutter.dart';

class ServerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch servers that the current user has access to
  Future<List<Map<String, dynamic>>> getServers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('DEBUG: No authenticated user, returning empty server list');
        return [];
      }

      print('DEBUG: Fetching servers for authenticated user: ${user.id}');

      // Get servers the user is a member of
      final response = await _supabase
          .from('server_members')
          .select('''
            server_id,
            servers (
              id,
              name,
              description,
              icon,
              icon_url,
              color,
              owner_id,
              created_at
            )
          ''')
          .eq('user_id', user.id)
          .order('sort_order', ascending: true)
          .order('joined_at', ascending: true);

      print('DEBUG: Supabase response: $response');

      // Extract the server data from the joined response
      final servers = response.map<Map<String, dynamic>>((member) {
        final serverData = member['servers'] as Map<String, dynamic>;
        return {
          'id': serverData['id'],
          'name': serverData['name'],
          'description': serverData['description'],
          'icon': serverData['icon'] ?? '🏠',
          'color': serverData['color'] ?? '#7289DA',
          'icon_url': serverData['icon_url'],
          'owner_id': serverData['owner_id'],
          'created_at': serverData['created_at'],
        };
      }).toList();

      print('DEBUG: Found ${servers.length} servers for user ${user.email}');
      return servers;
    } catch (e) {
      print('Error fetching servers: $e');
      return [];
    }
  }

  /// Fetch a specific server by ID
  Future<Map<String, dynamic>?> getServerById(String serverId) async {
    try {
      final response = await _supabase
          .from('servers')
          .select('*')
          .eq('id', serverId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching server by ID: $e');
      return null;
    }
  }

  /// Fetch servers that the current user is a member of
  Future<List<Map<String, dynamic>>> getUserServers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('server_members')
          .select('''
            server_id,
            servers (
              id,
              name,
              description,
              icon,
              icon_url,
              color,
              owner_id,
              created_at
            )
          ''')
          .eq('user_id', user.id)
          .order('sort_order', ascending: true)
          .order('joined_at', ascending: true);

      // Extract the server data from the joined response
      return response.map<Map<String, dynamic>>((member) {
        final serverData = member['servers'] as Map<String, dynamic>;
        final server = {
          'id': serverData['id'],
          'name': serverData['name'],
          'description': serverData['description'],
          'icon': serverData['icon'] ?? '🏠',
          'color': serverData['color'] ?? '#7289DA',
          'icon_url': serverData['icon_url'],
          'server_type': serverData['server_type'],
          'visibility': serverData['visibility'],
          'sort_order': serverData['sort_order'] ?? 0,
          'owner_id': serverData['owner_id'],
          'created_at': serverData['created_at'],
        };
        print('Fetched server: ${server['name']} with icon_url: ${server['icon_url']}');
        return server;
      }).toList();
    } catch (e) {
      print('Error fetching user servers: $e');
      return [];
    }
  }

  /// Create a new server
  Future<Map<String, dynamic>?> createServer({
    required String name,
    String? description,
    String? icon,
    String? color,
    String? serverType,
    String? visibility,
    String? iconUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('Creating server in database with data:');
      print('Name: $name');
      print('Description: $description');
      print('Server Type: $serverType');
      print('Visibility: $visibility');
      print('Icon URL: $iconUrl');
      print('User ID: ${user.id}');

      final serverData = {
        'name': name,
        'description': description,
        'icon': icon ?? '🏠',
        'color': color ?? '#7289DA',
        'server_type': serverType ?? 'Madden',
        'visibility': visibility ?? 'Public',
        'icon_url': iconUrl,
        'sort_order': 0, // Will be updated to max + 1
        'owner_id': user.id,
      };

      print('Server data to insert: $serverData');

      final response = await _supabase
          .from('servers')
          .insert(serverData)
          .select()
          .single();

      print('Server created successfully: ${response['id']}');

      // Add the creator as a member
      await _supabase
          .from('server_members')
          .insert({
            'server_id': response['id'],
            'user_id': user.id,
            'nickname': null,
          });

      print('User added as member to server');

      return response;
    } catch (e) {
      print('Error creating server: $e');
      return null;
    }
  }

  /// Join a server
  Future<bool> joinServer(String serverId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('server_members')
          .insert({
            'server_id': serverId,
            'user_id': user.id,
            'nickname': null,
          });

      return true;
    } catch (e) {
      print('Error joining server: $e');
      return false;
    }
  }

  /// Leave a server
  Future<bool> leaveServer(String serverId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('server_members')
          .delete()
          .eq('server_id', serverId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error leaving server: $e');
      return false;
    }
  }



  /// Track server access (update last_accessed_at)
  Future<bool> trackServerAccess(String serverId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('server_members')
          .update({'last_accessed_at': DateTime.now().toIso8601String()})
          .eq('server_id', serverId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error tracking server access: $e');
      return false;
    }
  }



  /// Get recent servers (last accessed)
  Future<List<Map<String, dynamic>>> getRecentServers({int limit = 3}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('server_members')
          .select('''
            server_id,
            last_accessed_at,
            servers (
              id,
              name,
              description,
              icon,
              icon_url,
              color,
              owner_id,
              created_at
            )
          ''')
          .eq('user_id', user.id)
          .not('last_accessed_at', 'is', null)
          .order('last_accessed_at', ascending: false)
          .limit(limit);

      // Extract the server data from the joined response
      final servers = response.map<Map<String, dynamic>>((member) {
        final serverData = member['servers'] as Map<String, dynamic>;
        return {
          'id': serverData['id'],
          'name': serverData['name'],
          'description': serverData['description'],
          'icon': serverData['icon'] ?? '🏠',
          'color': serverData['color'] ?? '#7289DA',
          'icon_url': serverData['icon_url'],
          'server_type': serverData['server_type'],
          'visibility': serverData['visibility'],
          'owner_id': serverData['owner_id'],
          'created_at': serverData['created_at'],
          'last_accessed_at': member['last_accessed_at'],
        };
      }).toList();

      return servers;
    } catch (e) {
      print('Error fetching recent servers: $e');
      return [];
    }
  }

  /// Update server sort order
  Future<bool> updateServerSortOrder(String serverId, int newSortOrder) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('servers')
          .update({'sort_order': newSortOrder})
          .eq('id', serverId)
          .eq('owner_id', user.id);

      return true;
    } catch (e) {
      print('Error updating server sort order: $e');
      return false;
    }
  }

  /// Update server information
  Future<bool> updateServer(String serverId, {
    String? name,
    String? description,
    String? iconUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (iconUrl != null) updateData['icon_url'] = iconUrl;

      if (updateData.isEmpty) {
        return true; // Nothing to update
      }

      await _supabase
          .from('servers')
          .update(updateData)
          .eq('id', serverId)
          .eq('owner_id', user.id);

      return true;
    } catch (e) {
      print('Error updating server: $e');
      return false;
    }
  }

  /// Reorder servers by updating their sort_order values
  Future<bool> reorderServers(List<String> serverIds) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Update sort_order for each server based on the new order
      for (int i = 0; i < serverIds.length; i++) {
        await _supabase
            .from('server_members')
            .update({'sort_order': i})
            .eq('server_id', serverIds[i])
            .eq('user_id', user.id);
      }

      return true;
    } catch (e) {
      print('Error reordering servers: $e');
      return false;
    }
  }

  /// Delete a server and all its data
  Future<bool> deleteServer(String serverId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('DEBUG: No authenticated user for server deletion');
        return false;
      }

      print('DEBUG: Attempting to delete server: $serverId');

      // First, check if user is the owner of the server
      final server = await getServerById(serverId);
      if (server == null) {
        print('DEBUG: Server not found: $serverId');
        return false;
      }

      if (server['owner_id'] != user.id) {
        print('DEBUG: User is not the owner of server: $serverId');
        return false;
      }

      // Delete all related data in the correct order (respecting foreign key constraints)
      // Only delete from tables that actually exist
      
      try {
        // 1. Delete franchise channels (depends on franchises)
        await _supabase
            .from('franchise_channels')
            .delete()
            .eq('franchise_id', serverId);
        print('DEBUG: Deleted franchise channels for server: $serverId');
      } catch (e) {
        print('DEBUG: No franchise_channels table or no data to delete: $e');
      }

      try {
        // 2. Delete franchises
        await _supabase
            .from('franchises')
            .delete()
            .eq('server_id', serverId);
        print('DEBUG: Deleted franchises for server: $serverId');
      } catch (e) {
        print('DEBUG: No franchises table or no data to delete: $e');
      }

      // 3. Delete server members
      try {
        await _supabase
            .from('server_members')
            .delete()
            .eq('server_id', serverId);
        print('DEBUG: Deleted server members for server: $serverId');
      } catch (e) {
        print('DEBUG: Error deleting server members: $e');
        throw e; // This is critical, so re-throw
      }

      // 4. Finally, delete the server itself
      try {
        await _supabase
            .from('servers')
            .delete()
            .eq('id', serverId);
        print('DEBUG: Deleted server: $serverId');
      } catch (e) {
        print('DEBUG: Error deleting server: $e');
        throw e; // This is critical, so re-throw
      }

      print('DEBUG: Successfully deleted server: $serverId');
      return true;
    } catch (e) {
      print('Error deleting server: $e');
      return false;
    }
  } 
}