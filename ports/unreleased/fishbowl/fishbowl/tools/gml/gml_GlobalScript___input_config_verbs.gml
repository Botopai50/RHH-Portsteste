return
{
    keyboard_and_mouse:
    {
        up: [input_binding_key(38), input_binding_key("W")],
        down: [input_binding_key(40), input_binding_key("S")],
        left: [input_binding_key(37), input_binding_key("A")],
        right: [input_binding_key(39), input_binding_key("D")],
        action: [input_binding_key("E"), input_binding_key(32), input_binding_key(13)],
        cancel: input_binding_key(8),
        sp1: input_binding_key("F"),
        sp2: input_binding_key("Q"),
        pause: input_binding_key(27),
        cursor_click: [input_binding_key("E"), input_binding_key(32), input_binding_mouse_button(1)],
        cursor_up: [input_binding_key(38), input_binding_key("W")],
        cursor_down: [input_binding_key(40), input_binding_key("S")],
        cursor_left: [input_binding_key(37), input_binding_key("A")],
        cursor_right: [input_binding_key(39), input_binding_key("D")],
        debug: input_binding_key("1"),
        debug_fps: input_binding_key("2"),
        backtoqa: input_binding_key("3")
    },
    gamepad:
    {
        up: [input_binding_gamepad_axis(32786, true), input_binding_gamepad_button(32781)],
        down: [input_binding_gamepad_axis(32786, false), input_binding_gamepad_button(32782)],
        left: [input_binding_gamepad_axis(32785, true), input_binding_gamepad_button(32783)],
        right: [input_binding_gamepad_axis(32785, false), input_binding_gamepad_button(32784)],
        action: [input_binding_gamepad_button(32769), input_binding_gamepad_button(32776)],
        cancel: input_binding_gamepad_button(32770),
        sp1: input_binding_gamepad_button(32771),
        sp2: input_binding_gamepad_button(32772),
        pause: input_binding_gamepad_button(32778),
        cursor_click: [input_binding_gamepad_button(32769), input_binding_gamepad_button(32776)],
        cursor_up: [input_binding_gamepad_axis(32786, true), input_binding_gamepad_button(32781)],
        cursor_down: [input_binding_gamepad_axis(32786, false), input_binding_gamepad_button(32782)],
        cursor_left: [input_binding_gamepad_axis(32785, true), input_binding_gamepad_button(32783)],
        cursor_right: [input_binding_gamepad_axis(32785, false), input_binding_gamepad_button(32784)],
        debug: input_binding_gamepad_button(32773),
        debug_fps: input_binding_gamepad_button(32775),
        backtoqa: input_binding_gamepad_button(32774)
    }
};
