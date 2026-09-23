import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock_data.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});
  @override
  State<EquipmentScreen> createState() => _State();
}

class _State extends State<EquipmentScreen> {
  String _filter = 'All';
  String _search = '';

  List<MockEquipment> get _filtered => mockEquipment.where((e) {
    final matchFilter = _filter == 'All' || e.status == _filter;
    final matchSearch = _search.isEmpty || e.type.toLowerCase().contains(_search.toLowerCase()) || e.location.toLowerCase().contains(_search.toLowerCase());
    return matchFilter && matchSearch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(context, title: 'Equipment Registry', subtitle: '${mockEquipment.length} items registered', showBack: true,
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner_rounded), onPressed: () => _showQrSheet(context)),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddEquipSheet(context)),
        ],
      ),
      body: Column(
        children: [
          _SummaryBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(hintText: 'Search equipment, location...', prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All', 'OPERATIONAL', 'MAINTENANCE_DUE', 'DEFECTIVE'].map((f) {
                final selected = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(f == 'All' ? 'All' : f.replaceAll('_', ' '),
                      style: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EquipmentCard(equipment: _filtered[i], onTap: () => _showDetail(context, _filtered[i])),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, MockEquipment eq) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EquipmentDetailSheet(equipment: eq),
    );
  }

  void _showQrSheet(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Scan QR / NFC Tag', style: AppTextStyles.h4),
        const SizedBox(height: 24),
        Container(height: 220, width: 220, decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(16), color: AppColors.borderLight), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.textHint), SizedBox(height: 12), Text('Camera View', style: AppTextStyles.bodySmall)]))),
        const SizedBox(height: 20),
        const Text('Point camera at equipment QR code or tap NFC tag', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 32),
      ]),
    ),
  );

  void _showAddEquipSheet(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Add Equipment', style: AppTextStyles.h4),
        const SizedBox(height: 20),
        const TextField(decoration: InputDecoration(labelText: 'Equipment Type', prefixIcon: Icon(Icons.category_rounded, size: 20, color: AppColors.textSecondary))),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_rounded, size: 20, color: AppColors.textSecondary))),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Serial Number', prefixIcon: Icon(Icons.pin_rounded, size: 20, color: AppColors.textSecondary))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Equipment registered successfully'))); }, child: const Text('Register Equipment')),
      ]),
    ),
  );
}

class _SummaryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _SummaryStat(label: 'Total', value: '${mockEquipment.length}', color: AppColors.textPrimary),
      const _SummaryStat(label: 'Operational', value: '5', color: AppColors.success),
      const _SummaryStat(label: 'Service Due', value: '1', color: AppColors.warning),
      const _SummaryStat(label: 'Defective', value: '1', color: AppColors.error),
      const _SummaryStat(label: 'Missing', value: '0', color: AppColors.textSecondary),
    ]),
  );
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.h4.copyWith(color: color)),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _EquipmentCard extends StatelessWidget {
  final MockEquipment equipment;
  final VoidCallback onTap;
  const _EquipmentCard({required this.equipment, required this.onTap});

  IconData get _icon => switch (equipment.type) {
    String t when t.contains('Extinguisher') => Icons.fire_extinguisher_rounded,
    String t when t.contains('Detector') => Icons.sensors_rounded,
    String t when t.contains('Pump') => Icons.water_drop_rounded,
    String t when t.contains('Alarm') => Icons.notifications_active_rounded,
    String t when t.contains('Hose') => Icons.water_rounded,
    String t when t.contains('Sprinkler') => Icons.water_rounded,
    String t when t.contains('Exit') => Icons.emergency_rounded,
    _ => Icons.hardware_rounded,
  };

  Color get _statusColor => switch (equipment.status) {
    'OPERATIONAL' => AppColors.success,
    'MAINTENANCE_DUE' => AppColors.warning,
    'DEFECTIVE' => AppColors.error,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: equipment.status == 'OPERATIONAL' ? AppColors.borderLight : _statusColor.withValues(alpha: 0.3), width: equipment.status == 'OPERATIONAL' ? 1 : 1.5),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(equipment.type, style: AppTextStyles.h6),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textHint),
                const SizedBox(width: 3),
                Expanded(child: Text(equipment.location, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Text('Next: ', style: AppTextStyles.caption),
                Text(equipment.nextService, style: AppTextStyles.caption.copyWith(color: equipment.status == 'MAINTENANCE_DUE' ? AppColors.warning : AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ]),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusBadge(status: equipment.status),
            const SizedBox(height: 6),
            const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.textHint),
          ]),
        ],
      ),
    ),
  );
}

class _EquipmentDetailSheet extends StatelessWidget {
  final MockEquipment equipment;
  const _EquipmentDetailSheet({required this.equipment});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Text(equipment.type, style: AppTextStyles.h4)),
          StatusBadge(status: equipment.status),
        ]),
        Text(equipment.location, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        const Divider(),
        InfoRow(label: 'Equipment ID', value: equipment.id),
        InfoRow(label: 'Make / Brand', value: equipment.make),
        InfoRow(label: 'Serial Number', value: equipment.serial),
        InfoRow(label: 'Last Serviced', value: equipment.lastService),
        InfoRow(label: 'Next Service', value: equipment.nextService, valueColor: equipment.status == 'MAINTENANCE_DUE' ? AppColors.warning : null),
        InfoRow(label: 'Condition', value: equipment.condition, valueColor: equipment.status == 'OPERATIONAL' ? AppColors.success : AppColors.warning),
        InfoRow(label: 'Floor', value: equipment.floor == -1 ? 'Basement' : 'Floor ${equipment.floor}', isLast: true),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.history_rounded, size: 18), label: const Text('Service History'), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service request raised'))); }, icon: const Icon(Icons.build_rounded, size: 18), label: const Text('Log Service'))),
        ]),
      ],
    ),
  );
}
