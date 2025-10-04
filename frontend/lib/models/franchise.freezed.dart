// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'franchise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Franchise _$FranchiseFromJson(Map<String, dynamic> json) {
  return _Franchise.fromJson(json);
}

/// @nodoc
mixin _$Franchise {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'server_id')
  String get serverId => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'external_id')
  String? get externalId => throw _privateConstructorUsedError;
  @JsonKey(name: 'metadata')
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Franchise to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Franchise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FranchiseCopyWith<Franchise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FranchiseCopyWith<$Res> {
  factory $FranchiseCopyWith(Franchise value, $Res Function(Franchise) then) =
      _$FranchiseCopyWithImpl<$Res, Franchise>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'server_id') String serverId,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'external_id') String? externalId,
      @JsonKey(name: 'metadata') Map<String, dynamic> metadata,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$FranchiseCopyWithImpl<$Res, $Val extends Franchise>
    implements $FranchiseCopyWith<$Res> {
  _$FranchiseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Franchise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serverId = null,
    Object? name = null,
    Object? externalId = freezed,
    Object? metadata = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      serverId: null == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FranchiseImplCopyWith<$Res>
    implements $FranchiseCopyWith<$Res> {
  factory _$$FranchiseImplCopyWith(
          _$FranchiseImpl value, $Res Function(_$FranchiseImpl) then) =
      __$$FranchiseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'server_id') String serverId,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'external_id') String? externalId,
      @JsonKey(name: 'metadata') Map<String, dynamic> metadata,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$FranchiseImplCopyWithImpl<$Res>
    extends _$FranchiseCopyWithImpl<$Res, _$FranchiseImpl>
    implements _$$FranchiseImplCopyWith<$Res> {
  __$$FranchiseImplCopyWithImpl(
      _$FranchiseImpl _value, $Res Function(_$FranchiseImpl) _then)
      : super(_value, _then);

  /// Create a copy of Franchise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? serverId = null,
    Object? name = null,
    Object? externalId = freezed,
    Object? metadata = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$FranchiseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      serverId: null == serverId
          ? _value.serverId
          : serverId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FranchiseImpl implements _Franchise {
  const _$FranchiseImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'server_id') required this.serverId,
      @JsonKey(name: 'name') required this.name,
      @JsonKey(name: 'external_id') this.externalId,
      @JsonKey(name: 'metadata') final Map<String, dynamic> metadata = const {},
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt})
      : _metadata = metadata;

  factory _$FranchiseImpl.fromJson(Map<String, dynamic> json) =>
      _$$FranchiseImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'server_id')
  final String serverId;
  @override
  @JsonKey(name: 'name')
  final String name;
  @override
  @JsonKey(name: 'external_id')
  final String? externalId;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey(name: 'metadata')
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Franchise(id: $id, serverId: $serverId, name: $name, externalId: $externalId, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FranchiseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.serverId, serverId) ||
                other.serverId == serverId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, serverId, name, externalId,
      const DeepCollectionEquality().hash(_metadata), createdAt, updatedAt);

  /// Create a copy of Franchise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FranchiseImplCopyWith<_$FranchiseImpl> get copyWith =>
      __$$FranchiseImplCopyWithImpl<_$FranchiseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FranchiseImplToJson(
      this,
    );
  }
}

abstract class _Franchise implements Franchise {
  const factory _Franchise(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'server_id') required final String serverId,
          @JsonKey(name: 'name') required final String name,
          @JsonKey(name: 'external_id') final String? externalId,
          @JsonKey(name: 'metadata') final Map<String, dynamic> metadata,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$FranchiseImpl;

  factory _Franchise.fromJson(Map<String, dynamic> json) =
      _$FranchiseImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'server_id')
  String get serverId;
  @override
  @JsonKey(name: 'name')
  String get name;
  @override
  @JsonKey(name: 'external_id')
  String? get externalId;
  @override
  @JsonKey(name: 'metadata')
  Map<String, dynamic> get metadata;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of Franchise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FranchiseImplCopyWith<_$FranchiseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FranchiseChannel _$FranchiseChannelFromJson(Map<String, dynamic> json) {
  return _FranchiseChannel.fromJson(json);
}

/// @nodoc
mixin _$FranchiseChannel {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'franchise_id')
  String get franchiseId => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'type')
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'position')
  int get position => throw _privateConstructorUsedError;
  @JsonKey(name: 'livekit_room_id')
  String? get livekitRoomId => throw _privateConstructorUsedError;
  @JsonKey(name: 'voice_enabled')
  bool get voiceEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'video_enabled')
  bool get videoEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_private')
  bool get isPrivate => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_participants')
  int get maxParticipants => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FranchiseChannel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FranchiseChannel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FranchiseChannelCopyWith<FranchiseChannel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FranchiseChannelCopyWith<$Res> {
  factory $FranchiseChannelCopyWith(
          FranchiseChannel value, $Res Function(FranchiseChannel) then) =
      _$FranchiseChannelCopyWithImpl<$Res, FranchiseChannel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'franchise_id') String franchiseId,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'type') String type,
      @JsonKey(name: 'position') int position,
      @JsonKey(name: 'livekit_room_id') String? livekitRoomId,
      @JsonKey(name: 'voice_enabled') bool voiceEnabled,
      @JsonKey(name: 'video_enabled') bool videoEnabled,
      @JsonKey(name: 'is_private') bool isPrivate,
      @JsonKey(name: 'max_participants') int maxParticipants,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$FranchiseChannelCopyWithImpl<$Res, $Val extends FranchiseChannel>
    implements $FranchiseChannelCopyWith<$Res> {
  _$FranchiseChannelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FranchiseChannel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? franchiseId = null,
    Object? name = null,
    Object? type = null,
    Object? position = null,
    Object? livekitRoomId = freezed,
    Object? voiceEnabled = null,
    Object? videoEnabled = null,
    Object? isPrivate = null,
    Object? maxParticipants = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      franchiseId: null == franchiseId
          ? _value.franchiseId
          : franchiseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      livekitRoomId: freezed == livekitRoomId
          ? _value.livekitRoomId
          : livekitRoomId // ignore: cast_nullable_to_non_nullable
              as String?,
      voiceEnabled: null == voiceEnabled
          ? _value.voiceEnabled
          : voiceEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      videoEnabled: null == videoEnabled
          ? _value.videoEnabled
          : videoEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FranchiseChannelImplCopyWith<$Res>
    implements $FranchiseChannelCopyWith<$Res> {
  factory _$$FranchiseChannelImplCopyWith(_$FranchiseChannelImpl value,
          $Res Function(_$FranchiseChannelImpl) then) =
      __$$FranchiseChannelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'franchise_id') String franchiseId,
      @JsonKey(name: 'name') String name,
      @JsonKey(name: 'type') String type,
      @JsonKey(name: 'position') int position,
      @JsonKey(name: 'livekit_room_id') String? livekitRoomId,
      @JsonKey(name: 'voice_enabled') bool voiceEnabled,
      @JsonKey(name: 'video_enabled') bool videoEnabled,
      @JsonKey(name: 'is_private') bool isPrivate,
      @JsonKey(name: 'max_participants') int maxParticipants,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$FranchiseChannelImplCopyWithImpl<$Res>
    extends _$FranchiseChannelCopyWithImpl<$Res, _$FranchiseChannelImpl>
    implements _$$FranchiseChannelImplCopyWith<$Res> {
  __$$FranchiseChannelImplCopyWithImpl(_$FranchiseChannelImpl _value,
      $Res Function(_$FranchiseChannelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FranchiseChannel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? franchiseId = null,
    Object? name = null,
    Object? type = null,
    Object? position = null,
    Object? livekitRoomId = freezed,
    Object? voiceEnabled = null,
    Object? videoEnabled = null,
    Object? isPrivate = null,
    Object? maxParticipants = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$FranchiseChannelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      franchiseId: null == franchiseId
          ? _value.franchiseId
          : franchiseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as int,
      livekitRoomId: freezed == livekitRoomId
          ? _value.livekitRoomId
          : livekitRoomId // ignore: cast_nullable_to_non_nullable
              as String?,
      voiceEnabled: null == voiceEnabled
          ? _value.voiceEnabled
          : voiceEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      videoEnabled: null == videoEnabled
          ? _value.videoEnabled
          : videoEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: null == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FranchiseChannelImpl implements _FranchiseChannel {
  const _$FranchiseChannelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'franchise_id') required this.franchiseId,
      @JsonKey(name: 'name') required this.name,
      @JsonKey(name: 'type') required this.type,
      @JsonKey(name: 'position') this.position = 0,
      @JsonKey(name: 'livekit_room_id') this.livekitRoomId,
      @JsonKey(name: 'voice_enabled') this.voiceEnabled = false,
      @JsonKey(name: 'video_enabled') this.videoEnabled = false,
      @JsonKey(name: 'is_private') this.isPrivate = false,
      @JsonKey(name: 'max_participants') this.maxParticipants = 0,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$FranchiseChannelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FranchiseChannelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'franchise_id')
  final String franchiseId;
  @override
  @JsonKey(name: 'name')
  final String name;
  @override
  @JsonKey(name: 'type')
  final String type;
  @override
  @JsonKey(name: 'position')
  final int position;
  @override
  @JsonKey(name: 'livekit_room_id')
  final String? livekitRoomId;
  @override
  @JsonKey(name: 'voice_enabled')
  final bool voiceEnabled;
  @override
  @JsonKey(name: 'video_enabled')
  final bool videoEnabled;
  @override
  @JsonKey(name: 'is_private')
  final bool isPrivate;
  @override
  @JsonKey(name: 'max_participants')
  final int maxParticipants;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'FranchiseChannel(id: $id, franchiseId: $franchiseId, name: $name, type: $type, position: $position, livekitRoomId: $livekitRoomId, voiceEnabled: $voiceEnabled, videoEnabled: $videoEnabled, isPrivate: $isPrivate, maxParticipants: $maxParticipants, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FranchiseChannelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.franchiseId, franchiseId) ||
                other.franchiseId == franchiseId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.livekitRoomId, livekitRoomId) ||
                other.livekitRoomId == livekitRoomId) &&
            (identical(other.voiceEnabled, voiceEnabled) ||
                other.voiceEnabled == voiceEnabled) &&
            (identical(other.videoEnabled, videoEnabled) ||
                other.videoEnabled == videoEnabled) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      franchiseId,
      name,
      type,
      position,
      livekitRoomId,
      voiceEnabled,
      videoEnabled,
      isPrivate,
      maxParticipants,
      createdAt,
      updatedAt);

  /// Create a copy of FranchiseChannel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FranchiseChannelImplCopyWith<_$FranchiseChannelImpl> get copyWith =>
      __$$FranchiseChannelImplCopyWithImpl<_$FranchiseChannelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FranchiseChannelImplToJson(
      this,
    );
  }
}

abstract class _FranchiseChannel implements FranchiseChannel {
  const factory _FranchiseChannel(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'franchise_id') required final String franchiseId,
          @JsonKey(name: 'name') required final String name,
          @JsonKey(name: 'type') required final String type,
          @JsonKey(name: 'position') final int position,
          @JsonKey(name: 'livekit_room_id') final String? livekitRoomId,
          @JsonKey(name: 'voice_enabled') final bool voiceEnabled,
          @JsonKey(name: 'video_enabled') final bool videoEnabled,
          @JsonKey(name: 'is_private') final bool isPrivate,
          @JsonKey(name: 'max_participants') final int maxParticipants,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$FranchiseChannelImpl;

  factory _FranchiseChannel.fromJson(Map<String, dynamic> json) =
      _$FranchiseChannelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'franchise_id')
  String get franchiseId;
  @override
  @JsonKey(name: 'name')
  String get name;
  @override
  @JsonKey(name: 'type')
  String get type;
  @override
  @JsonKey(name: 'position')
  int get position;
  @override
  @JsonKey(name: 'livekit_room_id')
  String? get livekitRoomId;
  @override
  @JsonKey(name: 'voice_enabled')
  bool get voiceEnabled;
  @override
  @JsonKey(name: 'video_enabled')
  bool get videoEnabled;
  @override
  @JsonKey(name: 'is_private')
  bool get isPrivate;
  @override
  @JsonKey(name: 'max_participants')
  int get maxParticipants;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of FranchiseChannel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FranchiseChannelImplCopyWith<_$FranchiseChannelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
