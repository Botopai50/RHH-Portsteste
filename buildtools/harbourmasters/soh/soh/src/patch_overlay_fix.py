from pathlib import Path

PROJECT = Path('/root/build-port/project')
SOH = PROJECT / 'soh' / 'soh'
LUS = PROJECT / 'libultraship'

# Fix the generated compact overlay so it builds on the celshade branch and
# uses SoH's own controller state instead of newer ImGui gamepad key names.
stats_cpp = SOH / 'Enhancements' / 'debugger' / 'SohStatsWindow.cpp'
s = stats_cpp.read_text()

s = s.replace(
    '#include "soh/cvar_prefixes.h"\n\n#include <algorithm>',
    '#include "soh/cvar_prefixes.h"\n#include <ship/Context.h>\n#include <libultraship/controller/controldeck/ControlDeck.h>\n#include "libultraship/libultra/controller.h"\n\n#include <algorithm>\n#include <cstdint>\n#include <memory>',
    1,
)

old_combo = '''static bool ResetComboPressed() {
#if defined(IMGUI_VERSION_NUM) && IMGUI_VERSION_NUM >= 18700
    // Y is the upper face button in ImGui's gamepad naming.
    bool comboDown = ImGui::IsKeyDown(ImGuiKey_GamepadL1) && ImGui::IsKeyDown(ImGuiKey_GamepadR1) &&
                     ImGui::IsKeyDown(ImGuiKey_GamepadFaceUp);
    bool pressed = comboDown && !gFps.comboWasDown;
    gFps.comboWasDown = comboDown;
    return pressed;
#else
    return false;
#endif
}
'''

new_combo = '''static bool ResetComboPressed() {
    auto deck = std::dynamic_pointer_cast<LUS::ControlDeck>(Ship::Context::GetInstance()->GetControlDeck());
    if (deck == nullptr) {
        gFps.comboWasDown = false;
        return false;
    }

    OSContPad* pads = deck->GetPads();
    if (pads == nullptr) {
        gFps.comboWasDown = false;
        return false;
    }

    const uint16_t buttons = pads[0].button;
    // PortMaster/gamepad Y can land on different N64 inputs depending on the active mapping.
    // Accept C-Up, B, or the custom modifiers so the reset shortcut remains usable on handhelds.
    const bool yLike = (buttons & BTN_CUP) || (buttons & BTN_B) || (buttons & BTN_CUSTOM_MODIFIER1) ||
                       (buttons & BTN_CUSTOM_MODIFIER2);
    const bool comboDown = (buttons & BTN_L) && (buttons & BTN_R) && yLike;
    const bool pressed = comboDown && !gFps.comboWasDown;
    gFps.comboWasDown = comboDown;
    return pressed;
}
'''

if old_combo in s:
    s = s.replace(old_combo, new_combo, 1)
else:
    print('overlay fix: ImGui gamepad combo block not found; leaving combo unchanged')

stats_cpp.write_text(s)

# Avoid newer/combined ImGui flags that may be missing in the version bundled by this branch.
soh_gui_cpp = SOH / 'SohGui' / 'SohGui.cpp'
s = soh_gui_cpp.read_text()
s = s.replace(
    'ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings |\n'
    '            ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav | ImGuiWindowFlags_NoMove |\n'
    '            ImGuiWindowFlags_NoScrollbar',
    'ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoCollapse |\n'
    '            ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings |\n'
    '            ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoScrollbar',
    1,
)
soh_gui_cpp.write_text(s)

# The OpenGL mipmap helper logs through SPDLOG_INFO; make the include explicit.
gfx_cpp = LUS / 'src' / 'fast' / 'backends' / 'gfx_opengl.cpp'
s = gfx_cpp.read_text()
if '#include <spdlog/spdlog.h>' not in s:
    s = s.replace('#include <fstream>\n', '#include <fstream>\n#include <spdlog/spdlog.h>\n', 1)
    gfx_cpp.write_text(s)

print('Applied overlay compatibility fix')
