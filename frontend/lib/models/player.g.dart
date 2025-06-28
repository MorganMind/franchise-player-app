// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      age: (json['age'] as num).toInt(),
      playerBestOvr: (json['playerBestOvr'] as num).toInt(),
      playerSchemeOvr: (json['playerSchemeOvr'] as num).toInt(),
      speedRating: (json['speedRating'] as num).toInt(),
      position: json['position'] as String,
      team: json['team'] as String?,
      isFreeAgent: json['isFreeAgent'] as bool,
      teamId: (json['teamId'] as num?)?.toInt(),
      jerseyNum: (json['jerseyNum'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toInt(),
      college: json['college'] as String?,
      draftRound: (json['draftRound'] as num?)?.toInt(),
      draftPick: (json['draftPick'] as num?)?.toInt(),
      strengthRating: (json['strengthRating'] as num?)?.toInt(),
      agilityRating: (json['agilityRating'] as num?)?.toInt(),
      awareRating: (json['awareRating'] as num?)?.toInt(),
      catchRating: (json['catchRating'] as num?)?.toInt(),
      tackleRating: (json['tackleRating'] as num?)?.toInt(),
      throwPowerRating: (json['throwPowerRating'] as num?)?.toInt(),
      staminaRating: (json['staminaRating'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'age': instance.age,
      'playerBestOvr': instance.playerBestOvr,
      'playerSchemeOvr': instance.playerSchemeOvr,
      'speedRating': instance.speedRating,
      'position': instance.position,
      'team': instance.team,
      'isFreeAgent': instance.isFreeAgent,
      'teamId': instance.teamId,
      'jerseyNum': instance.jerseyNum,
      'height': instance.height,
      'weight': instance.weight,
      'college': instance.college,
      'draftRound': instance.draftRound,
      'draftPick': instance.draftPick,
      'strengthRating': instance.strengthRating,
      'agilityRating': instance.agilityRating,
      'awareRating': instance.awareRating,
      'catchRating': instance.catchRating,
      'tackleRating': instance.tackleRating,
      'throwPowerRating': instance.throwPowerRating,
      'staminaRating': instance.staminaRating,
    };
