// Perf patch: raindrops are drawn in a single batched bm_add pass by
// obj_lw_rain_effect's Draw event instead of per-instance. If the controller
// is gone (end of the rain sequence), fall back to stock self-drawing so the
// last drops stay visible while they fall offscreen.

if (!instance_exists(obj_lw_rain_effect))
{
    draw_set_blend_mode(bm_add);
    draw_self();
    draw_set_blend_mode(bm_normal);
}
