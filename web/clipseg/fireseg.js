/* FireShield in-browser CLIPSeg detector (progressive enhancement).
 *
 * Prompt-based zero-shot segmentation of fire-safety equipment using
 * Transformers.js + CLIPSeg (Xenova/clipseg-rd64-refined). Gives *presence +
 * coarse count* per equipment type; Qwen (server-side) reads type/condition and
 * is the baseline that always works. This layer only augments capable devices.
 *
 * Exposes two globals used by lib/fireshield/services/fs_clipseg_interop_web.dart:
 *   window.fsClipsegSupported()             -> boolean
 *   window.fsDetectEquipment(url, promptsJson) -> Promise<string>  (JSON array)
 *
 * Everything is wrapped so a failure degrades to "no detections" — never an
 * app crash. For strict-CSP / offline hosting, vendor transformers.js and the
 * model under web/clipseg/ and set window.FIRESHIELD_TRANSFORMERS_URL /
 * env.localModelPath before first use.
 */
(function () {
  'use strict';

  const TRANSFORMERS_URL =
    window.FIRESHIELD_TRANSFORMERS_URL ||
    'https://cdn.jsdelivr.net/npm/@huggingface/transformers@3.0.2';
  const MODEL_ID = 'Xenova/clipseg-rd64-refined';
  const THRESHOLD = 0.4; // sigmoid prob above which a pixel is "equipment"
  const MIN_BLOB_PX = 12; // ignore specks when counting instances (on 64x64)
  // CLIPSeg's own processor resizes to a fixed model input anyway (352x352),
  // so decoding/resizing a full 12MP phone photo before that only burns time.
  // Cap the longest side before handing the image to the processor.
  const MAX_INPUT_SIDE = 640;

  let _pipe = null; // { processor, model, tensorOps }
  let _loading = null;

  // ── capability gate ────────────────────────────────────────────────────────
  function fsClipsegSupported() {
    try {
      const hasGpu = typeof navigator !== 'undefined' && 'gpu' in navigator;
      const mem = (navigator && navigator.deviceMemory) || 4;
      const hasWasm = typeof WebAssembly === 'object';
      // CPU/WASM inference can take minutes and lock the UI. Only advertise
      // the enhancement when WebGPU is present; Qwen remains the baseline.
      return hasWasm && hasGpu && mem >= 4;
    } catch (_) {
      return false;
    }
  }

  async function loadModel() {
    if (_pipe) return _pipe;
    if (_loading) return _loading;
    _loading = (async () => {
      const t = await import(/* @vite-ignore */ TRANSFORMERS_URL);
      const { AutoProcessor, CLIPSegForImageSegmentation, RawImage, env } = t;
      if (window.FIRESHIELD_LOCAL_MODELS) {
        env.allowRemoteModels = false;
        env.localModelPath = window.FIRESHIELD_LOCAL_MODELS;
      }
      const processor = await AutoProcessor.from_pretrained(MODEL_ID);
      const model = await CLIPSegForImageSegmentation.from_pretrained(MODEL_ID, {
        dtype: 'fp16',
      });
      _pipe = { processor, model, RawImage, sigmoid: t.sigmoid };
      return _pipe;
    })();
    return _loading;
  }

  // Connected-component count on a thresholded HxW probability grid.
  function countBlobs(probs, w, h) {
    const seen = new Uint8Array(w * h);
    let blobs = 0;
    const stack = [];
    for (let i = 0; i < w * h; i++) {
      if (seen[i] || probs[i] < THRESHOLD) continue;
      // BFS flood fill
      let size = 0;
      stack.length = 0;
      stack.push(i);
      seen[i] = 1;
      while (stack.length) {
        const p = stack.pop();
        size++;
        const x = p % w;
        const y = (p / w) | 0;
        const nb = [
          x > 0 ? p - 1 : -1,
          x < w - 1 ? p + 1 : -1,
          y > 0 ? p - w : -1,
          y < h - 1 ? p + w : -1,
        ];
        for (const q of nb) {
          if (q >= 0 && !seen[q] && probs[q] >= THRESHOLD) {
            seen[q] = 1;
            stack.push(q);
          }
        }
      }
      if (size >= MIN_BLOB_PX) blobs++;
    }
    return blobs;
  }

  function sigmoid(x) {
    return 1 / (1 + Math.exp(-x));
  }

  // Downscale via canvas so decode + the processor's own resize work on a
  // bounded number of pixels regardless of the source photo's resolution.
  function downscale(dataUrl) {
    return new Promise((resolve) => {
      const img = new Image();
      img.onload = () => {
        const longest = Math.max(img.width, img.height);
        if (longest <= MAX_INPUT_SIDE) {
          resolve(dataUrl);
          return;
        }
        const scale = MAX_INPUT_SIDE / longest;
        const canvas = document.createElement('canvas');
        canvas.width = Math.round(img.width * scale);
        canvas.height = Math.round(img.height * scale);
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        resolve(canvas.toDataURL('image/jpeg', 0.85));
      };
      img.onerror = () => resolve(dataUrl); // fall back to the original on decode failure
      img.src = dataUrl;
    });
  }

  async function fsDetectEquipment(dataUrl, promptsJson) {
    if (!fsClipsegSupported()) return '[]';
    let prompts;
    try {
      prompts = JSON.parse(promptsJson); // { typeKey: promptText }
    } catch (_) {
      return '[]';
    }
    const typeKeys = Object.keys(prompts);
    const texts = typeKeys.map((k) => prompts[k]);
    if (texts.length === 0) return '[]';

    let pipe;
    try {
      pipe = await loadModel();
    } catch (_) {
      return '[]'; // model unavailable → let Qwen carry the run
    }

    try {
      const scaledUrl = await downscale(dataUrl);
      const image = await pipe.RawImage.fromURL(scaledUrl);
      // One image, N text prompts → N segmentation maps.
      const inputs = await pipe.processor(image, texts);
      const { logits } = await pipe.model(inputs);
      // logits shape: [N, H, W] (or [N,1,H,W]) — normalize to per-prompt grids.
      const data = logits.data;
      const dims = logits.dims;
      const n = dims[0];
      const h = dims[dims.length - 2];
      const w = dims[dims.length - 1];
      const per = h * w;

      const detections = [];
      for (let idx = 0; idx < n && idx < typeKeys.length; idx++) {
        const probs = new Float32Array(per);
        let sum = 0;
        for (let p = 0; p < per; p++) {
          const v = sigmoid(data[idx * per + p]);
          probs[p] = v;
          if (v >= THRESHOLD) sum++;
        }
        const coverage = sum / per; // fraction of image flagged
        if (coverage < 0.004) continue; // nothing meaningful
        const count = Math.max(1, countBlobs(probs, w, h));
        const conf = Math.min(1, coverage * 6); // rough confidence proxy
        detections.push({
          type: typeKeys[idx],
          count,
          label: '',
          condition: '',
          confidence: Number(conf.toFixed(2)),
        });
      }
      return JSON.stringify(detections);
    } catch (_) {
      return '[]';
    }
  }

  window.fsClipsegSupported = fsClipsegSupported;
  window.fsDetectEquipment = fsDetectEquipment;
})();
