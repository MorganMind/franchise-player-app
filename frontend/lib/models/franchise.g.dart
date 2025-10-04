// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'franchise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FranchiseImpl _$$FranchiseImplFromJson(Map<String, dynamic> json) =>
    _$FranchiseImpl(
      id: json['id'] as String,
      serverId: json['server_id'] as String,
      name: json['name'] as String,
      externalId: json['external_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$FranchiseImplToJson(_$FranchiseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'server_id': instance.serverId,
      'name': instance.name,
      'external_id': instance.externalId,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

_$FranchiseChannelImpl _$$FranchiseChannelImplFromJson(
        Map<String, dynamic> json) =>
    _$FranchiseChannelImpl(
      id: json['id'] as String,
      franchiseId: json['franchise_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      livekitRoomId: json['livekit_room_id'] as String?,
      voiceEnabled: json['voice_enabled'] as bool? ?? false,
      videoEnabled: json['video_enabled'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$FranchiseChannelImplToJson(
        _$FranchiseChannelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'franchise_id': instance.franchiseId,
      'name': instance.name,
      'type': instance.type,
      'position': instance.position,
      'livekit_room_id': instance.livekitRoomId,
      'voice_enabled': instance.voiceEnabled,
      'video_enabled': instance.videoEnabled,
      'is_private': instance.isPrivate,
      'max_participants': instance.maxParticipants,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
