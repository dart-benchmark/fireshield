/// Non-web stub for CLIPSeg interop. In-browser segmentation is web-only, so on
/// any other platform it reports unsupported and the caller uses server vision.
library;

bool clipsegSupported() => false;

Future<List<Map<String, dynamic>>> detectEquipment(
  String imageDataUrl,
  Map<String, String> prompts,
) async =>
    const [];
