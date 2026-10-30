"""Generates 10 sofa .glb models (real-world metres) + transparent PNG previews."""
import json, struct, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT_MODELS = Path(sys.argv[1]); OUT_IMAGES = Path(sys.argv[2])

def hex2rgb(h): h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))

class Mesh:
    """Collects boxes grouped by material and writes a binary glTF."""
    def __init__(self): self.boxes = []  # (cx,cy,cz,sx,sy,sz,material)
    def box(self, cx, cy, cz, sx, sy, sz, mat): self.boxes.append((cx, cy, cz, sx, sy, sz, mat))

    def save(self, path, materials):
        names = list(materials)
        bin_data = bytearray(); views = []; accs = []; prims = []
        for mi, name in enumerate(names):
            pos, nor, idx = [], [], []
            for (cx, cy, cz, sx, sy, sz, m) in self.boxes:
                if m != name: continue
                hx, hy, hz = sx / 2, sy / 2, sz / 2
                faces = [((0,0,1),[(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]),((0,0,-1),[(1,-1,-1),(-1,-1,-1),(-1,1,-1),(1,1,-1)]),
                         ((1,0,0),[(1,-1,1),(1,-1,-1),(1,1,-1),(1,1,1)]),((-1,0,0),[(-1,-1,-1),(-1,-1,1),(-1,1,1),(-1,1,-1)]),
                         ((0,1,0),[(-1,1,1),(1,1,1),(1,1,-1),(-1,1,-1)]),((0,-1,0),[(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1)])]
                for n, vs in faces:
                    b = len(pos)
                    for v in vs: pos.append((cx + v[0]*hx, cy + v[1]*hy, cz + v[2]*hz)); nor.append(n)
                    idx += [b, b+1, b+2, b, b+2, b+3]
            if not pos: continue
            def add(data, fmt, target, ctype, count, typ, mm=None):
                off = len(bin_data); bin_data.extend(data)
                while len(bin_data) % 4: bin_data.append(0)
                views.append({"buffer": 0, "byteOffset": off, "byteLength": len(data), "target": target})
                a = {"bufferView": len(views)-1, "componentType": ctype, "count": count, "type": typ}
                if mm: a["min"], a["max"] = mm
                accs.append(a); return len(accs)-1
            flat = [c for p in pos for c in p]
            pa = add(struct.pack(f"<{len(flat)}f", *flat), "f", 34962, 5126, len(pos), "VEC3",
                     ([min(p[i] for p in pos) for i in range(3)], [max(p[i] for p in pos) for i in range(3)]))
            fn = [c for n in nor for c in n]
            na = add(struct.pack(f"<{len(fn)}f", *fn), "f", 34962, 5126, len(nor), "VEC3")
            ia = add(struct.pack(f"<{len(idx)}H", *idx), "H", 34963, 5123, len(idx), "SCALAR")
            prims.append({"attributes": {"POSITION": pa, "NORMAL": na}, "indices": ia, "material": mi})
        mats = [{"name": n, "pbrMetallicRoughness": {"baseColorFactor": list(hex2rgb(c)) + [1], "metallicFactor": met, "roughnessFactor": rou}}
                for n, (c, met, rou) in materials.items()]
        gltf = {"asset": {"version": "2.0", "generator": "sofa_ar"}, "scene": 0, "scenes": [{"nodes": [0]}],
                "nodes": [{"mesh": 0}], "meshes": [{"primitives": prims}], "materials": mats,
                "buffers": [{"byteLength": len(bin_data)}], "bufferViews": views, "accessors": accs}
        js = json.dumps(gltf, separators=(",", ":")).encode()
        while len(js) % 4: js += b" "
        total = 12 + 8 + len(js) + 8 + len(bin_data)
        Path(path).write_bytes(struct.pack("<III", 0x46546C67, 2, total) + struct.pack("<II", len(js), 0x4E4F534A) + js +
                               struct.pack("<II", len(bin_data), 0x004E4942) + bytes(bin_data))

# ---- sofa builder: width/depth/height in metres -------------------------------------------
def build(spec):
    m = Mesh(); W, D = spec["w"], spec["d"]; seats = spec["seats"]
    leg_h = spec.get("leg", 0.12); base_h = 0.20; arm_w = spec.get("arm", 0.14); back_t = spec.get("back", 0.20)
    back_h = spec.get("back_h", 0.45); arm_h = spec.get("arm_h", 0.22)
    # legs
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.box(sx*(W/2-0.08), leg_h/2, sz*(D/2-0.08), 0.05, leg_h, 0.05, "leg")
    m.box(0, leg_h + base_h/2, 0, W, base_h, D, "frame")
    top = leg_h + base_h
    inner = W - 2*arm_w
    cw = inner / seats
    for i in range(seats):                                   # seat cushions
        cx = -inner/2 + cw*(i+0.5)
        m.box(cx, top + 0.09, (back_t)/2, cw-0.02, 0.18, D-back_t-0.02, "fabric")
        m.box(cx, top + 0.18 + back_h/2, -D/2 + back_t/2 + 0.05, cw-0.02, back_h, back_t-0.02, "fabric")  # back cushion
    m.box(0, top + back_h/2 + 0.09, -D/2 + 0.04, W-0.02, back_h+0.18, 0.08, "frame")                        # back panel
    for sx in (-1, 1):                                        # arms
        m.box(sx*(W/2-arm_w/2), top + arm_h/2 + 0.09, 0, arm_w, arm_h+0.18, D, "fabric")
    if spec.get("l_shape"):                                   # chaise extension on the right
        L = spec["l_shape"]
        m.box(W/2 + 0.45, leg_h + base_h/2, D/2 - L/2 + 0.0, 0.9, base_h, L, "frame")
        m.box(W/2 + 0.45, top + 0.09, D/2 - L/2 + 0.0, 0.88, 0.18, L-0.02, "fabric")
        m.box(W/2 + 0.45, top + 0.2, -D/2 + back_t/2 + 0.0, 0.88, 0.34, 0.02, "frame") if False else None
        for sz in (-1, 1): m.box(W/2+0.85, leg_h/2, sz*(L/2-0.08)+D/2-L/2, 0.05, leg_h, 0.05, "leg")
    if spec.get("pillows"):
        for k, px in enumerate(spec["pillows"]):
            m.box(px, top + 0.30, -D/2 + back_t + 0.12, 0.38, 0.38, 0.10, "pillow")
    if spec.get("ottoman"):
        m.box(0, 0.18, D/2 + 0.55, 0.9, 0.36, 0.55, "fabric")
    return m

SOFAS = [
 dict(id="sofa_01", name="Nordic Grey 3-Seater", w=2.10, d=0.92, seats=3, fabric="#8A8F98", frame="#6B7078", leg="#C9A66B", pillow="#E3B04B", pillows=[-0.65, 0.65], price="₹42,999", style="Scandinavian"),
 dict(id="sofa_02", name="Velvet Emerald 2-Seater", w=1.65, d=0.88, seats=2, fabric="#1F6B54", frame="#17513F", leg="#B08D3A", pillow="#E8D9A8", pillows=[-0.45], price="₹36,499", style="Modern Velvet", rough=0.9),
 dict(id="sofa_03", name="Classic Tan Leather 3-Seater", w=2.20, d=0.95, seats=3, fabric="#A0622D", frame="#7C4A20", leg="#2B2B2B", pillow="#6E3F1B", price="₹78,500", style="Leather", metal=0.1, rough=0.45, arm=0.18, back_h=0.5),
 dict(id="sofa_04", name="Navy Blue Loveseat", w=1.50, d=0.85, seats=2, fabric="#27406B", frame="#1B2D4D", leg="#D0D0D0", pillow="#F2F2F2", pillows=[0.4], price="₹29,999", style="Compact"),
 dict(id="sofa_05", name="Sand Beige Sectional (L-Shape)", w=2.30, d=0.95, seats=3, fabric="#CDBBA0", frame="#A8977D", leg="#4A3B2A", pillow="#8C6F4B", l_shape=1.55, pillows=[-0.7], price="₹64,999", style="Sectional"),
 dict(id="sofa_06", name="Blush Pink Accent Sofa", w=1.80, d=0.85, seats=2, fabric="#D9A3A8", frame="#B8828A", leg="#B08D3A", pillow="#FFFFFF", pillows=[-0.5, 0.5], price="₹33,250", style="Boho", rough=0.85),
 dict(id="sofa_07", name="Charcoal Modern 4-Seater", w=2.80, d=1.00, seats=4, fabric="#3A3D42", frame="#26282B", leg="#111111", pillow="#9AA0A8", pillows=[-1.0, 1.0], price="₹58,750", style="Contemporary", arm=0.12),
 dict(id="sofa_08", name="Mustard Retro 2-Seater", w=1.70, d=0.82, seats=2, fabric="#D4A017", frame="#A87F0F", leg="#5C3A21", pillow="#5C3A21", pillows=[0.45], price="₹31,400", style="Mid-century", leg_h=0.2, leg_=0.2),
 dict(id="sofa_09", name="Ivory Cloud Lounge Sofa", w=2.40, d=1.05, seats=3, fabric="#EDE8DF", frame="#D6CEBF", leg="#9A9A9A", pillow="#C8BFA9", pillows=[-0.8, 0.8], price="₹69,900", style="Lounge", arm=0.2, back_h=0.5, rough=0.95),
 dict(id="sofa_10", name="Teal Sofa with Ottoman", w=2.00, d=0.90, seats=3, fabric="#2E7F86", frame="#1F5A60", leg="#C9A66B", pillow="#F1E5C8", pillows=[-0.6, 0.6], ottoman=True, price="₹47,800", style="Modern"),
]

def preview(spec, path):
    """Front-view transparent PNG with soft shadow, so it works as a 2D overlay too."""
    W_, H_ = 900, 520; im = Image.new("RGBA", (W_, H_), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    scale = 330 * (spec["w"] / 2.1) ** 0.9; sw = int(scale * 1.9 * (spec["w"] / spec["w"])); sw = int(spec["w"] * 330)
    x0 = (W_ - sw) // 2; base_y = 430; fab, frm, leg = spec["fabric"], spec["frame"], spec["leg"]
    sh = Image.new("RGBA", (W_, H_), (0, 0, 0, 0)); ImageDraw.Draw(sh).ellipse([x0-10, base_y-8, x0+sw+10, base_y+30], fill=(0, 0, 0, 90))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10)))
    arm_w = 52; back_top = base_y - 270
    d.rounded_rectangle([x0+arm_w-6, back_top, x0+sw-arm_w+6, base_y-70], 28, fill=frm)             # back
    seats = spec["seats"]; cw = (sw - 2*arm_w) / seats
    for i in range(seats):
        cx = x0 + arm_w + cw*i
        d.rounded_rectangle([cx+3, back_top+14, cx+cw-3, base_y-95], 24, fill=fab, outline=frm, width=2)  # back cushion
        d.rounded_rectangle([cx+2, base_y-100, cx+cw-2, base_y-48], 18, fill=fab, outline=frm, width=2)   # seat cushion
    for sx in (x0, x0+sw-arm_w):
        d.rounded_rectangle([sx, base_y-175, sx+arm_w, base_y-30], 22, fill=fab, outline=frm, width=2)    # arms
    d.rounded_rectangle([x0, base_y-48, x0+sw, base_y-22], 8, fill=frm)                              # base
    for lx in (x0+26, x0+sw-40): d.rectangle([lx, base_y-22, lx+14, base_y], fill=leg)               # legs
    for k, px in enumerate(spec.get("pillows", [])):
        cxp = x0 + sw/2 + px*330; d.rounded_rectangle([cxp-42, base_y-190, cxp+42, base_y-105], 16, fill=spec["pillow"], outline=frm, width=2)
    im.save(path)

for s in SOFAS:
    mats = {"fabric": (s["fabric"], s.get("metal", 0.0), s.get("rough", 0.8)), "frame": (s["frame"], 0.0, 0.85),
            "leg": (s["leg"], 0.4, 0.4), "pillow": (s["pillow"], 0.0, 0.9)}
    s2 = dict(s); s2["leg"] = s.get("leg_h", 0.12)
    mesh = build(s2); mesh.save(OUT_MODELS / f"{s['id']}.glb", mats)
    preview(s, OUT_IMAGES / f"{s['id']}.png")
print("ok")
