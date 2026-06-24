if (global.IdolSFX == 1 && !debugDisableMandala)
{
    if (!surface_exists(global.smallDrawingSurface))
    {
        global.smallDrawingSurface = surface_create(384, 216);
        drawSurfaceSmall = global.smallDrawingSurface;
        global.mandalaRedrawAccum = 100000;
    }
    if (surface_exists(drawSurfaceSmall))
    {
        global.mandalaRedrawAccum += delta_time;
        if (global.mandalaRedrawAccum >= 33333)
        {
            global.mandalaRedrawAccum = 0;
            surface_set_target(drawSurfaceSmall);
            draw_clear_alpha(c_white, 0);
            var angleIncrement = angleInc;
            for (var i = 0; i < gemCount; i++)
            {
                with (gemArray[i])
                {
                    var angle = angle_clamp(point_direction(x, y, focalPointX, focalPointY) - angleIncrement);
                    var x2 = focalPointX;
                    var y2 = focalPointY;
                    draw_set_color(lineColor);
                    draw_line_curved_width(x, y, x2, y2, angle, false, 8, 3);
                    draw_line_curved_width(x, y, x2, y2, angle, true, 8, 3);
                }
            }
            surface_reset_target();
        }
        draw_surface(drawSurfaceSmall, 0, 0);
    }
}
