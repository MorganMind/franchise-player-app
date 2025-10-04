import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required String id,
    required String firstName,
    required String lastName,
    required int age,
    required int playerBestOvr,
    required int playerSchemeOvr,
    required int speedRating,
    required String position,
    required String? team,
    required bool isFreeAgent,
    required int? teamId,
    required String franchiseId,
    int? jerseyNum,
    int? height,
    int? weight,
    String? college,
    int? draftRound,
    int? draftPick,
    int? strengthRating,
    int? agilityRating,
    int? awareRating,
    int? catchRating,
    int? tackleRating,
    int? throwPowerRating,
    int? staminaRating,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}

extension PlayerExtension on Player {
  String get fullName => '$firstName $lastName';
  int get overall => playerBestOvr > 0 ? playerBestOvr : playerSchemeOvr;
} 