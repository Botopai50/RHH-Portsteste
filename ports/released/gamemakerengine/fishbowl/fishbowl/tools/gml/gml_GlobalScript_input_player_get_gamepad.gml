// Force the game to always consider a gamepad present.
//
// This port drives all input through gptokeyb (keyboard) so the d-pad works in
// menus and the packing puzzle without the native pad stealing the Input source.
// But the UI's keyboard-vs-gamepad glyph choice keys off isOnKeyboard(), which is
// just `input_player_get_gamepad() == -1`. oUIShowControls.getMoveSprite() and
// friends bypass input_verb_get_icon and pick kbdMove*/gpdMove* sprites directly
// from that check, so without this the movement prompts would draw keyboard arrows.
// Returning a valid index here keeps isOnKeyboard() false everywhere, so gamepad
// glyphs are drawn at all times. The only non-debug callers are glyph-styling
// (input_player_get_gamepad_type, which falls back to the "xbox one" icon set) and
// DualSense trigger effects (unused here), so this is display-only and safe.
function input_player_get_gamepad(arg0 = 0, arg1 = undefined)
{
    return 0;
}
