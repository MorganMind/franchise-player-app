import 'package:freezed_annotation/freezed_annotation.dart';

part 'franchise.freezed.dart';
part 'franchise.g.dart';

@freezed
class Franchise with _$Franchise {
  const factory Franchise({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'server_id') required String serverId,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'external_id') String? externalId,
    @JsonKey(name: 'metadata') @Default({}) Map<String, dynamic> metadata,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Franchise;

  factory Franchise.fromJson(Map<String, dynamic> json) => _$FranchiseFromJson(json);
}

@freezed
class FranchiseChannel with _$FranchiseChannel {
  const factory FranchiseChannel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'franchise_id') required String franchiseId,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'type') required String type,
    @JsonKey(name: 'position') @Default(0) int position,
    @JsonKey(name: 'livekit_room_id') String? livekitRoomId,
    @JsonKey(name: 'voice_enabled') @Default(false) bool voiceEnabled,
    @JsonKey(name: 'video_enabled') @Default(false) bool videoEnabled,
    @JsonKey(name: 'is_private') @Default(false) bool isPrivate,
    @JsonKey(name: 'max_participants') @Default(0) int maxParticipants,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _FranchiseChannel;

  factory FranchiseChannel.fromJson(Map<String, dynamic> json) => _$FranchiseChannelFromJson(json);
} 