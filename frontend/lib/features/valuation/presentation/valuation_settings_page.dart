import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Valuation Settings UI
/// - Loads current settings from Supabase Edge Function `/valuation/settings`
/// - Lets you tune sliders for Age, Cliffs, Youth Positional Buffer, Dev Trait, and OVR anchors
/// - Saves back via PATCH `/valuation/settings`
/// - Live Preview: calls `/valuation/compute` to show value + nearest JJ pick
///
/// Drop this screen anywhere in your Flutter app and pass the base function URL
/// (e.g., https://<your-project>.functions.supabase.co/valuation) and optional franchiseId.
///
/// Example:
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ValuationSettingsPage(
///     baseUrl: const String.fromEnvironment('VALUATION_URL', defaultValue: ''),
///     franchiseId: null,
///   ),
/// ));

class ValuationSettingsPage extends StatefulWidget {
  final String baseUrl; // e.g., https://proj.functions.supabase.co/valuation
  final String? franchiseId; // optional

  const ValuationSettingsPage({super.key, required this.baseUrl, this.franchiseId});

  @override
  State<ValuationSettingsPage> createState() => _ValuationSettingsPageState();
}

class _ValuationSettingsPageState extends State<ValuationSettingsPage> {
  Map<String, dynamic>? _settings; // raw JSON settings blob
  bool _loading = false;
  bool _saving = false;

  // Preview inputs
  int _prevOvr = 80;
  int _prevAge = 21;
  String _prevPos = 'QB';
  String _prevDev = 'X-Factor';

  // Preview outputs
  double? _prevValue;
  int? _prevPick;
  int? _prevRound;
  int? _prevPickInRound;
  double? _prevNearestPoints;
  Map<String, dynamic>? _prevDetails;

  // --- Convenience getters/setters into the nested map ---
  double _getNum(List<String> path, {double fallback = 0}) {
    dynamic cur = _settings;
    for (final key in path) {
      if (cur is Map && cur.containsKey(key)) {
        cur = cur[key];
      } else {
        return fallback;
      }
    }
    if (cur is num) return cur.toDouble();
    return fallback;
  }

  void _setNum(List<String> path, double value) {
    Map<String, dynamic> cur = _settings!;
    for (int i = 0; i < path.length - 1; i++) {
      cur = (cur[path[i]] ??= <String, dynamic>{}) as Map<String, dynamic>;
    }
    cur[path.last] = value;
    setState(() {});
  }

  Map<String, dynamic> _getMap(List<String> path) {
    dynamic cur = _settings;
    for (final key in path) {
      if (cur is Map && cur.containsKey(key)) {
        cur = cur[key];
      } else {
        return <String, dynamic>{};
      }
    }
    return (cur as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  void _setMap(List<String> path, Map<String, dynamic> value) {
    Map<String, dynamic> cur = _settings!;
    for (int i = 0; i < path.length - 1; i++) {
      cur = (cur[path[i]] ??= <String, dynamic>{}) as Map<String, dynamic>;
    }
    cur[path.last] = value;
    setState(() {});
  }

  // --- HTTP ---
  Future<void> _load() async {
    if (widget.baseUrl.isEmpty) {
      _snack('Set baseUrl to your valuation function.');
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/settings').replace(
        queryParameters: {
          if (widget.franchiseId != null) 'franchise_id': widget.franchiseId!,
        },
      );
      final resp = await http.get(uri);
      if (resp.statusCode >= 300) throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['ok'] != true) throw Exception(json['error'] ?? 'load_failed');
      setState(() => _settings = Map<String, dynamic>.from(json['settings'] as Map));
    } catch (e) {
      _snack('Load failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (widget.baseUrl.isEmpty) {
      _snack('Set baseUrl to your valuation function.');
      return;
    }
    if (_settings == null) return;
    setState(() => _saving = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/settings');
      final resp = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (widget.franchiseId != null) 'franchise_id': widget.franchiseId,
          'settings': _settings,
        }),
      );
      if (resp.statusCode >= 300) throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['ok'] != true) throw Exception(json['error'] ?? 'save_failed');
      _snack('Saved ✔');
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _computePreview() async {
    if (_settings == null) return;
    try {
      final uri = Uri.parse('${widget.baseUrl}/compute');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ovr': _prevOvr,
          'age': _prevAge,
          'pos': _prevPos,
          'dev': _prevDev,
          if (widget.franchiseId != null) 'franchise_id': widget.franchiseId,
        }),
      );
      if (resp.statusCode >= 300) throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['ok'] != true) throw Exception(json['error'] ?? 'compute_failed');
      setState(() {
        _prevValue = (json['value'] as num).toDouble();
        _prevPick = json['nearest_pick'] as int;
        _prevRound = json['round'] as int;
        _prevPickInRound = json['pick_in_round'] as int;
        _prevNearestPoints = (json['nearest_points'] as num).toDouble();
        _prevDetails = Map<String, dynamic>.from(json['details'] as Map);
      });
    } catch (e) {
      _snack('Compute failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valuation Settings'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _settings == null
          ? Center(child: _loading ? const CircularProgressIndicator() : const Text('No settings loaded'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConnectionCard(),
          const SizedBox(height: 12),
          _ovrAnchorsCard(),
          const SizedBox(height: 12),
          _ageCard(),
          const SizedBox(height: 12),
          _youthBufferCard(),
          const SizedBox(height: 12),
          _devTraitCard(),
          const SizedBox(height: 12),
          _previewCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Function Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SelectableText('Base URL: ${widget.baseUrl}')
          ],
        ),
      ),
    );
  }

  Widget _ovrAnchorsCard() {
    final qb60 = _getNum(['ovr_curve', 'qb60'], fallback: 2.5);
    final qb99 = _getNum(['ovr_curve', 'qb99'], fallback: 6000);
    final gamma = _getNum(['ovr_curve', 'gamma'], fallback: 1.0);
    final spread = _getNum(['pos_spread_scalar'], fallback: 1.5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('OVR Curve & Position Spread', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _numRow('QB @ 60 OVR', qb60, 0, 20000, (v) => _setNum(['ovr_curve', 'qb60'], v)),
            _numRow('QB @ 99 OVR', qb99, 0, 50000, (v) => _setNum(['ovr_curve', 'qb99'], v)),
            _sliderRow('OVR Emphasis γ (>1 lifts high OVR)', gamma, 0.80, 1.50, 0.01, (v) => _setNum(['ovr_curve', 'gamma'], v)),
            const Divider(),
            _sliderRow('Position Spread Scalar (s)', spread, 0.0, 3.0, 0.01, (v) => _setNum(['pos_spread_scalar'], v)),
            const SizedBox(height: 6),
            const Text('Note: per-position offsets are configured elsewhere (not in this page).')
          ],
        ),
      ),
    );
  }

  Widget _ageCard() {
    final gain = _getNum(['age', 'gain'], fallback: 4.0);
    final cliff25 = _getNum(['age', 'cliff_25_27'], fallback: 0.90);
    final cliff28 = _getNum(['age', 'cliff_28_plus'], fallback: 0.75);
    final relief = _getNum(['age', 'penalty_relief_over28'], fallback: 0.0);
    final floorAge = _getNum(['age', 'floor_age'], fallback: 35).toInt();
    final floorVal = _getNum(['age', 'floor_value'], fallback: 0.0);
    final schedule = _getMap(['age', 'base_schedule']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Age Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _sliderRow('Age Gain (intensity)', gain, 0.0, 6.0, 0.05, (v) => _setNum(['age','gain'], v)),
            _sliderRow('Cliff 25–27 Multiplier', cliff25, 0.5, 1.0, 0.01, (v) => _setNum(['age','cliff_25_27'], v)),
            _sliderRow('Cliff 28+ Multiplier', cliff28, 0.5, 1.0, 0.01, (v) => _setNum(['age','cliff_28_plus'], v)),
            _sliderRow('Age 28+ Relief (reduce penalty)', relief, 0.0, 0.30, 0.01, (v) => _setNum(['age','penalty_relief_over28'], v)),
            _intSliderRow('Floor Age (clamp ≤)', floorAge, 20, 40, (v) => _setNum(['age','floor_age'], v.toDouble())),
            _sliderRow('Floor Value (≥ Floor Age)', floorVal, 0.0, 1.0, 0.01, (v) => _setNum(['age','floor_value'], v)),
            const SizedBox(height: 12),
            const Text('Base Schedule (per age, pre-cliffs) — tap age to edit'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(21, (i) {
                final age = 20 + i;
                final val = (schedule['$age'] ?? 1.0) as num;
                return ActionChip(
                  label: Text('$age: ${val.toStringAsFixed(2)}'),
                  onPressed: () async {
                    final newVal = await _promptNumber(context, title: 'Age $age Multiplier', initial: val.toDouble(), min: 0.0, max: 5.0, step: 0.05);
                    if (newVal != null) {
                      final newSched = Map<String, dynamic>.from(schedule);
                      newSched['$age'] = newVal;
                      _setMap(['age','base_schedule'], newSched);
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _youthBufferCard() {
    final band = _getMap(['youth_buffer','band']);
    final dmax = _getMap(['youth_buffer','dmax']);

    final positions = [
      'QB','WR','CB','LE','RE','LOLB','ROLB','LT','RT','DT','FS','SS','TE','MLB','HB','LG','C','RG','K','P','LS'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Positional Youth Buffer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Age Bands (fraction of Dmax applied):'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [20,21,22,23,24,25,26,27,28].map((age){
                final v = (band['$age'] ?? 0.0) as num;
                return ActionChip(
                  label: Text('$age: ${v.toStringAsFixed(2)}'),
                  onPressed: () async {
                    final newVal = await _promptNumber(context, title: 'Band for age $age (0..1)', initial: v.toDouble(), min: 0.0, max: 1.0, step: 0.05);
                    if (newVal != null) {
                      final nb = Map<String, dynamic>.from(band);
                      nb['$age'] = newVal;
                      _setMap(['youth_buffer','band'], nb);
                    }
                  },
                );
              }).toList(),
            ),
            const Divider(height: 24),
            const Text('Dmax per Position (max extra at youngest, 0..0.30 typical):'),
            const SizedBox(height: 8),
            ...positions.map((p){
              final v = (dmax[p] ?? 0.0) as num;
              return _sliderRow('$p Dmax', v.toDouble(), 0.0, 0.30, 0.005, (x){
                final nm = Map<String, dynamic>.from(dmax);
                nm[p] = x;
                _setMap(['youth_buffer','dmax'], nm);
              });
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _devTraitCard() {
    final traitScores = _getMap(['dev_trait','trait_scores']);
    final dcap = _getMap(['dev_trait','dcap']);
    final weights = _getMap(['dev_trait','weights']);

    final traitOrder = ['Normal','Star','Superstar','X-Factor'];
    final posGroups = [
      'QB','WR','CB','LE','RE','LOLB','ROLB','LT','RT','DT','FS','SS','TE','MLB','HB','IOL','LG','C','RG','K','P','LS'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dev Trait', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Trait Scores (Normal=0 always):'),
            const SizedBox(height: 8),
            ...traitOrder.map((t){
              final v = (traitScores[t] ?? 0.0) as num;
              return _sliderRow('$t Score', v.toDouble(), 0.0, 10.0, 0.05, (x){
                final nm = Map<String, dynamic>.from(traitScores);
                nm[t] = x;
                _setMap(['dev_trait','trait_scores'], nm);
              });
            }),
            const Divider(height: 24),
            const Text('Per-Position Caps (Dcap):'),
            const SizedBox(height: 8),
            ...posGroups.map((p){
              final v = (dcap[p] ?? 0.0) as num;
              return _sliderRow('$p Dcap', v.toDouble(), 0.0, 0.30, 0.005, (x){
                final nm = Map<String, dynamic>.from(dcap);
                nm[p] = x;
                _setMap(['dev_trait','dcap'], nm);
              });
            }),
            const Divider(height: 24),
            const Text('Per-Position Weights (XP vs Abilities)'),
            const SizedBox(height: 8),
            ...posGroups.map((p){
              final w = Map<String, dynamic>.from(weights[p] ?? {'w_xp':0.5,'w_abil':0.5});
              final wxp = (w['w_xp'] as num).toDouble();
              return _sliderRow('$p w_xp (w_abil = 1 - w_xp)', wxp, 0.0, 1.0, 0.01, (x){
                final nw = Map<String, dynamic>.from(weights);
                nw[p] = {'w_xp': x, 'w_abil': (1 - x)};
                _setMap(['dev_trait','weights'], nw);
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _previewCard() {
    final positions = [
      'QB','WR','CB','LE','RE','LOLB','ROLB','LT','RT','DT','FS','SS','TE','MLB','HB','LG','C','RG','K','P','LS'
    ];
    final devs = ['Normal','Star','Superstar','X-Factor'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _intSliderRow('OVR', _prevOvr, 60, 99, (v){ setState(()=>_prevOvr=v); })),
              const SizedBox(width: 12),
              Expanded(child: _intSliderRow('Age', _prevAge, 20, 40, (v){ setState(()=>_prevAge=v); })),
            ]),
            Row(children: [
              Expanded(child: _dropdownRow('Position', _prevPos, positions, (v){ setState(()=>_prevPos=v!); })),
              const SizedBox(width: 12),
              Expanded(child: _dropdownRow('Dev', _prevDev, devs, (v){ setState(()=>_prevDev=v!); })),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _computePreview,
                icon: const Icon(Icons.calculate),
                label: const Text('Compute'),
              ),
            ),
            if (_prevValue != null) ...[
              const SizedBox(height: 12),
              Text('Value: ${_prevValue!.toStringAsFixed(1)} pts'),
              Text('Nearest Pick: R${_prevRound} P${_prevPickInRound} (overall ${_prevPick}) — ${_prevNearestPoints?.toStringAsFixed(1)} pts'),
              const SizedBox(height: 8),
              if (_prevDetails != null)
                Text('Multipliers: ${jsonEncode(_prevDetails!['multipliers'])}'),
            ]
          ],
        ),
      ),
    );
  }

  // ---- Helpers ----
  Widget _sliderRow(String label, double value, double min, double max, double step, ValueChanged<double> onChanged){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label)),
            SizedBox(
              width: 96,
              child: Text(value.toStringAsFixed(step < 0.01 ? 3 : 2), textAlign: TextAlign.right),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min, max: max, divisions: ((max-min)/step).round(),
          label: value.toStringAsFixed(step < 0.01 ? 3 : 2),
          onChanged: (v)=> setState(()=> onChanged(v)),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _intSliderRow(String label, int value, int min, int max, ValueChanged<int> onChanged){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label)),
            SizedBox(width: 64, child: Text('$value', textAlign: TextAlign.right)),
          ],
        ),
        Slider(
          value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(), max: max.toDouble(), divisions: (max-min),
          label: '$value',
          onChanged: (v)=> setState(()=> onChanged(v.round())),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _numRow(String label, double value, double min, double max, ValueChanged<double> onChanged){
    final controller = TextEditingController(text: value.toStringAsFixed(2));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 140,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              onSubmitted: (txt){
                final v = double.tryParse(txt);
                if (v==null || v<min || v>max){ _snack('Enter a number between $min and $max'); return; }
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> items, ValueChanged<String?> onChanged){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          items: items.map((e)=> DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<double?> _promptNumber(BuildContext context, {required String title, required double initial, double min=0, double max=10, double step=0.1}) async {
    final controller = TextEditingController(text: initial.toStringAsFixed(3));
    return showDialog<double>(context: context, builder: (ctx){
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: 'Between $min and $max'),
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: (){
            final v = double.tryParse(controller.text.trim());
            if (v==null || v<min || v>max){ _snack('Enter a number between $min and $max'); return; }
            Navigator.pop(ctx, v);
          }, child: const Text('OK')),
        ],
      );
    });
  }

  void _snack(String msg){
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
