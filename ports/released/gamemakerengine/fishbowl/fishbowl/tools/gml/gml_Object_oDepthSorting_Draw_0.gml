var _nof_instances = instance_number(opThing);
_nof_instances += 1;

if (ds_grid_height(ds_depth_grid) != _nof_instances)
    ds_grid_resize(ds_depth_grid, 2, _nof_instances);

global.__dsg = ds_depth_grid;
global.__dsi = 0;

with (opThing)
{
    ds_grid_set(global.__dsg, 0, global.__dsi, id);
    ds_grid_set(global.__dsg, 1, global.__dsi, y);
    global.__dsi += 1;
}

ds_grid_set(ds_depth_grid, 0, global.__dsi, oAlo);
ds_grid_set(ds_depth_grid, 1, global.__dsi, oAlo.y);
ds_grid_sort(ds_depth_grid, 1, true);

// Cull things whose bbox is off-screen so we don't submit draws for them. The bbox already
// includes the full sprite extent; a small 16px pad covers selection outlines / on-top things.
var _pad = 16;
global.__dsL = camera_get_view_x(view_camera[0]) - _pad;
global.__dsT = camera_get_view_y(view_camera[0]) - _pad;
global.__dsR = global.__dsL + camera_get_view_width(view_camera[0]) + _pad * 2;
global.__dsB = global.__dsT + camera_get_view_height(view_camera[0]) + _pad * 2;

var _i = 0;

repeat (_nof_instances)
{
    var _obj_to_draw = ds_grid_get(ds_depth_grid, 0, _i);
    _i += 1;

    with (_obj_to_draw)
    {
        if (object_index == oAlo || !(bbox_right < global.__dsL || bbox_left > global.__dsR || bbox_bottom < global.__dsT || bbox_top > global.__dsB))
        {
            if (object_index == oAlo && global.showAlo == false)
            {
            }
            else if (object_index == oAlo)
            {
                draw_self();

                with (oAlo.store.portrait)
                {
                    if (store.visibility)
                        draw_self();
                }

                with (oAlo.store.mood)
                {
                    if (sprite_index != -4 && sprite_index != -1)
                    {
                        updatePosition();
                        draw_self();
                    }
                }
            }
            else
            {
                state.draw();
            }

            drawOnTopThings();
        }
    }
}
