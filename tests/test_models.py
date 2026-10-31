"""Checks every sample sofa model (.glb) and that the Dart code, the model builder
and the files on disk all agree with each other."""
import ast
import io
import json
import math
import re
import struct

import pytest
from PIL import Image

from conftest import IMAGES, MODELS, ROOT

DART = (ROOT / "lib/data/sample_sofas.dart").read_text()
TOOL = (ROOT / "tool/make_sample_glbs.py").read_text()


def dart_sofas():
    """[(id, width)] from the sample list in sample_sofas.dart."""
    return [(m[0], float(m[1])) for m in
            re.findall(r"_sample\('(sofa_\d+)',[^\n]*?,\s*([\d.]+)\)", DART)]


def revision():
    return int(re.search(r"modelRevision\s*=\s*(\d+)", DART).group(1))


def read_glb(path):
    data = path.read_bytes()
    magic, version, total = struct.unpack("<III", data[:12])
    assert (magic, version) == (0x46546C67, 2), "not a glTF 2.0 binary"
    assert total == len(data), "header length does not match the file"
    json_len, json_type = struct.unpack("<II", data[12:20])
    assert json_type == 0x4E4F534A and json_len % 4 == 0
    doc = json.loads(data[20:20 + json_len])
    offset = 20 + json_len
    bin_len, bin_type = struct.unpack("<II", data[offset:offset + 8])
    assert bin_type == 0x004E4942 and bin_len % 4 == 0
    assert offset + 8 + bin_len == len(data)
    return doc, data[offset + 8: offset + 8 + bin_len]


def accessor(doc, binary, index):
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    fmt = {5126: "f", 5123: "H"}[acc["componentType"]]
    width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[acc["type"]]
    start = view["byteOffset"] + acc.get("byteOffset", 0)
    values = struct.unpack(f"<{acc['count'] * width}{fmt}", binary[start:start + acc["count"] * width * struct.calcsize(fmt)])
    return [values[i:i + width] for i in range(0, len(values), width)], acc


SOFAS = dart_sofas()
IDS = [s for s, _ in SOFAS]


def test_ten_sofas_listed():
    assert len(SOFAS) == 10 and len(set(IDS)) == 10


def test_dart_and_tool_agree():
    tool_widths = ast.literal_eval(re.search(r"WIDTHS\s*=\s*(\{.*?\})", TOOL, re.S).group(1))
    assert tool_widths == dict(SOFAS), "widths differ between sample_sofas.dart and make_sample_glbs.py"
    assert int(re.search(r"^REVISION\s*=\s*(\d+)", TOOL, re.M).group(1)) == revision()


def test_no_stray_or_missing_files():
    expected = {f"{s}_r{revision()}.glb" for s in IDS}
    assert {p.name for p in MODELS.glob("*.glb")} == expected
    assert {p.name for p in IMAGES.glob("*.png")} == {f"{s}.png" for s in IDS}


@pytest.mark.parametrize("sofa_id,width", SOFAS)
def test_model_is_valid_and_true_size(sofa_id, width):
    doc, binary = read_glb(MODELS / f"{sofa_id}_r{revision()}.glb")
    prim = doc["meshes"][0]["primitives"][0]

    # geometry: declared bounds match the real vertices
    pos, pos_acc = accessor(doc, binary, prim["attributes"]["POSITION"])
    for axis in range(3):
        values = [p[axis] for p in pos]
        assert math.isclose(min(values), pos_acc["min"][axis], abs_tol=1e-6)
        assert math.isclose(max(values), pos_acc["max"][axis], abs_tol=1e-6)

    # real-world size, standing on the floor
    xs, ys, zs = ([p[a] for p in pos] for a in range(3))
    assert math.isclose(max(xs) - min(xs), width, abs_tol=1e-4), "wrong width"
    assert math.isclose(min(ys), 0, abs_tol=1e-6), "sofa should stand on the floor (y=0)"
    assert 0.5 <= max(ys) <= 1.6, f"unrealistic height {max(ys):.2f} m"
    assert max(zs) - min(zs) > 0.01, "model has no thickness (AR apps can reject flat models)"

    # indices, normals, UVs
    idx = [i[0] for i in accessor(doc, binary, prim["indices"])[0]]
    assert len(idx) % 3 == 0 and max(idx) < len(pos)
    normals, _ = accessor(doc, binary, prim["attributes"]["NORMAL"])
    assert all(math.isclose(math.dist((0, 0, 0), n), 1, abs_tol=1e-5) for n in normals)
    uvs, _ = accessor(doc, binary, prim["attributes"]["TEXCOORD_0"])
    assert all(0 <= c <= 1 for uv in uvs for c in uv)

    # every triangle faces the way its normal says (otherwise it is invisible from the front)
    for t in range(0, len(idx), 3):
        a, b, c = (pos[i] for i in idx[t:t + 3])
        u = [b[k] - a[k] for k in range(3)]
        v = [c[k] - a[k] for k in range(3)]
        cross_z = u[0] * v[1] - u[1] * v[0]
        assert cross_z * normals[idx[t]][2] > 0, "triangle winding does not match its normal"

    # texture: an RGBA PNG with both see-through and solid pixels (the sofa cut-out)
    image = doc["images"][0]
    view = doc["bufferViews"][image["bufferView"]]
    png = binary[view["byteOffset"]: view["byteOffset"] + view["byteLength"]]
    assert png[:8] == b"\x89PNG\r\n\x1a\n" and image["mimeType"] == "image/png"
    pic = Image.open(io.BytesIO(png))
    assert pic.mode == "RGBA"
    alpha = pic.getchannel("A")
    low, high = alpha.getextrema()
    assert low == 0 and high == 255, "cut-out should have transparent and solid pixels"
    # the picture proportions give the model's height
    assert math.isclose(max(ys), width * pic.height / pic.width, rel_tol=1e-3)
    assert doc["materials"][0]["alphaMode"] == "MASK"


def test_picture_matches_the_one_in_the_app():
    for sofa_id in IDS:
        doc, binary = read_glb(MODELS / f"{sofa_id}_r{revision()}.glb")
        view = doc["bufferViews"][doc["images"][0]["bufferView"]]
        assert binary[view["byteOffset"]: view["byteOffset"] + view["byteLength"]] == (IMAGES / f"{sofa_id}.png").read_bytes()


def test_app_does_not_start_google_ar_viewer_directly():
    """That direct start made the Google app crash ("Google keeps stopping") on a Redmi phone."""
    for path in (ROOT / "lib").rglob("*.dart"):
        assert "arvr.google.com" not in path.read_text(), f"{path.name} starts Scene Viewer directly"


def test_app_points_at_the_hosted_page():
    constants = (ROOT / "lib/core/constants/app_constants.dart").read_text()
    url = re.search(r"arPageUrl\s*=\s*'([^']+)'", constants).group(1)
    assert url == "https://goldwin18.github.io/sofa-ar/ar.html"
    assert (ROOT / "ar.html").exists() and (ROOT / ".nojekyll").exists()
