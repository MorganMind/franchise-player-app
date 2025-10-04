import 'dart:convert';
import 'package:http/http.dart' as http;

class ValuationService {
  final String baseUrl;
  final String? franchiseId;

  ValuationService({
    required this.baseUrl,
    this.franchiseId,
  });

  /// Get current valuation settings
  Future<Map<String, dynamic>> getSettings() async {
    final uri = Uri.parse('$baseUrl/settings').replace(
      queryParameters: {
        if (franchiseId != null) 'franchise_id': franchiseId!,
      },
    );

    final response = await http.get(uri);
    
    if (response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ok'] != true) {
      throw Exception(json['error'] ?? 'Failed to load settings');
    }

    return Map<String, dynamic>.from(json['settings'] as Map);
  }

  /// Update valuation settings
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final uri = Uri.parse('$baseUrl/settings');
    
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (franchiseId != null) 'franchise_id': franchiseId,
        'settings': settings,
      }),
    );

    if (response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ok'] != true) {
      throw Exception(json['error'] ?? 'Failed to save settings');
    }

    return Map<String, dynamic>.from(json['settings'] as Map);
  }

  /// Compute player value
  Future<ValuationResult> computeValue({
    required int ovr,
    required int age,
    required String position,
    required String devTrait,
  }) async {
    final uri = Uri.parse('$baseUrl/compute');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ovr': ovr,
        'age': age,
        'pos': position,
        'dev': devTrait,
        if (franchiseId != null) 'franchise_id': franchiseId,
      }),
    );

    if (response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ok'] != true) {
      throw Exception(json['error'] ?? 'Failed to compute value');
    }

    return ValuationResult.fromJson(json);
  }
}

class ValuationResult {
  final double value;
  final int nearestPick;
  final int round;
  final int pickInRound;
  final double nearestPoints;
  final ValuationDetails details;

  ValuationResult({
    required this.value,
    required this.nearestPick,
    required this.round,
    required this.pickInRound,
    required this.nearestPoints,
    required this.details,
  });

  factory ValuationResult.fromJson(Map<String, dynamic> json) {
    return ValuationResult(
      value: (json['value'] as num).toDouble(),
      nearestPick: json['nearest_pick'] as int,
      round: json['round'] as int,
      pickInRound: json['pick_in_round'] as int,
      nearestPoints: (json['nearest_points'] as num).toDouble(),
      details: ValuationDetails.fromJson(json['details'] as Map<String, dynamic>),
    );
  }
}

class ValuationDetails {
  final double qbBaseValue;
  final double baseAfterDividingQbMult;
  final ValuationMultipliers multipliers;

  ValuationDetails({
    required this.qbBaseValue,
    required this.baseAfterDividingQbMult,
    required this.multipliers,
  });

  factory ValuationDetails.fromJson(Map<String, dynamic> json) {
    return ValuationDetails(
      qbBaseValue: (json['qb_base_value'] as num).toDouble(),
      baseAfterDividingQbMult: (json['base_after_dividing_qb_mult'] as num).toDouble(),
      multipliers: ValuationMultipliers.fromJson(json['multipliers'] as Map<String, dynamic>),
    );
  }
}

class ValuationMultipliers {
  final double pos;
  final double age;
  final double youth;
  final double dev;

  ValuationMultipliers({
    required this.pos,
    required this.age,
    required this.youth,
    required this.dev,
  });

  factory ValuationMultipliers.fromJson(Map<String, dynamic> json) {
    return ValuationMultipliers(
      pos: (json['pos'] as num).toDouble(),
      age: (json['age'] as num).toDouble(),
      youth: (json['youth'] as num).toDouble(),
      dev: (json['dev'] as num).toDouble(),
    );
  }
}
