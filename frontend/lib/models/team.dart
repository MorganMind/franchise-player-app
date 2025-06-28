import 'package:freezed_annotation/freezed_annotation.dart';
import 'player.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
class Team with _$Team {
  const factory Team({
    required int teamId,
    required String name,
    required List<Player> players,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
} 