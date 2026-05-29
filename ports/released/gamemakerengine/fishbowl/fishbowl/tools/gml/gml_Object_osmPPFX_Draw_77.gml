// Lightweight replacement for the PPFX post chain: apply only the colour grade
// (brightness/contrast/saturation from oShaderApply) when blitting the application
// surface to the screen. The full PPFX effect stack is bypassed for performance.
gpu_push_state();
gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
gpu_set_blendenable(false);
if (instance_exists(oShaderApply) && variable_global_exists("gradeBrt"))
{
    var _sh = asset_get_index("shPhotoshop");
    shader_set(_sh);
    shader_set_uniform_f(shader_get_uniform(_sh, "brightness"), global.gradeBrt);
    shader_set_uniform_f(shader_get_uniform(_sh, "contrast"), global.gradeCon);
    shader_set_uniform_f(shader_get_uniform(_sh, "saturation"), global.gradeSat);
    draw_surface_stretched(application_surface, 0, 0, window_get_width(), window_get_height());
    shader_reset();
}
else
{
    draw_surface_stretched(application_surface, 0, 0, window_get_width(), window_get_height());
}
gpu_pop_state();
