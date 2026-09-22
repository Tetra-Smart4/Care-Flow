import 'package:flutter/material.dart';

import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final service = CareFlowFeatureService.instance;

  bool loading = true;
  List<Map<String, dynamic>> records = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await service.patientRecords();

      if (!mounted) {
        return;
      }

      setState(() {
        records = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load records: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const FeatureScaffold(
        title: 'Medical records',
        subtitle: 'Your connected care history',
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (records.isEmpty) {
      return const FeatureScaffold(
        title: 'Medical records',
        subtitle: 'Your connected care history',
        child: EmptyState(
          icon: Icons.folder_open_rounded,
          title: 'No records yet',
          message:
              'Consultation records, prescriptions and lab reports will appear after your clinic visit.',
        ),
      );
    }

    return FeatureScaffold(
      title: 'Medical records',
      subtitle: 'Your connected care history',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          28,
        ),
        children: <Widget>[
          const SectionTitle('Timeline'),
          for (final record in records)
            Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                leading: Icon(
                  _icon(
                    '${record['record_type'] ?? ''}',
                  ),
                  color: CareFlowUIColors.primary,
                ),
                title: Text(
                  '${record['title'] ?? 'Record'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${record['record_date'] ?? ''}\n'
                  '${record['summary'] ?? ''}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }

  IconData _icon(String type) {
    final value = type.toLowerCase();

    if (value.contains('prescription')) {
      return Icons.medication_rounded;
    }

    if (value.contains('lab')) {
      return Icons.science_rounded;
    }

    return Icons.medical_information_rounded;
  }
}
