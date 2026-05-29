// Force UI prompt glyphs to always use the gamepad profile.
//
// On a handheld the controller is the only real input device, but the launcher
// runs gptokeyb alongside the native SDL gamepad to map the d-pad to arrow keys
// (some puzzles need the analog stick, which gptokeyb can't reach). Those synthetic
// key events flip JujuAdams Input's active profile to keyboard_and_mouse, so verb
// icons resolve to keyboard glyphs. By pinning the binding lookup to the "gamepad"
// profile whenever the caller didn't request a specific one, every prompt that goes
// through a verb (oUIShowControls, etc.) shows gamepad buttons regardless of which
// device most recently produced input. Input reading itself is untouched.
function input_verb_get_icon(arg0, arg1 = 0, arg2 = 0, arg3 = undefined)
{
    if (arg3 == undefined)
        arg3 = "gamepad";
    return input_binding_get_icon(input_binding_get(arg0, arg1, arg2, arg3), arg1);
}
