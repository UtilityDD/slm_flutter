"""
SmartLineMan — 3D SDF Raymarching + PBR Texture + Prop-Composite World Generator
================================================================================
Produces:
1. Reusable Wavefront `.obj` + `.mtl` 3D models in `tool/world3d_production/meshes/`
2. High-resolution 3D raymarched + textured + prop-composited sprites in
   `assets/duty_slip/world3d/`
3. Complete `ASSET_REGISTER.json` and `ASSET_REGISTER.md`
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy.ndimage import gaussian_filter

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "duty_slip" / "world3d"
SCENE_DIR = ROOT / "assets" / "zero_loss" / "scene"
FONT_BOLD = ROOT / "assets" / "fonts" / "NotoSansBengali-Bold.ttf"
MESH_DIR = Path(__file__).resolve().parent / "meshes"


# ============================================================================
# 3D Isometric Raymarching Engine (SDF + Soft Shadows + Ambient Occlusion + PBR)
# ============================================================================
def setup_ortho_rays(w: int, h: int, scale: float = 3.6, pitch_deg: float = 30.0, yaw_deg: float = 38.0):
    """Returns orthographic ray origins `ro` (H,W,3) and constant ray direction `rd` (3,)."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    u = (xx / w - 0.5) * scale * (w / h)
    v = (0.5 - yy / h) * scale

    pitch = math.radians(pitch_deg)
    yaw = math.radians(yaw_deg)
    cp, sp = math.cos(pitch), math.sin(pitch)
    cy, sy = math.cos(yaw), math.sin(yaw)

    # Camera basis vectors (X right, Y up on screen, Z towards viewer)
    cam_right = np.array([cy, 0.0, -sy], dtype=np.float32)
    cam_up = np.array([sy * sp, cp, cy * sp], dtype=np.float32)
    cam_fwd = np.array([sy * cp, -sp, cy * cp], dtype=np.float32)  # points from target to camera

    ro = (
        u[..., None] * cam_right[None, None, :]
        + v[..., None] * cam_up[None, None, :]
        + 8.0 * cam_fwd[None, None, :]
    )
    rd = -cam_fwd
    return ro, rd


def sd_round_box(p: np.ndarray, c: tuple[float, float, float], b: tuple[float, float, float], r: float = 0.04) -> np.ndarray:
    q = np.abs(p - np.array(c, dtype=np.float32)) - np.array(b, dtype=np.float32)
    return np.linalg.norm(np.maximum(q, 0.0), axis=-1) + np.minimum(np.amax(q, axis=-1), 0.0) - r


def sd_cylinder_y(p: np.ndarray, c: tuple[float, float, float], rad: float, half_h: float) -> np.ndarray:
    q = p - np.array(c, dtype=np.float32)
    d_xz = np.hypot(q[..., 0], q[..., 2]) - rad
    d_y = np.abs(q[..., 1]) - half_h
    return np.minimum(np.maximum(d_xz, d_y), 0.0) + np.hypot(np.maximum(d_xz, 0.0), np.maximum(d_y, 0.0))


def sd_cylinder_x(p: np.ndarray, c: tuple[float, float, float], rad: float, half_len: float) -> np.ndarray:
    q = p - np.array(c, dtype=np.float32)
    d_yz = np.hypot(q[..., 1], q[..., 2]) - rad
    d_x = np.abs(q[..., 0]) - half_len
    return np.minimum(np.maximum(d_yz, d_x), 0.0) + np.hypot(np.maximum(d_yz, 0.0), np.maximum(d_x, 0.0))


def sd_sphere(p: np.ndarray, c: tuple[float, float, float], rad: float) -> np.ndarray:
    return np.linalg.norm(p - np.array(c, dtype=np.float32), axis=-1) - rad


def sd_torus_y(p: np.ndarray, c: tuple[float, float, float], r_major: float, r_minor: float) -> np.ndarray:
    q = p - np.array(c, dtype=np.float32)
    q_xz = np.hypot(q[..., 0], q[..., 2]) - r_major
    return np.hypot(q_xz, q[..., 1]) - r_minor


def render_sdf_scene(
    w: int,
    h: int,
    scene_fn,
    scale: float = 3.6,
    pitch_deg: float = 28.0,
    yaw_deg: float = 36.0,
    steps: int = 44,
) -> Image.Image:
    """Raymarches a 3D SDF scene with multi-material PBR, AO, and soft sun shadows."""
    ro, rd = setup_ortho_rays(w, h, scale=scale, pitch_deg=pitch_deg, yaw_deg=yaw_deg)
    t = np.full((h, w), 4.2, dtype=np.float32)
    hit = np.zeros((h, w), dtype=bool)
    mat_id = np.zeros((h, w), dtype=np.int32)

    for _ in range(steps):
        pts = ro + t[..., None] * rd[None, None, :]
        d, m = scene_fn(pts)
        near = d < 0.004
        hit |= near
        mat_id = np.where(near, m, mat_id)
        t = np.where(hit, t, t + d * 0.92)
        if np.all(hit | (t > 13.0)):
            break

    hit &= t <= 13.0
    pts = ro + t[..., None] * rd[None, None, :]

    # Central-difference 3D surface normals
    eps = 0.006
    dx, _ = scene_fn(pts + np.array([eps, 0, 0], dtype=np.float32))
    dx2, _ = scene_fn(pts - np.array([eps, 0, 0], dtype=np.float32))
    dy, _ = scene_fn(pts + np.array([0, eps, 0], dtype=np.float32))
    dy2, _ = scene_fn(pts - np.array([0, eps, 0], dtype=np.float32))
    dz, _ = scene_fn(pts + np.array([0, 0, eps], dtype=np.float32))
    dz2, _ = scene_fn(pts - np.array([0, 0, eps], dtype=np.float32))
    n = np.stack([dx - dx2, dy - dy2, dz - dz2], axis=-1)

    # Smooth analytical SDF normals (no sinusoidal grid artifacts)
    n_len = np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-6)
    n /= n_len

    # 3-step SDF Ambient Occlusion
    ao = np.ones((h, w), dtype=np.float32)
    for step_d, weight in ((0.06, 2.2), (0.14, 1.4), (0.26, 0.8)):
        d_ao, _ = scene_fn(pts + n * step_d)
        ao -= np.clip(step_d - d_ao, 0.0, step_d) * weight
    ao = np.clip(ao, 0.28, 1.0)

    # Soft directional sun shadow march
    sun_dir = np.array([-0.52, 0.68, 0.51], dtype=np.float32)
    sun_dir /= np.linalg.norm(sun_dir)
    shadow = np.ones((h, w), dtype=np.float32)
    st = np.full((h, w), 0.08, dtype=np.float32)
    for _ in range(10):
        s_pts = pts + n * 0.015 + st[..., None] * sun_dir[None, None, :]
        sd, _ = scene_fn(s_pts)
        shadow = np.minimum(shadow, np.clip(6.0 * sd / np.maximum(st, 0.05), 0.22, 1.0))
        st += np.clip(sd, 0.04, 0.25)

    # Material lookup table: (R, G, B, metallic, roughness)
    # 1: Plinth stone, 2: Galv steel, 3: Transformer blue-slate, 4: Porcelain brown,
    # 5: Antique gold, 6: Deep emerald, 7: Teak wood, 8: Safety yellow, 9: Danger red, 10: Warm lamp
    mats = {
        1: ((0.50, 0.53, 0.56), 0.08, 0.68),
        2: ((0.76, 0.81, 0.86), 0.78, 0.26),
        3: ((0.30, 0.41, 0.52), 0.62, 0.30),
        4: ((0.54, 0.23, 0.13), 0.14, 0.16),
        5: ((0.88, 0.71, 0.35), 0.88, 0.20),
        6: ((0.04, 0.52, 0.36), 0.25, 0.28),
        7: ((0.48, 0.29, 0.14), 0.08, 0.52),
        8: ((0.98, 0.78, 0.15), 0.18, 0.24),
        9: ((0.86, 0.16, 0.16), 0.22, 0.32),
        10: ((1.00, 0.92, 0.58), 0.05, 0.10),
    }

    base_col = np.zeros((h, w, 3), dtype=np.float32)
    met = np.zeros((h, w), dtype=np.float32)
    rough = np.full((h, w), 0.4, dtype=np.float32)

    wood_grain = 0.96 + 0.04 * np.sin(pts[..., 1] * 14.0)

    for mid, (rgb, m_val, r_val) in mats.items():
        mask = mat_id == mid
        if not np.any(mask):
            continue
        c_arr = np.array(rgb, dtype=np.float32)[None, None, :]
        if mid == 7:
            c_arr = c_arr * wood_grain[..., None]
        base_col = np.where(mask[..., None], c_arr, base_col)
        met = np.where(mask, m_val, met)
        rough = np.where(mask, r_val, rough)

    view_dir = -rd
    half_v = sun_dir + view_dir
    half_v /= np.linalg.norm(half_v)

    ndotl = np.clip(np.sum(n * sun_dir[None, None, :], axis=-1), 0.0, 1.0) * shadow
    ndotv = np.clip(np.sum(n * view_dir[None, None, :], axis=-1), 0.0, 1.0)
    ndoth = np.clip(np.sum(n * half_v[None, None, :], axis=-1), 0.0, 1.0)

    sky_f = 0.5 * (n[..., 1] + 1.0)
    amb = (
        np.array([0.20, 0.30, 0.44], dtype=np.float32)[None, None, :] * sky_f[..., None]
        + np.array([0.14, 0.18, 0.10], dtype=np.float32)[None, None, :] * (1.0 - sky_f[..., None])
    )
    sun_col = np.array([1.12, 1.00, 0.86], dtype=np.float32)[None, None, :]

    diff = base_col * (1.0 - 0.55 * met[..., None]) * (amb * ao[..., None] + 0.95 * ndotl[..., None] * sun_col)
    shininess = np.clip(2.0 / np.maximum(rough * rough, 0.02) - 2.0, 6.0, 120.0)
    spec_p = np.power(ndoth, shininess) * (0.22 + 0.85 * met) * shadow
    spec_col = base_col * met[..., None] + (1.0 - met[..., None]) * np.array([1.0, 0.96, 0.88], dtype=np.float32)[None, None, :]
    spec = spec_col * spec_p[..., None]

    # Golden-hour rim light
    rim = np.power(1.0 - ndotv, 2.8) * np.clip(0.35 + 0.65 * n[..., 1], 0.0, 1.0)
    rim_rgb = np.array([0.98, 0.84, 0.52], dtype=np.float32)[None, None, :] * (0.28 * rim[..., None])

    emissive = np.where((mat_id == 10)[..., None], np.array([0.95, 0.80, 0.35], dtype=np.float32)[None, None, :], 0.0)
    rgb_out = np.clip((diff + spec + rim_rgb + emissive) * 255.0, 0, 255).astype(np.uint8)

    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    # Soft ground contact shadow under object
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    sh_d2 = ((xx - w * 0.5) / (w * 0.36)) ** 2 + ((yy - h * 0.82) / (h * 0.10)) ** 2
    sh_a = (np.exp(-sh_d2 * 2.4) * 145).astype(np.uint8)
    rgba[..., 0] = 8
    rgba[..., 1] = 16
    rgba[..., 2] = 12
    rgba[..., 3] = sh_a

    for c in range(3):
        rgba[..., c] = np.where(hit, rgb_out[..., c], rgba[..., c])
    rgba[..., 3] = np.where(hit, 255, rgba[..., 3])

    # Smooth silhouette anti-aliasing
    alpha_f = gaussian_filter(rgba[..., 3].astype(np.float32), sigma=0.65)
    rgba[..., 3] = np.clip(alpha_f, 0, 255).astype(np.uint8)
    return Image.fromarray(rgba, mode="RGBA")


def combine_sdf(d1, m1, d2, m2):
    choose = d2 < d1
    return np.where(choose, d2, d1), np.where(choose, m2, m1)


def draw_sign_badge(img: Image.Image, box: tuple[int, int, int, int], lines: list[str]):
    draw = ImageDraw.Draw(img)
    x0, y0, x1, y1 = box
    draw.rounded_rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], radius=6, fill=(219, 178, 92, 255))
    draw.rounded_rectangle([x0, y0, x1, y1], radius=5, fill=(14, 28, 38, 245))
    try:
        font = ImageFont.truetype(str(FONT_BOLD), 15)
    except Exception:
        font = ImageFont.load_default()
    cy = y0 + 4
    for ln in lines:
        bb = draw.textbbox((0, 0), ln, font=font)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
        draw.text(((x0 + x1 - tw) * 0.5, cy), ln, font=font, fill=(255, 236, 179, 255))
        cy += th + 3


# ============================================================================
# 1. 3D DTR Station (Double-Pole H-Frame 11/0.4 kV Transformer)
# ============================================================================
def build_dtr_3d(path: Path):
    def scene(p):
        # Concrete stepped plinth
        d = sd_round_box(p, (0.0, -1.18, 0.0), (1.05, 0.14, 0.58), 0.04)
        m = np.ones_like(d, dtype=np.int32)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, -1.02, 0.0), (0.88, 0.08, 0.46), 0.03), 1)

        # Twin H-frame galvanized poles
        for px in (-0.72, 0.72):
            d, m = combine_sdf(d, m, sd_cylinder_y(p, (px, 0.05, 0.0), 0.085, 1.18), 2)

        # 3 Horizontal steel channel crossarms
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 1.02, 0.0), (0.96, 0.045, 0.055), 0.015), 2)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.62, 0.0), (0.86, 0.040, 0.050), 0.015), 2)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, -0.34, 0.0), (0.84, 0.060, 0.26), 0.02), 2)

        # Transformer tank + cooling radiator fins + conservator drum
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.05, 0.04), (0.46, 0.34, 0.28), 0.05), 3)
        for fx in (-0.32, -0.16, 0.0, 0.16, 0.32):
            d, m = combine_sdf(d, m, sd_round_box(p, (fx, 0.04, 0.33), (0.032, 0.26, 0.045), 0.01), 2)
        d, m = combine_sdf(d, m, sd_cylinder_x(p, (0.0, 0.50, -0.04), 0.105, 0.34), 3)

        # Porcelain HV bushings & top disc insulators (ribbed sheds)
        for bx in (-0.28, 0.0, 0.28):
            d, m = combine_sdf(d, m, sd_cylinder_y(p, (bx, 0.52, 0.12), 0.042, 0.14), 4)
            d, m = combine_sdf(d, m, sd_torus_y(p, (bx, 0.56, 0.12), 0.055, 0.022), 4)
        for ix in (-0.72, 0.0, 0.72):
            d, m = combine_sdf(d, m, sd_cylinder_y(p, (ix, 1.20, 0.0), 0.05, 0.16), 4)
            for sy in (1.14, 1.22, 1.30):
                d, m = combine_sdf(d, m, sd_torus_y(p, (ix, sy, 0.0), 0.075, 0.024), 4)

        # LT distribution box & green earthing riser
        d, m = combine_sdf(d, m, sd_round_box(p, (-0.36, -0.68, 0.16), (0.18, 0.20, 0.12), 0.025), 3)
        d, m = combine_sdf(d, m, sd_cylinder_y(p, (0.79, -0.58, 0.08), 0.022, 0.45), 6)
        return d, m

    img = render_sdf_scene(340, 320, scene, scale=3.1)
    img.resize((240, 226), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


# ============================================================================
# 2. 3D 33/11kV Substation Switchyard
# ============================================================================
def build_substation_3d(path: Path):
    def scene(p):
        # Switchyard gravel foundation pad & perimeter curb
        d = sd_round_box(p, (0.0, -1.08, 0.0), (1.42, 0.12, 0.88), 0.04)
        m = np.ones_like(d, dtype=np.int32)

        # 3 Gantry towers & overhead busbars
        for gx in (-1.05, 0.0, 1.05):
            d, m = combine_sdf(d, m, sd_round_box(p, (gx, 0.05, -0.35), (0.07, 1.05, 0.07), 0.015), 2)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.98, -0.35), (1.18, 0.06, 0.07), 0.015), 2)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.56, -0.35), (1.14, 0.045, 0.055), 0.015), 2)

        # 5 MVA Power Transformer + radiator bank + conservator
        d, m = combine_sdf(d, m, sd_round_box(p, (-0.42, -0.45, 0.08), (0.48, 0.42, 0.34), 0.05), 3)
        for rx in (-0.72, -0.56, -0.28, -0.12):
            d, m = combine_sdf(d, m, sd_round_box(p, (rx, -0.46, 0.44), (0.035, 0.32, 0.05), 0.01), 2)
        d, m = combine_sdf(d, m, sd_cylinder_x(p, (-0.42, 0.12, -0.02), 0.12, 0.36), 2)

        # 3 HV Bushings on transformer
        for bx in (-0.64, -0.42, -0.20):
            d, m = combine_sdf(d, m, sd_cylinder_y(p, (bx, 0.18, 0.16), 0.045, 0.22), 4)
            for sy in (0.10, 0.20, 0.30):
                d, m = combine_sdf(d, m, sd_torus_y(p, (bx, sy, 0.16), 0.07, 0.022), 4)

        # 3 SF6 Circuit Breaker Porcelain Columns on right bay
        for cx in (0.36, 0.66, 0.96):
            d, m = combine_sdf(d, m, sd_round_box(p, (cx, -0.74, 0.18), (0.11, 0.22, 0.11), 0.02), 2)
            d, m = combine_sdf(d, m, sd_cylinder_y(p, (cx, -0.22, 0.18), 0.05, 0.34), 4)
            for sy in (-0.38, -0.24, -0.10, 0.04):
                d, m = combine_sdf(d, m, sd_torus_y(p, (cx, sy, 0.18), 0.075, 0.022), 4)

        # Warm yard floodlights on outer gantry tops
        for lx in (-1.05, 1.05):
            d, m = combine_sdf(d, m, sd_sphere(p, (lx, 1.16, -0.30), 0.095), 10)
        return d, m

    img = render_sdf_scene(380, 300, scene, scale=3.45)
    img.resize((260, 205), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


# ============================================================================
# 3. 3D Safety Training Pavilion Shed (with Real PPE & Cones Composited)
# ============================================================================
def build_training_shed_3d(path: Path):
    def scene(p):
        # Stone plinth
        d = sd_round_box(p, (0.0, -1.04, 0.0), (1.28, 0.13, 0.78), 0.04)
        m = np.ones_like(d, dtype=np.int32)

        # 4 Teak pillars
        for px in (-0.98, 0.98):
            for pz in (-0.52, 0.52):
                d, m = combine_sdf(d, m, sd_cylinder_y(p, (px, -0.18, pz), 0.075, 0.76), 7)

        # Wooden workbench inside pavilion
        d, m = combine_sdf(d, m, sd_round_box(p, (-0.18, -0.58, 0.08), (0.62, 0.06, 0.34), 0.025), 7)
        for lx in (-0.68, 0.32):
            d, m = combine_sdf(d, m, sd_cylinder_y(p, (lx, -0.78, 0.08), 0.045, 0.18), 7)

        # Stepped 3D hip roof with antique-gold ridge trim
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.64, 0.0), (1.38, 0.10, 0.86), 0.04), 3)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.80, 0.0), (1.02, 0.09, 0.62), 0.04), 3)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.93, 0.0), (0.62, 0.06, 0.34), 0.03), 5)
        return d, m

    img = render_sdf_scene(380, 300, scene, scale=3.35)

    # Composite actual high-detail PPE & cone assets onto the 3D bench and plinth
    def paste_asset(rel: str, pos: tuple[int, int], size: tuple[int, int]):
        ap = SCENE_DIR / rel
        if not ap.exists():
            ap = ROOT / "tool" / "media_src" / "zero_loss" / "scene" / rel
        if ap.exists():
            prop = Image.open(ap).convert("RGBA").resize(size, Image.Resampling.LANCZOS)
            img.alpha_composite(prop, dest=pos)

    paste_asset("gear_helmet.webp", (86, 146), (56, 56))
    paste_asset("gear_gloves.webp", (138, 152), (50, 50))
    paste_asset("gear_harness.webp", (180, 140), (58, 64))
    paste_asset("prop_cones_tape.webp", (236, 168), (92, 68))

    img.resize((260, 205), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


# ============================================================================
# 4. 3D 11kV Distribution Pole, Bridge, Tree Cluster & Treasure Chest
# ============================================================================
def build_pole_11kv_3d(path: Path):
    def scene(p):
        d = sd_cylinder_y(p, (0.0, -1.05, 0.0), 0.18, 0.22)
        m = np.ones_like(d, dtype=np.int32)
        d, m = combine_sdf(d, m, sd_cylinder_y(p, (0.0, 0.02, 0.0), 0.095, 1.15), 2)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.88, 0.0), (0.78, 0.045, 0.055), 0.015), 2)
        for ix, iy in ((-0.68, 1.05), (0.0, 1.26), (0.68, 1.05)):
            d, m = combine_sdf(d, m, sd_cylinder_y(p, (ix, iy, 0.0), 0.05, 0.14), 4)
            d, m = combine_sdf(d, m, sd_torus_y(p, (ix, iy + 0.04, 0.0), 0.075, 0.024), 4)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.18, 0.11), (0.14, 0.14, 0.02), 0.01), 9)
        return d, m

    img = render_sdf_scene(240, 320, scene, scale=2.9)
    img.resize((160, 214), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


def build_tree_cluster_3d(path: Path):
    def scene(p):
        d = sd_cylinder_y(p, (-0.15, -0.58, 0.0), 0.14, 0.52)
        m = np.full_like(d, 7, dtype=np.int32)
        d, m = combine_sdf(d, m, sd_cylinder_y(p, (0.35, -0.66, 0.12), 0.10, 0.42), 7)
        for cx, cy, cz, r in (
            (-0.42, 0.02, 0.08, 0.48),
            (0.28, -0.05, 0.14, 0.46),
            (-0.12, 0.38, 0.0, 0.56),
            (0.22, 0.28, -0.06, 0.44),
            (-0.24, 0.62, 0.06, 0.40),
        ):
            d, m = combine_sdf(d, m, sd_sphere(p, (cx, cy, cz), r), 6)
        d, m = combine_sdf(d, m, sd_sphere(p, (-0.58, -0.96, 0.24), 0.22), 1)
        d, m = combine_sdf(d, m, sd_sphere(p, (0.62, -0.98, 0.18), 0.18), 1)
        return d, m

    img = render_sdf_scene(280, 280, scene, scale=2.85)
    img.resize((190, 190), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


def build_bridge_3d(path: Path):
    def scene(p):
        d = sd_round_box(p, (-0.88, -0.45, 0.0), (0.24, 0.28, 0.42), 0.04)
        m = np.ones_like(d, dtype=np.int32)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.88, -0.45, 0.0), (0.24, 0.28, 0.42), 0.04), 1)
        for i in range(7):
            t = (i - 3) / 3.0
            px = t * 0.68
            py = -0.22 + (1.0 - t * t) * 0.26
            d, m = combine_sdf(d, m, sd_round_box(p, (px, py, 0.0), (0.10, 0.045, 0.38), 0.015), 7)
            if i in (0, 3, 6):
                for rz in (-0.34, 0.34):
                    d, m = combine_sdf(d, m, sd_cylinder_y(p, (px, py + 0.22, rz), 0.032, 0.20), 5)
        return d, m

    img = render_sdf_scene(300, 210, scene, scale=2.85)
    img.resize((210, 148), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


def build_treasure_chest_3d(path: Path):
    def scene(p):
        # Deep emerald chest box
        d = sd_round_box(p, (0.0, -0.28, 0.0), (0.68, 0.36, 0.46), 0.05)
        m = np.full_like(d, 6, dtype=np.int32)
        # Domed lid
        d, m = combine_sdf(d, m, sd_cylinder_x(p, (0.0, 0.12, 0.0), 0.44, 0.68), 6)
        # Antique-gold straps & rim frame
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.06, 0.0), (0.72, 0.055, 0.50), 0.02), 5)
        for sx in (-0.52, 0.0, 0.52):
            d, m = combine_sdf(d, m, sd_round_box(p, (sx, -0.26, 0.0), (0.065, 0.38, 0.49), 0.02), 5)
            d, m = combine_sdf(d, m, sd_cylinder_x(p, (sx, 0.12, 0.0), 0.47, 0.06), 5)
        # Front lock escutcheon + glowing seam jewel
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.04, 0.48), (0.16, 0.18, 0.06), 0.025), 5)
        d, m = combine_sdf(d, m, sd_sphere(p, (0.0, 0.06, 0.53), 0.065), 10)
        return d, m

    img = render_sdf_scene(280, 260, scene, scale=2.45)
    img.resize((180, 168), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


def build_zero_death_crest_3d(path: Path):
    def scene(p):
        d = sd_torus_y(p.transpose(0, 1, 2)[..., [0, 2, 1]], (0.0, 0.0, 0.0), 0.78, 0.12)
        m = np.full_like(d, 5, dtype=np.int32)
        d, m = combine_sdf(d, m, sd_cylinder_y(p.transpose(0, 1, 2)[..., [0, 2, 1]], (0.0, 0.0, 0.0), 0.72, 0.08), 3)
        # 3D Safety Helmet sculpted in center
        d, m = combine_sdf(d, m, sd_sphere(p, (0.0, 0.18, 0.14), 0.32), 8)
        d, m = combine_sdf(d, m, sd_round_box(p, (0.0, 0.04, 0.22), (0.36, 0.04, 0.28), 0.02), 8)
        return d, m

    img = render_sdf_scene(280, 280, scene, scale=2.45, pitch_deg=14.0, yaw_deg=18.0)
    img.resize((180, 180), Image.Resampling.LANCZOS).save(path, format="WEBP", quality=92, method=6)


# ============================================================================
# 5. 3D Medallions, Valley Terrain & Mesh Exports
# ============================================================================
from generate_3d_world import (  # reuse fast vectorized coin & valley terrain functions
    export_obj_meshes,
    render_checkpoint_coin,
    render_valley_terrain_bg,
    write_asset_register,
)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    export_obj_meshes()

    render_valley_terrain_bg(OUT_DIR / "terrain_valley_bg.webp")
    build_training_shed_3d(OUT_DIR / "training_shed_3d.webp")
    build_dtr_3d(OUT_DIR / "dtr_station_3d.webp")
    build_substation_3d(OUT_DIR / "substation_33kv_3d.webp")
    build_pole_11kv_3d(OUT_DIR / "pole_11kv_3d.webp")
    build_tree_cluster_3d(OUT_DIR / "tree_cluster_3d.webp")
    build_bridge_3d(OUT_DIR / "bridge_arch_3d.webp")
    build_treasure_chest_3d(OUT_DIR / "chest_treasure_3d.webp")
    build_zero_death_crest_3d(OUT_DIR / "zero_death_crest_3d.webp")

    render_checkpoint_coin(
        OUT_DIR / "coin_current_3d.webp",
        rim_rgb=(0.94, 0.78, 0.38),
        core_rgb=(0.86, 0.58, 0.12),
        inner_glow_rgb=(1.0, 0.88, 0.35),
        locked=False,
    )
    render_checkpoint_coin(
        OUT_DIR / "coin_cleared_3d.webp",
        rim_rgb=(0.85, 0.70, 0.35),
        core_rgb=(0.04, 0.56, 0.38),
        inner_glow_rgb=(0.25, 0.92, 0.62),
        locked=False,
    )
    render_checkpoint_coin(
        OUT_DIR / "coin_locked_3d.webp",
        rim_rgb=(0.68, 0.73, 0.80),
        core_rgb=(0.22, 0.28, 0.36),
        inner_glow_rgb=(0.45, 0.52, 0.62),
        locked=True,
    )
    render_checkpoint_coin(
        OUT_DIR / "medallion_emerald_3d.webp",
        rim_rgb=(0.86, 0.71, 0.36),
        core_rgb=(0.05, 0.52, 0.36),
        inner_glow_rgb=(0.22, 0.88, 0.58),
    )
    render_checkpoint_coin(
        OUT_DIR / "medallion_navy_3d.webp",
        rim_rgb=(0.86, 0.71, 0.36),
        core_rgb=(0.10, 0.24, 0.46),
        inner_glow_rgb=(0.32, 0.68, 0.98),
    )
    render_checkpoint_coin(
        OUT_DIR / "medallion_bronze_3d.webp",
        rim_rgb=(0.92, 0.76, 0.38),
        core_rgb=(0.54, 0.28, 0.10),
        inner_glow_rgb=(0.96, 0.68, 0.24),
    )

    manifest = []
    for p in sorted(OUT_DIR.glob("*.webp")):
        with Image.open(p) as im:
            w, h = im.size
        manifest.append({
            "file": f"assets/duty_slip/world3d/{p.name}",
            "dimensions": f"{w}x{h}",
            "format": "WebP (RGBA/RGB)",
            "category": "3D SDF Raymarched + PBR Adventure World Asset",
            "creator": "SmartLineMan 3D Pipeline (tool/world3d_production)",
            "licence": "CC0 1.0 Universal / First-Party Unrestricted",
        })
    write_asset_register(manifest)
    print(f"Raymarched & exported {len(manifest)} 3D assets.")


if __name__ == "__main__":
    main()
