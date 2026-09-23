# floorplan2dxf

Working proof of a **semantic** floor-plan raster → DXF pipeline:

**PDF/image → OpenCV preprocess → CubiCasa5K floortrans → OCR → topology → printed-dimension scale → ezdxf**

This is a library + CLI, not a GUI. A later app can call `convert()` and read the same JSON/DXF.

CubiCasa is not a pip package. Its inference path is vendored under `vendor/cubicasa/` and patched for Python 3.10+ / PyTorch 2 / SciPy 1.11 / Shapely 2.

## Setup

```powershell
cd "C:\Users\allad\Downloads\fireshield app\pdf image to dxf"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[ocr,recognizer,dev]"
python -m floorplan2dxf download-weights
```

Weights come from the official CubiCasa checkpoint
[model_best_val_loss_var.pkl](https://drive.google.com/file/d/1gRB7ez1e4H7a9Y09lLqRuna0luZO5VRK/view)
and are stored in `weights/` (gitignored).

## Convert a scan

```powershell
python -m floorplan2dxf demo --out-dir out
python -m floorplan2dxf convert samples\synthetic_plan.png --out out\plan.dxf
python -m floorplan2dxf convert "samples\hard example.png" --out out\hard_example.dxf --overall 40ft,30ft
python -m floorplan2dxf convert scan.pdf --page 0 --dpi 200 --overall 18m,12m --out out\plan.dxf
python -m floorplan2dxf convert samples\synthetic_plan.png --vision-first `
  --audit-json out\plan_audit.json --machine-readable
```

`--vision-first` asks Qwen to specify rooms and structural walls before OpenCV
reconstruction. A mandatory second Qwen image pass independently verifies the
traced topology, then GPT-OSS 120B turns that visual review into bounded
correction proposals. Pixel support and closed-perimeter checks decide whether
each proposal is accepted. `--no-ai-correction` disables the second pass for
local diagnostics only.

`--overall` is the printed size **on that drawing** (any units). Nothing in the engine is hardcoded to one plan. If OCR is installed, room sizes like `9'-0" x 12'-0"` are also used for scale.

Outputs:

- `out/plan.dxf` — semantic layers plus loss-preserving `A-TRACE-THIN` and `A-TRACE-THICK`
- `out/plan.json` — `WALL` / `DOOR` / `ROOM` / `TEXT` objects for the later app
- `out/plan_overlay.png` — debug overlay on the deskewed raster

If OCR reads a printed size such as `10'10"x10'0"` and can pair it with a room, the DXF is written in millimetres.

## App integration

```python
from floorplan2dxf import convert

result = convert("plan.png", out="out/plan.dxf")
payload = result.model.to_dict()
print(result.mm_per_px, result.model.rooms[0].type)
```

## Tests (no GPU, no weights)

```powershell
pytest -q
```

## License

Our code is usable as a FireShield prototype. CubiCasa **code** is MIT. The official checkpoint was trained on the CubiCasa5K dataset (CC BY-NC). Do not ship that checkpoint in a commercial product without a license or a retrained recognizer. Swap the model behind `recognize.py` without changing the JSON schema.
