import 'package:flutter/material.dart';
import '../services/valuation_service.dart';

/// A simple widget that shows player valuation
/// Can be used in player cards, trade screens, etc.
class PlayerValuationWidget extends StatefulWidget {
  final int ovr;
  final int age;
  final String position;
  final String devTrait;
  final String? franchiseId;

  const PlayerValuationWidget({
    super.key,
    required this.ovr,
    required this.age,
    required this.position,
    required this.devTrait,
    this.franchiseId,
  });

  @override
  State<PlayerValuationWidget> createState() => _PlayerValuationWidgetState();
}

class _PlayerValuationWidgetState extends State<PlayerValuationWidget> {
  final ValuationService _service = ValuationService(
    baseUrl: 'https://fxbpsuisqzffyggihvin.supabase.co/functions/v1/valuation',
  );
  
  ValuationResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _computeValue();
  }

  @override
  void didUpdateWidget(PlayerValuationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ovr != widget.ovr ||
        oldWidget.age != widget.age ||
        oldWidget.position != widget.position ||
        oldWidget.devTrait != widget.devTrait ||
        oldWidget.franchiseId != widget.franchiseId) {
      _computeValue();
    }
  }

  Future<void> _computeValue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.computeValue(
        ovr: widget.ovr,
        age: widget.age,
        position: widget.position,
        devTrait: widget.devTrait,
      );
      
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Computing value...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text('Error', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No valuation data'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Player Valuation',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Value:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '${_result!.value.toStringAsFixed(1)} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Draft Pick:', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  'R${_result!.round} P${_result!.pickInRound} (#${_result!.nearestPick})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Multipliers:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pos: ${_result!.details.multipliers.pos.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                      Text('Age: ${_result!.details.multipliers.age.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Youth: ${_result!.details.multipliers.youth.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                      Text('Dev: ${_result!.details.multipliers.dev.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
