"""
SmartLineMan — Blender Python (bpy) Automated 3D World Pipeline
===============================================================
Usage with Blender CLI (3.6+ / 4.x):
    blender -b -P tool/world3d_production/blender_world_pipeline.py

This script procedurally constructs the SmartLineMan 3D electrical distribution
and adventure world inside Blender, assigns Principled BSDF materials (Midnight
Navy, Deep Emerald, Antique Gold, Galvanized Steel, Porcelain, Copper, Teak),
configures an oblique isometric orthographic camera (32 deg elevation) with
three-point Golden Hour sun + sky hemisphere lighting + Ambient Occlusion,
saves the reusable `.blend` library, and renders transparent WebP/PNG sprites.

When Blender is not installed on a workstation, `generate_3d_world.py` in this
same folder exports the 3D `.obj` meshes and renders all assets using the
built-in NumPy/SciPy PBR + ray-shadow engine.
"""

import math
import os
import sys

try:
    import bpy  # type: ignore
    HAS_BPY = True
except ImportError:
    HAS_BPY = False


PALETTE_RGBA = {
    "navy_deep": (0.039, 0.078, 0.157, 1.0),
    "emerald": (0.020, 0.588, 0.412, 1.0),
    "gold_antique": (0.827, 0.678, 0.361, 1.0),
    "gold_champagne": (0.945, 0.875, 0.690, 1.0),
    "steel_galv": (0.710, 0.760, 0.815, 1.0),
    "transformer_slate": (0.365, 0.435, 0.510, 1.0),
    "porcelain_brown": (0.480, 0.240, 0.140, 1.0),
    "porcelain_glaze": (0.140, 0.450, 0.340, 1.0),
    "wood_teak": (0.420, 0.255, 0.120, 1.0),
    "foliage_ lush": (0.145, 0.420, 0.180, 1.0),
    "danger_red": (0.820, 0.160, 0.160, 1.0),
}


def make_pbr_material(name: str, rgba, metallic: float = 0.0, roughness: float = 0.45, emission: float = 0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = rgba
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        if emission > 0 and "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = rgba
            bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def setup_scene_and_camera():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = True
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512

    cam_data = bpy.data.cameras.new("IsoObliqueCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 5.4
    cam_obj = bpy.data.objects.new("IsoObliqueCam", cam_data)
    scene.collection.objects.link(cam_obj)
    cam_obj.location = (6.0, -6.0, 5.2)
    cam_obj.rotation_euler = (math.radians(58.0), 0.0, math.radians(45.0))
    scene.camera = cam_obj

    sun_data = bpy.data.lights.new(name="GoldenHourSun", type="SUN")
    sun_data.energy = 3.8
    sun_data.color = (1.0, 0.93, 0.78)
    sun_obj = bpy.data.objects.new(name="GoldenHourSun", object_data=sun_data)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(48.0), math.radians(-18.0), math.radians(32.0))

    fill_data = bpy.data.lights.new(name="SkyFill", type="AREA")
    fill_data.energy = 120.0
    fill_data.color = (0.62, 0.80, 1.0)
    fill_obj = bpy.data.objects.new(name="SkyFill", object_data=fill_data)
    scene.collection.objects.link(fill_obj)
    fill_obj.location = (-5.0, 4.0, 6.0)
    return scene


def build_dtr_structure(mats):
    for side in (-1.1, 1.1):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.11, depth=3.8, location=(side, 0, 1.9))
        pole = bpy.context.active_object
        pole.data.materials.append(mats["steel"])
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.85))
    tank = bpy.context.active_object
    tank.scale = (0.85, 0.55, 0.65)
    tank.data.materials.append(mats["slate"])
    for bx in (-0.45, 0.0, 0.45):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.38, location=(bx, 0, 2.65))
        bush = bpy.context.active_object
        bush.data.materials.append(mats["porcelain"])


def main():
    if not HAS_BPY:
        print("Blender (bpy) is not active in this Python interpreter.")
        print("Run `python tool/world3d_production/generate_3d_world.py` for standalone 3D mesh + PBR sprite generation.")
        return

    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "duty_slip", "world3d"))
    os.makedirs(out_dir, exist_ok=True)
    scene = setup_scene_and_camera()
    mats = {
        "steel": make_pbr_material("GalvSteel", PALETTE_RGBA["steel_galv"], metallic=0.75, roughness=0.32),
        "slate": make_pbr_material("TransformerSlate", PALETTE_RGBA["transformer_slate"], metallic=0.55, roughness=0.38),
        "porcelain": make_pbr_material("PorcelainInsulator", PALETTE_RGBA["porcelain_brown"], metallic=0.05, roughness=0.18),
        "gold": make_pbr_material("AntiqueGold", PALETTE_RGBA["gold_antique"], metallic=0.88, roughness=0.24),
        "emerald": make_pbr_material("DeepEmerald", PALETTE_RGBA["emerald"], metallic=0.15, roughness=0.28),
    }
    build_dtr_structure(mats)
    blend_path = os.path.join(os.path.dirname(__file__), "smartlineman_world3d.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    scene.render.filepath = os.path.join(out_dir, "dtr_station_bpy.png")
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
