import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_init.dart';
import '../models/message.dart';
import 'dart:async';

final channelMessagesProvider = StreamProvider.family<List<Message>, String>((ref, channelId) {
  print('Setting up messages stream for channel: $channelId'); // Debug print
  
  // Create a stream controller to manage the messages
  final controller = StreamController<List<Message>>();
  
  // Initial load
  _loadMessages(channelId).then((messages) {
    controller.add(messages);
  });
  
  // Set up real-time subscription
  final channel = supabase.channel('messages_$channelId');
  
  // Listen for messages in both server channels and franchise channels
  // We'll use two separate subscriptions since PostgresChangeFilter doesn't support OR
  final channelSubscription = supabase.channel('messages_server_$channelId');
  final franchiseSubscription = supabase.channel('messages_franchise_$channelId');
  
  // Subscribe to server channel messages
  channelSubscription
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'channel_id',
        value: channelId,
      ),
      callback: (payload) {
        print('Real-time INSERT detected for server channel: $payload'); // Debug print
        _loadMessages(channelId).then((messages) {
          controller.add(messages);
          print('New messages loaded, should auto-scroll'); // Debug print
        });
      },
    )
    .subscribe();
  
  // Subscribe to franchise channel messages
  franchiseSubscription
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'franchise_channel_id',
        value: channelId,
      ),
      callback: (payload) {
        print('Real-time INSERT detected for franchise channel: $payload'); // Debug print
        _loadMessages(channelId).then((messages) {
          controller.add(messages);
          print('New messages loaded, should auto-scroll'); // Debug print
        });
      },
    )
    .subscribe();
  
  // Clean up subscriptions when provider is disposed
  ref.onDispose(() {
    print('Disposing messages stream for channel: $channelId'); // Debug print
    channelSubscription.unsubscribe();
    franchiseSubscription.unsubscribe();
    controller.close();
  });
  
  return controller.stream;
});

Future<List<Message>> _loadMessages(String channelId) async {
  print('Loading messages for channel: $channelId'); // Debug print
  
  // Load messages from both server channels and franchise channels
  final response = await supabase
      .from('messages')
      .select()
      .or('channel_id.eq.$channelId,franchise_channel_id.eq.$channelId')
      .order('created_at', ascending: true);
  
  print('Loaded ${response.length} messages for channel $channelId'); // Debug print
  return response.map((json) => Message.fromJson(json)).toList();
}

Future<void> sendChannelMessage({
  required String channelId,
  required String content,
}) async {
  print('sendChannelMessage called with channelId: $channelId, content: $content'); // Debug print
  
  try {
    // First, try to determine if this is a server channel or franchise channel
    final channelResponse = await supabase
        .from('channels')
        .select('id')
        .eq('id', channelId)
        .maybeSingle();
    
    if (channelResponse != null) {
      // It's a server channel
      final result = await supabase.rpc('send_message', params: {
        'p_channel_id': channelId,
        'p_content': content,
      });
      print('send_message RPC result: $result'); // Debug print
    } else {
      // It's a franchise channel
      final result = await supabase.rpc('send_franchise_channel_message', params: {
        'p_franchise_channel_id': channelId,
        'p_content': content,
      });
      print('send_franchise_channel_message RPC result: $result'); // Debug print
    }
    
    // Force a manual refresh of messages after sending
    print('Message sent, real-time update should trigger...'); // Debug print
  } catch (e) {
    print('Error in sendChannelMessage: $e'); // Debug print
    rethrow;
  }
} 