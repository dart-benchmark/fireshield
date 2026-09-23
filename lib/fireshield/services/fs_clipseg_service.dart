/// In-browser CLIPSeg equipment detection — a progressive enhancement.
///
/// CLIPSeg runs client-side via Transformers.js (`web/clipseg/fireseg.js`) and
/// gives prompt-based *presence + coarse count* per equipment type. It is
/// capability-gated (WebGPU / memory): where it isn't supported — most low-end
/// phones — [supported] is false and the caller falls back to server-side Qwen
/// vision, so no device is forced to download a large model.
///
/// The heavy lifting lives in the platform files; this is the shared surface.
library;

import '../data/fs_models.dart';
import 'fs_clipseg_interop_stub.dart'
    if (dart.library.html) 'fs_clipseg_interop_web.dart' as interop;

/// The prompt set CLIPSeg segments each image against. Aligned to the app's
/// equipment inventory types and the Worker's detection vocabulary so CLIPSeg
/// and Qwen results merge cleanly.
const Map<String, String> kClipsegPrompts = {
  'extinguisher': 'a red fire extinguisher cylinder',
  'sprinkler': 'a ceiling fire sprinkler head',
  'smoke_detector': 'a round smoke detector mounted on a ceiling',
  'heat_detector': 'a heat detector mounted on a ceiling',
  'manual_call_point': 'a red manual call point break-glass alarm',
  'alarm_sounder_strobe': 'a fire alarm sounder or red alarm strobe',
  'alarm_panel': 'a fire alarm control panel on the wall',
  'exit_sign': 'an illuminated green exit sign',
  'emergency_light': 'an emergency light fitting',
  'fire_door': 'a labelled self-closing fire door',
  'door_closer': 'a hydraulic door closer on top of a fire door',
  'hydrant_hose_reel': 'a red fire hose reel inside a cabinet',
  'landing_valve': 'a fire hydrant landing valve or wet riser outlet',
  'kitchen_suppression': 'a commercial kitchen hood fire suppression nozzle',
  'fire_pump': 'a red fire water pump with pipework',
  'fire_department_connection':
      'a fire brigade inlet or fire department connection',
  'evacuation_map': 'a wall-mounted fire evacuation plan map',
};

class FsClipsegService {
  /// Whether in-browser CLIPSeg can run on this device/browser right now.
  bool get supported => interop.clipsegSupported();

  /// Detect equipment in one image (base64 data URL). Returns per-type counts.
  /// Silently returns empty on any error so the Qwen path still carries the run.
  Future<List<DetectedEquipment>> detect(String imageDataUrl) async {
    if (!supported) return const [];
    try {
      final raw = await interop
          .detectEquipment(imageDataUrl, kClipsegPrompts)
          .timeout(const Duration(seconds: 12), onTimeout: () => const []);
      return raw
          .map((m) => DetectedEquipment.fromJson({...m, 'source': 'clipseg'}))
          .where((d) => d.count > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Detect across a batch, summing counts per type.
  Future<List<DetectedEquipment>> detectBatch(
      List<String> imageDataUrls) async {
    if (!supported) return const [];
    final byType = <String, DetectedEquipment>{};
    for (final url in imageDataUrls) {
      for (final d in await detect(url)) {
        final prev = byType[d.type];
        byType[d.type] = DetectedEquipment(
          type: d.type,
          count: (prev?.count ?? 0) + d.count,
          source: 'clipseg',
          condition: d.condition,
          label: d.label,
          confidence: prev == null
              ? d.confidence
              : (prev.confidence + d.confidence) / 2,
        );
      }
    }
    return byType.values.toList();
  }
}
