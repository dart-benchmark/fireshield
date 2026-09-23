/// Web CLIPSeg interop — bridges to `web/clipseg/fireseg.js` via dart:js_interop.
///
/// The JS side exposes two globals:
///   window.fsClipsegSupported()            -> boolean (WebGPU / memory gate)
///   window.fsDetectEquipment(url, prompts) -> Promise<string>  (JSON array)
/// where `prompts` is a JSON object {typeKey: promptText} and the resolved
/// string is a JSON array of {type, count, label, confidence, condition}.
library;

import 'dart:convert';
import 'dart:js_interop';

@JS('fsClipsegSupported')
external JSBoolean? _supported();

@JS('fsDetectEquipment')
external JSPromise<JSString>? _detect(JSString dataUrl, JSString promptsJson);

bool clipsegSupported() {
  try {
    return _supported()?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

Future<List<Map<String, dynamic>>> detectEquipment(
  String imageDataUrl,
  Map<String, String> prompts,
) async {
  try {
    final promise = _detect(imageDataUrl.toJS, jsonEncode(prompts).toJS);
    if (promise == null) return const [];
    final result = await promise.toDart;
    final decoded = jsonDecode(result.toDart);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
}
