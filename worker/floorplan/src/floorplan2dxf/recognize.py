from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

import numpy as np

from .preprocess import Preprocessed, map_xy_to_display

N_CLASSES = 44
SPLIT = [21, 12, 11]
WEIGHTS_NAME = "model_best_val_loss_var.pkl"
DRIVE_ID = "1gRB7ez1e4H7a9Y09lLqRuna0luZO5VRK"


def project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def default_weights_path() -> Path:
    return project_root() / "weights" / WEIGHTS_NAME


def vendor_root() -> Path:
    return project_root() / "vendor" / "cubicasa"


def _ensure_vendor_on_path() -> None:
    root = str(vendor_root())
    if root not in sys.path:
        sys.path.insert(0, root)


@dataclass
class Recognition:
    polygons: Any
    types: list[dict[str, Any]]
    room_polygons: list[Any]
    room_types: list[dict[str, Any]]
    heatmaps: Any
    rooms: Any
    icons: Any


class MissingWeights(FileNotFoundError):
    pass


def download_weights(dest: Optional[Path] = None) -> Path:
    dest = dest or default_weights_path()
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.stat().st_size > 1_000_000:
        return dest
    try:
        import gdown
    except ImportError as exc:
        raise RuntimeError("gdown is required to download weights: pip install gdown") from exc
    url = f"https://drive.google.com/uc?id={DRIVE_ID}"
    gdown.download(url, str(dest), quiet=False)
    if not dest.exists() or dest.stat().st_size < 1_000_000:
        raise RuntimeError(
            "Weight download failed. Place the CubiCasa file manually at "
            f"{dest} from https://drive.google.com/file/d/{DRIVE_ID}/view"
        )
    return dest


def load_model(weights: Optional[Path] = None, device: Optional[str] = None):
    import torch

    _ensure_vendor_on_path()
    from floortrans.models import get_model

    weights = Path(weights) if weights else default_weights_path()
    if not weights.exists():
        raise MissingWeights(
            f"CubiCasa weights not found at {weights}.\n"
            "Download them with: python -m floorplan2dxf download-weights"
        )
    if device is None:
        device = "cuda" if torch.cuda.is_available() else "cpu"

    model = get_model("hg_furukawa_original", 51)
    model.conv4_ = torch.nn.Conv2d(256, N_CLASSES, bias=True, kernel_size=1)
    model.upsample = torch.nn.ConvTranspose2d(N_CLASSES, N_CLASSES, kernel_size=4, stride=4)
    checkpoint = torch.load(weights, map_location=device, weights_only=False)
    state = checkpoint["model_state"] if isinstance(checkpoint, dict) and "model_state" in checkpoint else checkpoint
    model.load_state_dict(state)
    model.to(device)
    model.eval()
    return model, device


class RotateNTurns:
    """Official CubiCasa TTA: rotate tensor and remap junction channels."""

    def rot_tensor(self, t, n):
        if n == 1:
            return t.flip(2).transpose(3, 2)
        if n == -1:
            return t.transpose(3, 2).flip(2)
        if n == 2:
            return t.flip(2).flip(3)
        return t

    def rot_points(self, t, n):
        t_sorted = t.clone().detach()
        if n == 1:
            t_sorted[:, 1] = t[:, 0]
            t_sorted[:, 2] = t[:, 1]
            t_sorted[:, 3] = t[:, 2]
            t_sorted[:, 0] = t[:, 3]
            t_sorted[:, 5] = t[:, 4]
            t_sorted[:, 6] = t[:, 5]
            t_sorted[:, 7] = t[:, 6]
            t_sorted[:, 4] = t[:, 7]
            t_sorted[:, 9] = t[:, 8]
            t_sorted[:, 10] = t[:, 9]
            t_sorted[:, 11] = t[:, 10]
            t_sorted[:, 8] = t[:, 11]
            t_sorted[:, 15] = t[:, 13]
            t_sorted[:, 16] = t[:, 14]
            t_sorted[:, 14] = t[:, 15]
            t_sorted[:, 13] = t[:, 16]
            t_sorted[:, 18] = t[:, 17]
            t_sorted[:, 20] = t[:, 18]
            t_sorted[:, 17] = t[:, 19]
            t_sorted[:, 19] = t[:, 20]
        elif n == -1:
            t_sorted[:, 3] = t[:, 0]
            t_sorted[:, 0] = t[:, 1]
            t_sorted[:, 1] = t[:, 2]
            t_sorted[:, 2] = t[:, 3]
            t_sorted[:, 7] = t[:, 4]
            t_sorted[:, 4] = t[:, 5]
            t_sorted[:, 5] = t[:, 6]
            t_sorted[:, 6] = t[:, 7]
            t_sorted[:, 11] = t[:, 8]
            t_sorted[:, 8] = t[:, 9]
            t_sorted[:, 9] = t[:, 10]
            t_sorted[:, 10] = t[:, 11]
            t_sorted[:, 16] = t[:, 13]
            t_sorted[:, 15] = t[:, 14]
            t_sorted[:, 13] = t[:, 15]
            t_sorted[:, 14] = t[:, 16]
            t_sorted[:, 19] = t[:, 17]
            t_sorted[:, 17] = t[:, 18]
            t_sorted[:, 20] = t[:, 19]
            t_sorted[:, 18] = t[:, 20]
        elif n == 2:
            t_sorted[:, 2] = t[:, 0]
            t_sorted[:, 3] = t[:, 1]
            t_sorted[:, 0] = t[:, 2]
            t_sorted[:, 1] = t[:, 3]
            t_sorted[:, 6] = t[:, 4]
            t_sorted[:, 7] = t[:, 5]
            t_sorted[:, 4] = t[:, 6]
            t_sorted[:, 5] = t[:, 7]
            t_sorted[:, 10] = t[:, 8]
            t_sorted[:, 11] = t[:, 9]
            t_sorted[:, 8] = t[:, 10]
            t_sorted[:, 9] = t[:, 11]
            t_sorted[:, 14] = t[:, 13]
            t_sorted[:, 13] = t[:, 14]
            t_sorted[:, 16] = t[:, 15]
            t_sorted[:, 15] = t[:, 16]
            t_sorted[:, 20] = t[:, 17]
            t_sorted[:, 19] = t[:, 18]
            t_sorted[:, 18] = t[:, 19]
            t_sorted[:, 17] = t[:, 20]
        return t_sorted


def _predict(model, tensor, tta: bool):
    import torch

    if not tta:
        return model(tensor)
    rot = RotateNTurns()
    acc = None
    count = 0
    for forward, back in ((0, 0), (1, -1), (2, 2), (-1, 1)):
        rotated = rot.rot_tensor(tensor, forward)
        pred = model(rotated)
        pred = rot.rot_tensor(pred, back)
        heat = rot.rot_points(pred[:, :21], back)
        pred = torch.cat([heat, pred[:, 21:]], dim=1)
        acc = pred if acc is None else acc + pred
        count += 1
    return acc / count


def recognize(prep: Preprocessed, model, device: str, tta: bool = False, threshold: float = 0.2) -> Recognition:
    import torch

    _ensure_vendor_on_path()
    from floortrans.post_prosessing import get_polygons, split_prediction

    rgb = prep.model_rgb.astype(np.float32) / 255.0
    tensor = torch.from_numpy(rgb.transpose(2, 0, 1)).unsqueeze(0).to(device)
    with torch.no_grad():
        pred = _predict(model, tensor, tta=tta)
        if pred.dim() == 3:
            pred = pred.unsqueeze(0)
        heatmaps, rooms, icons = split_prediction(pred.cpu(), rgb.shape[:2], SPLIT)
    polygons, types, room_polygons, room_types = get_polygons(
        (heatmaps, rooms, icons), threshold, [1, 2]
    )
    return Recognition(
        polygons=polygons,
        types=types,
        room_polygons=room_polygons,
        room_types=room_types,
        heatmaps=heatmaps,
        rooms=rooms,
        icons=icons,
    )


def remap_recognition(recog: Recognition, prep: Preprocessed) -> Recognition:
    def remap_quads(arr: np.ndarray) -> np.ndarray:
        if arr is None or len(arr) == 0:
            return arr
        out = np.array(arr, dtype=float)
        for i in range(out.shape[0]):
            for j in range(out.shape[1]):
                out[i, j, 0], out[i, j, 1] = map_xy_to_display(out[i, j, 0], out[i, j, 1], prep)
        return out

    polygons = remap_quads(recog.polygons)
    rooms = []
    for geom in recog.room_polygons:
        rooms.append(_remap_shapely(geom, prep))
    return Recognition(
        polygons=polygons,
        types=recog.types,
        room_polygons=rooms,
        room_types=recog.room_types,
        heatmaps=recog.heatmaps,
        rooms=recog.rooms,
        icons=recog.icons,
    )


def _remap_shapely(geom, prep: Preprocessed):
    try:
        from shapely.ops import transform
    except ImportError:
        return geom

    def _fn(xs, ys, zs=None):
        pts = [map_xy_to_display(x, y, prep) for x, y in zip(xs, ys)]
        xs2 = [p[0] for p in pts]
        ys2 = [p[1] for p in pts]
        if zs is None:
            return xs2, ys2
        return xs2, ys2, zs

    try:
        return transform(_fn, geom)
    except Exception:
        return geom
