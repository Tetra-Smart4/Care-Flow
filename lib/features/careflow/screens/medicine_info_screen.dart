import 'package:flutter/material.dart';

import '../models/feature_models.dart';
import '../services/feature_service.dart';
import '../widgets/feature_widgets.dart';
import '../../../ui/theme/careflow_ui_theme.dart';

class MedicineInfoScreen extends StatefulWidget {
  const MedicineInfoScreen({super.key});

  @override
  State<MedicineInfoScreen> createState() => _MedicineInfoScreenState();
}

class _MedicineInfoScreenState extends State<MedicineInfoScreen> {
  final service = CareFlowFeatureService.instance;
  final search = TextEditingController();

  List<MedicineInfo> all = <MedicineInfo>[];
  List<MedicineInfo> shown = <MedicineInfo>[];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    search.addListener(_filter);
    _load();
  }

  Future<void> _load() async {
    try {
      final medicines = await service.medicines();

      if (!mounted) return;

      setState(() {
        all = medicines;
        shown = medicines;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load medicine information: $e',
          ),
        ),
      );
    }
  }

  void _filter() {
    final query = search.text.trim().toLowerCase();

    setState(() {
      shown = all.where((medicine) {
        return medicine.name.toLowerCase().contains(query) ||
            medicine.commonUses.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _detail(MedicineInfo medicine) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        final sections = <Widget>[
          Text(
            medicine.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _label(
            'Common uses',
            medicine.commonUses,
          ),
          _label(
            'Precautions',
            medicine.precautions,
          ),
          _label(
            'Common side effects',
            medicine.sideEffects,
          ),
        ];

        final info = medicine.info;
        if (info != null && info.isNotEmpty) {
          sections.add(
            _label(
              'General information',
              info,
            ),
          );
        }

        sections.add(
          const SizedBox(height: 8),
        );
        sections.add(
          const Text(
            'This module is informational. Medicine use, dosage, and suitability should be confirmed with a qualified healthcare professional.',
            style: TextStyle(
              fontSize: 11,
              color: CareFlowUIColors.muted,
              height: 1.4,
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            22,
            4,
            22,
            28,
          ),
          child: ListView(
            shrinkWrap: true,
            children: sections,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const FeatureScaffold(
        title: 'Medicine information',
        subtitle: 'Reference information',
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final content = <Widget>[
      TextField(
        controller: search,
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
          ),
          hintText: 'Search medicines...',
        ),
      ),
      const SizedBox(height: 14),
    ];

    if (shown.isEmpty) {
      content.add(
        const EmptyState(
          icon: Icons.medication_outlined,
          title: 'No medicines found',
          message: 'Try a different medicine name or search term.',
        ),
      );
    } else {
      for (final medicine in shown) {
        content.add(
          Card(
            margin: const EdgeInsets.only(
              bottom: 10,
            ),
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CareFlowUIColors.softTeal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: CareFlowUIColors.teal,
                ),
              ),
              title: Text(
                medicine.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                medicine.commonUses,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: () => _detail(medicine),
            ),
          ),
        );
      }
    }

    return FeatureScaffold(
      title: 'Medicine information',
      subtitle: 'Reference only — follow your clinician\'s prescription',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          28,
        ),
        children: content,
      ),
    );
  }

  Widget _label(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: CareFlowUIColors.muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
