var _cfg = variable_struct_get(shaderDetails, currentShader);
global.gradeBrt = variable_struct_get(_cfg, "brt");
global.gradeCon = variable_struct_get(_cfg, "con");
global.gradeSat = variable_struct_get(_cfg, "sat");

// View bounds for culling lights that aren't on screen.
var _vl = camera_get_view_x(view_camera[0]);
var _vt = camera_get_view_y(view_camera[0]);
var _vr = _vl + camera_get_view_width(view_camera[0]);
var _vb = _vt + camera_get_view_height(view_camera[0]);

gpu_set_blendmode_ext_sepalpha(bm_zero, bm_one, bm_zero, bm_inv_src_alpha);

with (opLight)
{
    if (layer_get_visible(layer) && !(bbox_right < _vl || bbox_left > _vr || bbox_bottom < _vt || bbox_top > _vb))
        draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale, image_angle, image_blend, effectiveSubIntensity);
}

gpu_set_blendmode(bm_add);

with (opLight)
{
    if (layer_get_visible(layer) && !(bbox_right < _vl || bbox_left > _vr || bbox_bottom < _vt || bbox_top > _vb))
        draw_sprite_ext(sprite_index, -1, x, y, image_xscale, image_yscale, image_angle, color, addIntensity);
}

gpu_set_blendmode(bm_normal);
