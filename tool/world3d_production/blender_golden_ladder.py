"""
Monumental golden ladder for SmartLineMan.

Run inside Blender:
    blender --background --python tool/world3d_production/blender_golden_ladder.py

Builds two bevelled antique-gold rails, five rungs, emerald joint collars
and one checkpoint plinth. Saves the .blend next to this script and, when
the script is started with a real Blender build, renders a transparent
preview into assets/duty_slip/world3d/golden_ladder_section.png.

The live phone ladder is drawn in Flutter (adventure_map.dart) so the rails
stay sharp while the list scrolls. This file is the modelling source.
"""

from __future__ import annotations

from pathlib import Path

try:
    import bpy
except ImportError:
    raise SystemExit("This script runs inside Blender: blender --background --python blender_golden_ladder.py")

ROOT = Path(__file__).resolve().parents[2]
OUT_BLEND = Path(__file__).resolve().parent / "golden_ladder_section.blend"
OUT_PNG = ROOT / "assets" / "duty_slip" / "world3d" / "golden_ladder_section.png"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def metal(name: str, color: tuple[float, float, float], metallic: float, roughness: float) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    return mat


def box(name: str, location, scale, material, bevel: float = 0.02) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.shade_smooth()
    bevel_mod = obj.modifiers.new("Bevel", "BEVEL")
    bevel_mod.width = bevel
    bevel_mod.segments = 3
    obj.data.materials.append(material)
    return obj


def main() -> None:
    clear_scene()
    gold = metal("AntiqueGold", (0.72, 0.55, 0.22), 1.0, 0.28)
    champagne = metal("ChampagneGold", (0.95, 0.86, 0.55), 1.0, 0.18)
    emerald = metal("Emerald", (0.05, 0.45, 0.28), 0.35, 0.32)
    navy = metal("MidnightPlinth", (0.05, 0.10, 0.16), 0.2, 0.45)

    for side, x in (("L", -0.42), ("R", 0.42)):
        box(f"Rail_{side}", (x, 0.0, 1.35), (0.07, 0.06, 1.45), gold, bevel=0.015)
        box(f"Inlay_{side}", (x, -0.025, 1.35), (0.018, 0.02, 1.42), emerald, bevel=0.004)

    for i in range(5):
        z = 0.15 + i * 0.55
        box(f"Rung_{i+1}", (0.0, 0.0, z), (0.92, 0.045, 0.055), champagne, bevel=0.01)
        for x in (-0.42, 0.42):
            bpy.ops.mesh.primitive_uv_sphere_add(radius=0.055, location=(x, 0.0, z), segments=24, ring_count=16)
            collar = bpy.context.active_object
            collar.name = f"Collar_{i+1}_{'L' if x < 0 else 'R'}"
            collar.data.materials.append(emerald)

    box("CheckpointPlinth", (0.0, 0.0, 1.25), (0.28, 0.08, 0.28), navy, bevel=0.02)
    box("CheckpointRim", (0.0, -0.02, 1.25), (0.22, 0.05, 0.22), gold, bevel=0.015)

    sun = bpy.data.objects.get("Light")
    if sun is None:
        bpy.ops.object.light_add(type="SUN", location=(-2.5, -3.0, 6.0))
        sun = bpy.context.active_object
    sun.data.energy = 3.5
    sun.rotation_euler = (0.9, 0.2, -0.6)

    bpy.ops.object.camera_add(location=(0.0, -4.6, 1.5), rotation=(1.35, 0.0, 0.0))
    cam = bpy.context.active_object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 3.4
    bpy.context.scene.camera = cam

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 64
    scene.render.resolution_x = 720
    scene.render.resolution_y = 1280
    scene.render.film_transparent = True
    scene.render.filepath = str(OUT_PNG)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND))
    try:
        bpy.ops.render.render(write_still=True)
    except Exception as exc:  # noqa: BLE001
        print(f"Scene saved. Render skipped: {exc}")
    print(f"Wrote {OUT_BLEND}")


if __name__ == "__main__":
    main()
