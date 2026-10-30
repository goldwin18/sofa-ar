#!/usr/bin/env python3
"""Builds assets/models/sofa_XX.glb from assets/images/sofa_XX.png.

Each model is a real-size, upright, 4 cm thick cut-out of the photo (transparent parts are cut away),
the same thing the in-app "Quick 3D cut-out" makes. For a full 3D shape, convert the photo
with the AI option (Meshy) and drop the resulting .glb into assets/models/ under the same name.

Usage:  python3 tool/make_sample_glbs.py
Keep the WIDTHS below in sync with lib/data/sample_sofas.dart.
"""
import json
import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets/images"
MODELS = ROOT / "assets/models"

# real-world width of each sofa in metres
WIDTHS = {
    "sofa_01": 1.70, "sofa_02": 2.60, "sofa_03": 2.10, "sofa_04": 1.60, "sofa_05": 1.90,
    "sofa_06": 2.30, "sofa_07": 2.00, "sofa_08": 1.85, "sofa_09": 2.30, "sofa_10": 1.70,
}


def pad(data: bytes, fill: bytes) -> bytes:
    return data + fill * ((4 - len(data) % 4) % 4)


DEPTH = 0.04  # metres. A little thickness keeps AR apps from choking on a perfectly flat model.


def quad_glb(png: bytes, width: float, height: float) -> bytes:
    h, d = width / 2, DEPTH / 2
    front = [-h, 0, d, h, 0, d, h, height, d, -h, height, d]
    back = [-h, 0, -d, h, 0, -d, h, height, -d, -h, height, -d]
    pos = struct.pack("<24f", *front, *back)
    nor = struct.pack("<24f", *([0, 0, 1] * 4), *([0, 0, -1] * 4))
    uv = struct.pack("<16f", *([0, 1, 1, 1, 1, 0, 0, 0] * 2))
    idx = struct.pack("<12H", 0, 1, 2, 0, 2, 3, 4, 6, 5, 4, 7, 6)

    binary, views = b"", []
    for data, target in ((pos, 34962), (nor, 34962), (uv, 34962), (idx, 34963), (png, None)):
        view = {"buffer": 0, "byteOffset": len(binary), "byteLength": len(data)}
        if target:
            view["target"] = target
        views.append(view)
        binary = pad(binary + data, b"\0")

    doc = {
        "asset": {"version": "2.0", "generator": "sofa_ar"},
        "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": "SofaCutout"}],
        "meshes": [{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2},
                                    "indices": 3, "material": 0}]}],
        "materials": [{"pbrMetallicRoughness": {"baseColorTexture": {"index": 0},
                                                "metallicFactor": 0, "roughnessFactor": 1},
                       "alphaMode": "MASK", "alphaCutoff": 0.5, "doubleSided": True}],
        "textures": [{"source": 0, "sampler": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 33071, "wrapT": 33071}],
        "images": [{"bufferView": 4, "mimeType": "image/png"}],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": 8, "type": "VEC3",
             "min": [-h, 0, -d], "max": [h, height, d]},
            {"bufferView": 1, "componentType": 5126, "count": 8, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": 8, "type": "VEC2"},
            {"bufferView": 3, "componentType": 5123, "count": 12, "type": "SCALAR"},
        ],
        "bufferViews": views, "buffers": [{"byteLength": len(binary)}],
    }
    js = pad(json.dumps(doc, separators=(",", ":")).encode(), b" ")
    total = 12 + 8 + len(js) + 8 + len(binary)
    return (struct.pack("<III", 0x46546C67, 2, total) + struct.pack("<II", len(js), 0x4E4F534A) + js
            + struct.pack("<II", len(binary), 0x004E4942) + binary)


for sofa_id, width in WIDTHS.items():
    image_path = IMAGES / f"{sofa_id}.png"
    w, h = Image.open(image_path).size
    glb = quad_glb(image_path.read_bytes(), width, width * h / w)
    (MODELS / f"{sofa_id}.glb").write_bytes(glb)
    print(f"{sofa_id}.glb  {width:.2f} m wide  {len(glb) // 1024} KB")
