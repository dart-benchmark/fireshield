/// Port of pwa_app/src/screens/manager/EquipmentInventory.jsx
///
/// Browse fire safety assets by floor and asset type. The PWA has full
/// per-floor nesting for one sample floor (GF Atrium); this keeps that same
/// sample data and structure so the browsing pattern is real, and shows an
/// honest empty state for floors without seeded inventory.
library;

import 'package:flutter/material.dart';

import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

class _AssetType {
  final String key;
  final String label;
  final String icon;
  const _AssetType(this.key, this.label, this.icon);
}

const _kAssetTypes = [
  _AssetType('ext', 'Extinguishers', '🧯'),
  _AssetType('det', 'Detectors', '🔔'),
  _AssetType('hyd', 'Hydrant Points', '💧'),
  _AssetType('pmp', 'Fire Pumps', '⚙️'),
  _AssetType('spr', 'Sprinkler Heads', '🌊'),
  _AssetType('lit', 'Emergency Lights', '💡'),
  _AssetType('dor', 'Fire Doors', '🚪'),
  _AssetType('mcp', 'Manual Call Points', '🔴'),
];

const _kFloors = [
  'B2 Parking (Sub-Basement)', 'B1 Parking', 'GF Atrium',
  'F1 Retail', 'F2 Food Court', 'F3 Cinema',
];

class _Asset {
  final String id;
  final String type;
  final String location;
  final String status;
  const _Asset(this.id, this.type, this.location, this.status);
}

/// Only GF Atrium is seeded, matching the PWA's mock inventory — every
/// other floor is a real, honest empty state rather than fabricated rows.
const Map<String, List<_Asset>> _kInventory = {
  'ext': [
    _Asset('EXT-GF-001', 'ABC Powder 6kg', 'Near Main Entrance', 'OK'),
    _Asset('EXT-GF-002', 'CO₂ 4.5kg', 'Electrical Panel Room', 'OK'),
    _Asset('EXT-GF-003', 'ABC Powder 6kg', 'East Wing Corridor', 'DUE'),
  ],
  'det': [
    _Asset('DET-GF-001', 'Photoelectric Smoke', 'Atrium Ceiling Level 1', 'OK'),
    _Asset('DET-GF-002', 'Photoelectric Smoke', 'Atrium Ceiling Level 2', 'FAULT'),
    _Asset('DET-GF-003', 'Heat Detector', 'Electrical Riser', 'OK'),
  ],
  'hyd': [
    _Asset('HYD-GF-001', 'Landing Valve 65mm', 'Staircase S1 GF Level', 'OK'),
    _Asset('HYD-GF-002', 'Landing Valve 65mm', 'Staircase S2 GF Level', 'OK'),
  ],
  'spr': [
    _Asset('SPR-GF-001', 'Pendent 68°C Standard', 'Atrium Zone 1', 'OK'),
  ],
  'lit': [
    _Asset('LIT-GF-001', 'Self-Contained LED', 'Main Exit', 'OK'),
    _Asset('LIT-GF-002', 'Self-Contained LED', 'Staircase S1', 'LOW_BATTERY'),
  ],
  'dor': [
    _Asset('DOR-GF-001', '60-min Fire Door', 'Service Corridor A', 'OK'),
    _Asset('DOR-GF-002', '60-min Fire Door', 'Service Corridor B', 'PROPPED_OPEN'),
  ],
  'mcp': [
    _Asset('MCP-GF-001', 'Break Glass MCP', 'Near Main Entrance', 'OK'),
    _Asset('MCP-GF-002', 'Break Glass MCP', 'Staircase S1', 'OK'),
  ],
};

class FsEquipmentInventoryScreen extends StatefulWidget {
  const FsEquipmentInventoryScreen({super.key});

  @override
  State<FsEquipmentInventoryScreen> createState() =>
      _FsEquipmentInventoryScreenState();
}

class _FsEquipmentInventoryScreenState
    extends State<FsEquipmentInventoryScreen> {
  String _floor = 'GF Atrium';
  String? _type;

  @override
  Widget build(BuildContext context) {
    final seeded = _floor == 'GF Atrium';

    return Column(
      children: [
        Container(
          color: FsColors.surface,
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _kFloors
                .map((f) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _floor = f;
                          _type = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: f == _floor
                                ? FsColors.primary
                                : FsColors.gray100,
                            borderRadius:
                                BorderRadius.circular(FsRadius.full),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: f == _floor
                                  ? Colors.white
                                  : FsColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: !seeded
              ? EmptyState(
                  icon: '🧯',
                  title: 'No inventory seeded for $_floor',
                  subtitle:
                      'Asset data is captured floor by floor during onboarding. Try GF Atrium for a populated example.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.9,
                      children: _kAssetTypes.map((t) {
                        final count = _kInventory[t.key]?.length ?? 0;
                        final active = _type == t.key;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _type = active ? null : t.key),
                          child: Container(
                            decoration: BoxDecoration(
                              color: active
                                  ? FsColors.primary.withValues(alpha: 0.1)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(FsRadius.xl2),
                              border: Border.all(
                                color: active
                                    ? FsColors.primary
                                    : FsColors.border,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(t.icon,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 2),
                                Text('$count',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                                Text(
                                  t.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: FsText.micro,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (_type != null) ...[
                      Text(
                        _kAssetTypes.firstWhere((t) => t.key == _type).label
                            .toUpperCase(),
                        style: FsText.xs.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      ...(_kInventory[_type] ?? []).map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FsCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(a.id,
                                              style: FsText.tiny.copyWith(
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ],
                                      ),
                                      Text(a.type, style: FsText.cardTitle),
                                      Text(a.location, style: FsText.tiny),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                    status: a.status == 'OK'
                                        ? 'Valid'
                                        : a.status == 'FAULT'
                                            ? 'CRITICAL'
                                            : 'MAJOR'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if ((_kInventory[_type] ?? []).isEmpty)
                        const EmptyState(
                          icon: '📭',
                          title: 'None recorded',
                          subtitle:
                              'No assets of this type logged for this floor.',
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
