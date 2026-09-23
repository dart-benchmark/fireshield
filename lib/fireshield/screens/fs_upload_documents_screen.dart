/// Port of pwa_app/src/screens/manager/UploadDocuments.jsx
library;

import 'package:flutter/material.dart';

import '../theme/fs_tokens.dart';
import '../widgets/fs_ui.dart';

class _DocTemplate {
  final String icon, name, description, status;
  final bool required;
  const _DocTemplate(
      this.icon, this.name, this.description, this.required, this.status);
}

const _kTemplates = [
  _DocTemplate('🏛️', 'NOC Certificate', 'No Objection Certificate from Fire Dept', true, 'VALID'),
  _DocTemplate('📐', 'Floor Plan (DWG/PDF)', 'Architectural floor plan with fire escape routes', true, 'VALID'),
  _DocTemplate('🔥', 'Fire System Layout', 'Sprinkler, detector and alarm layout drawing', true, 'MISSING'),
  _DocTemplate('🚒', 'Hydrant & Hose Reel Map', 'Location of all fire hydrants and hose reels', true, 'VALID'),
  _DocTemplate('🚪', 'Evacuation Plan', 'Emergency evacuation routes and assembly points', true, 'EXPIRED'),
  _DocTemplate('🔧', 'Fire Equipment Maintenance Log', 'Last service and inspection records', false, 'PENDING'),
  _DocTemplate('📋', 'Insurance Certificate', 'Property and fire insurance policy document', false, 'MISSING'),
  _DocTemplate('📞', 'Emergency Contact List', 'Fire wardens and emergency personnel contacts', false, 'VALID'),
];

class FsUploadDocumentsScreen extends StatefulWidget {
  const FsUploadDocumentsScreen({super.key});

  @override
  State<FsUploadDocumentsScreen> createState() =>
      _FsUploadDocumentsScreenState();
}

class _FsUploadDocumentsScreenState extends State<FsUploadDocumentsScreen> {
  final Set<String> _uploaded = {};

  @override
  Widget build(BuildContext context) {
    final requiredDone = _kTemplates
        .where((t) => t.required && (t.status == 'VALID' || _uploaded.contains(t.name)))
        .length;
    final requiredTotal = _kTemplates.where((t) => t.required).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        FsCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Required documents',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: FsColors.gray900)),
                    const SizedBox(height: 6),
                    ProgressBar(
                      value: (requiredDone / requiredTotal) * 100,
                      color: requiredDone == requiredTotal
                          ? FsColors.success
                          : FsColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('$requiredDone/$requiredTotal',
                  style: FsText.title),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._kTemplates.map((t) {
          final done = t.status == 'VALID' || _uploaded.contains(t.name);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FsCard(
              onTap: () => setState(() {
                _uploaded.contains(t.name)
                    ? _uploaded.remove(t.name)
                    : _uploaded.add(t.name);
                if (t.status != 'VALID') {
                  FsToast.show(
                    context,
                    _uploaded.contains(t.name)
                        ? '${t.name} attached.'
                        : '${t.name} removed.',
                    type: FsToastType.success,
                  );
                }
              }),
              child: Row(
                children: [
                  Text(t.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(t.name,
                                    style: FsText.cardTitle,
                                    overflow: TextOverflow.ellipsis)),
                            if (t.required)
                              Text('required',
                                  style: FsText.micro
                                      .copyWith(color: FsColors.subtle)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(t.description, style: FsText.tiny),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                      status: done
                          ? 'Valid'
                          : t.status == 'EXPIRED'
                              ? 'Expired'
                              : t.status == 'PENDING'
                                  ? 'PENDING_REVIEW'
                                  : 'OPEN'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
