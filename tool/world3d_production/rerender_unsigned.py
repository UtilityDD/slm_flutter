"""Re-render the three structures that used to carry baked sign text."""

from raymarch_3d_world import (
    OUT_DIR,
    build_dtr_3d,
    build_substation_3d,
    build_training_shed_3d,
)

if __name__ == "__main__":
    build_dtr_3d(OUT_DIR / "dtr_station_3d.webp")
    build_substation_3d(OUT_DIR / "substation_33kv_3d.webp")
    build_training_shed_3d(OUT_DIR / "training_shed_3d.webp")
    print("unsigned structures written")
