from pathlib import Path

PROJECT = Path('/root/build-port/project')
SOH = PROJECT / 'soh' / 'soh'
LUS = PROJECT / 'libultraship'


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        print(f'{label}: already applied')
        return text
    if old not in text:
        raise SystemExit(f'{label}: target block not found')
    print(f'{label}: applied')
    return text.replace(old, new, 1)


# --------------------------------------------------------------------------------------
# 1) Wind Waker Style -> Performance menu
# --------------------------------------------------------------------------------------
menu = SOH / 'SohGui' / 'SohMenuWindWakerStyle.cpp'
s = menu.read_text()

anchor = '''    // ===========================================================================================
    // Sky — the Wind Waker-style sky replacement: gradient dome + drifting clouds + night stars.
    // ===========================================================================================
'''

performance_menu = '''    // ===========================================================================================
    // Performance — lightweight GPU texture tuning and monitoring for handhelds.
    // ===========================================================================================
    auto hideUnlessTextureMipmaps = [](WidgetInfo& info) {
        info.isHidden = !CVarGetInteger(CVAR_ENHANCEMENT("Graphics.TextureMipmaps.Enabled"), 0);
    };
    auto hideUnlessPerfOverlay = [](WidgetInfo& info) {
        info.isHidden = !CVarGetInteger(CVAR_WINDOW("SohStats"), 0);
    };
    path = { "Wind Waker Style", "Performance", SECTION_COLUMN_1 };
    AddSidebarEntry("Wind Waker Style", "Performance", 2);

    AddWidget(path, "Texture Mipmaps", WIDGET_SEPARATOR_TEXT);
    AddWidget(path, "Enable Texture Mipmaps", WIDGET_CVAR_CHECKBOX)
        .CVar(CVAR_ENHANCEMENT("Graphics.TextureMipmaps.Enabled"))
        .RaceDisable(false)
        .Options(CheckboxOptions().DefaultValue(false).Tooltip(
            "Generates GPU mipmaps for loaded textures and uses them only when textures are minified. "
            "This can reduce texture shimmer and sampling cost on distant floors, walls and scenery without "
            "replacing textures or changing model/actor LOD."));
    AddWidget(path, "Mipmap Bias", WIDGET_CVAR_SLIDER_FLOAT)
        .CVar(CVAR_ENHANCEMENT("Graphics.TextureMipmaps.Bias"))
        .RaceDisable(false)
        .PreFunc(hideUnlessTextureMipmaps)
        .Options(FloatSliderOptions()
                     .Tooltip("Adjusts how early smaller mip levels are chosen when supported by the backend. "
                              "0 = normal. Positive values prefer smaller/cheaper mip levels sooner; too high "
                              "can make distant textures blurrier. Negative values keep sharper mips longer.")
                     .Format("%.2f")
                     .Min(-1.0f)
                     .Max(2.0f)
                     .DefaultValue(0.0f));

    AddWidget(path, "Debug", WIDGET_SEPARATOR_TEXT).PreFunc(hideUnlessTextureMipmaps);
    AddWidget(path, "Log Mipmap Uploads", WIDGET_CVAR_CHECKBOX)
        .CVar(CVAR_DEVELOPER_TOOLS("TextureMipmaps.LogUploads"))
        .RaceDisable(false)
        .PreFunc(hideUnlessTextureMipmaps)
        .Options(CheckboxOptions().DefaultValue(false).Tooltip(
            "Writes a limited [SOH-MIPMAP] line to the log when the renderer creates texture mipmaps. "
            "Useful on small screens where the visual difference is hard to see."));

    path.column = SECTION_COLUMN_2;
    AddWidget(path, "Performance Overlay", WIDGET_SEPARATOR_TEXT);
    AddWidget(path, "Show Performance Overlay", WIDGET_CVAR_CHECKBOX)
        .CVar(CVAR_WINDOW("SohStats"))
        .RaceDisable(false)
        .Options(CheckboxOptions().DefaultValue(false).Tooltip(
            "Shows a tiny corner overlay with FPS, FPS average/min/max, frame time, CPU, RAM, and GPU load "
            "when the kernel exposes it. Designed to fit a 640x480 handheld screen."));
    AddWidget(path, "Overlay Corner: %d", WIDGET_CVAR_SLIDER_INT)
        .CVar(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.Corner"))
        .RaceDisable(false)
        .PreFunc(hideUnlessPerfOverlay)
        .Options(IntSliderOptions()
                     .Tooltip("Overlay position: 0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right.")
                     .Min(0)
                     .Max(3)
                     .DefaultValue(1)
                     .ShowButtons(true)
                     .Format("%d"));
    AddWidget(path, "Overlay Scale", WIDGET_CVAR_SLIDER_FLOAT)
        .CVar(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.Scale"))
        .RaceDisable(false)
        .PreFunc(hideUnlessPerfOverlay)
        .Options(FloatSliderOptions()
                     .Tooltip("Text scale for the tiny overlay. Lower values fit better on 640x480 screens.")
                     .Format("%.2fx")
                     .Min(0.65f)
                     .Max(1.05f)
                     .DefaultValue(0.78f));
    AddWidget(path, "Detailed Overlay", WIDGET_CVAR_CHECKBOX)
        .CVar(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.Detailed"))
        .RaceDisable(false)
        .PreFunc(hideUnlessPerfOverlay)
        .Options(CheckboxOptions().DefaultValue(false).Tooltip(
            "Shows extra app CPU and system RAM details. Leave off for the smallest 3-line overlay."));
    AddWidget(path, "Reset FPS Stats", WIDGET_BUTTON)
        .PreFunc(hideUnlessPerfOverlay)
        .Callback([](WidgetInfo& info) {
            int resetSerial = CVarGetInteger(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.ResetStats"), 0) + 1;
            CVarSetInteger(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.ResetStats"), resetSerial);
            Ship::Context::GetInstance()->GetWindow()->GetGui()->SaveConsoleVariablesNextFrame();
        })
        .Options(ButtonOptions().Tooltip(
            "Resets FPS average, minimum and maximum. In-game shortcut: hold L1 + R1 and press Y."));

'''

if performance_menu not in s:
    if anchor not in s:
        raise SystemExit('performance menu patch failed: Sky section anchor not found')
    s = s.replace(anchor, performance_menu + anchor, 1)
    menu.write_text(s)
    print('Performance menu patch: applied')
else:
    print('Performance menu patch: already applied')


# --------------------------------------------------------------------------------------
# 2) Existing SohStatsWindow becomes a tiny no-decoration overlay.
# --------------------------------------------------------------------------------------
soh_gui_cpp = SOH / 'SohGui' / 'SohGui.cpp'
s = soh_gui_cpp.read_text()
old_stats_window = '''    mStatsWindow = std::make_shared<SohStatsWindow>(CVAR_WINDOW("SohStats"), "Stats##Soh", ImVec2(400, 100));
    gui->AddGuiWindow(mStatsWindow);
'''
new_stats_window = '''    mStatsWindow = std::make_shared<SohStatsWindow>(
        CVAR_WINDOW("SohStats"), false, "Perf##SohStats", ImVec2(1, 1),
        ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings |
            ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav | ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoScrollbar);
    gui->AddGuiWindow(mStatsWindow);
'''
s = replace_once(s, old_stats_window, new_stats_window, 'Compact stats overlay registration')
soh_gui_cpp.write_text(s)


# --------------------------------------------------------------------------------------
# 3) Compact CPU/RAM/GPU/FPS overlay implementation.
# --------------------------------------------------------------------------------------
stats_cpp = SOH / 'Enhancements' / 'debugger' / 'SohStatsWindow.cpp'
stats_cpp.write_text(r'''#include "SohStatsWindow.h"
#include "soh/cvar_prefixes.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#if defined(__linux__)
#include <dirent.h>
#include <unistd.h>
#endif

namespace {

struct PerfMetrics {
    float cpuTotal = -1.0f;
    float appCpu = -1.0f;
    float ramUsedPct = -1.0f;
    unsigned long long appRamMb = 0;
    unsigned long long totalRamMb = 0;
    float gpuPct = -1.0f;
    float tempC = -1.0f;
    double lastUpdate = -1.0;
};

struct FpsStats {
    float current = 0.0f;
    float average = 0.0f;
    float minimum = 9999.0f;
    float maximum = 0.0f;
    double sum = 0.0;
    unsigned int samples = 0;
    int seenResetSerial = 0;
    bool comboWasDown = false;
};

PerfMetrics gPerf;
FpsStats gFps;

#if defined(__linux__)
unsigned long long gPrevCpuTotal = 0;
unsigned long long gPrevCpuIdle = 0;
unsigned long long gPrevProcTicks = 0;

static bool ReadTextFile(const std::string& path, std::string& out) {
    std::ifstream file(path);
    if (!file.good()) {
        return false;
    }
    std::ostringstream ss;
    ss << file.rdbuf();
    out = ss.str();
    return true;
}

static bool ReadSystemCpu(unsigned long long& total, unsigned long long& idle) {
    std::ifstream file("/proc/stat");
    if (!file.good()) {
        return false;
    }

    std::string cpu;
    unsigned long long user = 0, nice = 0, system = 0, idleTime = 0, iowait = 0, irq = 0, softirq = 0, steal = 0;
    file >> cpu >> user >> nice >> system >> idleTime >> iowait >> irq >> softirq >> steal;
    if (cpu != "cpu") {
        return false;
    }

    idle = idleTime + iowait;
    total = user + nice + system + idleTime + iowait + irq + softirq + steal;
    return total > 0;
}

static bool ReadProcessCpu(unsigned long long& procTicks) {
    std::string stat;
    if (!ReadTextFile("/proc/self/stat", stat)) {
        return false;
    }

    size_t endName = stat.rfind(')');
    if (endName == std::string::npos || endName + 2 >= stat.size()) {
        return false;
    }

    std::istringstream ss(stat.substr(endName + 2));
    std::vector<std::string> fields;
    std::string field;
    while (ss >> field) {
        fields.push_back(field);
    }

    // After the comm field, index 0 is field 3 (state). utime/stime are fields 14/15 -> indices 11/12.
    if (fields.size() <= 12) {
        return false;
    }

    procTicks = std::strtoull(fields[11].c_str(), nullptr, 10) + std::strtoull(fields[12].c_str(), nullptr, 10);
    return true;
}

static bool ReadMemory(unsigned long long& appRamMb, unsigned long long& totalRamMb, float& usedPct) {
    unsigned long long totalKb = 0;
    unsigned long long availableKb = 0;

    std::ifstream meminfo("/proc/meminfo");
    if (meminfo.good()) {
        std::string key;
        unsigned long long value = 0;
        std::string unit;
        while (meminfo >> key >> value >> unit) {
            if (key == "MemTotal:") {
                totalKb = value;
            } else if (key == "MemAvailable:") {
                availableKb = value;
            }
        }
    }

    std::ifstream statm("/proc/self/statm");
    unsigned long long residentPages = 0;
    if (statm.good()) {
        unsigned long long sizePages = 0;
        statm >> sizePages >> residentPages;
    }

    long pageSize = sysconf(_SC_PAGESIZE);
    if (pageSize <= 0) {
        pageSize = 4096;
    }

    appRamMb = (residentPages * static_cast<unsigned long long>(pageSize)) / (1024ULL * 1024ULL);
    totalRamMb = totalKb / 1024ULL;
    usedPct = (totalKb > 0 && availableKb <= totalKb) ? ((float)(totalKb - availableKb) * 100.0f / (float)totalKb) : -1.0f;
    return totalKb > 0;
}

static bool ParseLeadingPercent(const std::string& text, float& percent) {
    const char* s = text.c_str();
    while (*s != '\0' && std::isspace(static_cast<unsigned char>(*s))) {
        s++;
    }

    char* end = nullptr;
    float value = std::strtof(s, &end);
    if (end == s) {
        return false;
    }

    // Some kernels expose GPU load as 0-100, others as 0-1000 permille.
    if (value > 100.0f && value <= 1000.0f) {
        value /= 10.0f;
    }
    value = std::max(0.0f, std::min(100.0f, value));
    percent = value;
    return true;
}

static bool TryReadGpuLoadFile(const std::string& path, float& gpuPct) {
    std::string text;
    return ReadTextFile(path, text) && ParseLeadingPercent(text, gpuPct);
}

static std::string Lower(std::string text) {
    for (char& c : text) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return text;
}

static bool ReadGpuPercent(float& gpuPct) {
    const char* commonPaths[] = {
        "/sys/class/devfreq/fde60000.gpu/load",
        "/sys/class/devfreq/fb000000.gpu/load",
        "/sys/class/devfreq/gpu/load",
        "/sys/class/misc/mali0/device/utilization",
    };

    for (const char* path : commonPaths) {
        if (TryReadGpuLoadFile(path, gpuPct)) {
            return true;
        }
    }

    DIR* dir = opendir("/sys/class/devfreq");
    if (dir == nullptr) {
        return false;
    }

    bool found = false;
    struct dirent* ent = nullptr;
    while ((ent = readdir(dir)) != nullptr) {
        std::string name = ent->d_name;
        std::string lower = Lower(name);
        if (lower == "." || lower == "..") {
            continue;
        }
        if (lower.find("gpu") == std::string::npos && lower.find("mali") == std::string::npos) {
            continue;
        }

        std::string base = std::string("/sys/class/devfreq/") + name;
        if (TryReadGpuLoadFile(base + "/load", gpuPct) || TryReadGpuLoadFile(base + "/utilization", gpuPct)) {
            found = true;
            break;
        }
    }
    closedir(dir);
    return found;
}

static bool ReadThermalC(float& tempC) {
    DIR* dir = opendir("/sys/class/thermal");
    if (dir == nullptr) {
        return false;
    }

    bool found = false;
    struct dirent* ent = nullptr;
    while ((ent = readdir(dir)) != nullptr) {
        std::string name = ent->d_name;
        if (name.find("thermal_zone") != 0) {
            continue;
        }

        std::string text;
        if (!ReadTextFile(std::string("/sys/class/thermal/") + name + "/temp", text)) {
            continue;
        }

        float value = std::strtof(text.c_str(), nullptr);
        if (value > 1000.0f) {
            value /= 1000.0f;
        }

        if (value >= 10.0f && value <= 120.0f) {
            tempC = value;
            found = true;
            break;
        }
    }

    closedir(dir);
    return found;
}
#endif

static void ResetFpsStats() {
    gFps.average = 0.0f;
    gFps.minimum = 9999.0f;
    gFps.maximum = 0.0f;
    gFps.sum = 0.0;
    gFps.samples = 0;
}

static bool ResetComboPressed() {
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

static void UpdateFpsStats(float fps) {
    int resetSerial = CVarGetInteger(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.ResetStats"), 0);
    if (resetSerial != gFps.seenResetSerial || ResetComboPressed()) {
        gFps.seenResetSerial = resetSerial;
        ResetFpsStats();
    }

    if (fps <= 0.0f || fps > 1000.0f) {
        return;
    }

    gFps.current = fps;
    gFps.minimum = std::min(gFps.minimum, fps);
    gFps.maximum = std::max(gFps.maximum, fps);
    gFps.sum += fps;
    gFps.samples++;
    gFps.average = (gFps.samples > 0) ? (float)(gFps.sum / (double)gFps.samples) : fps;
}

static void UpdatePerfMetrics() {
    double now = ImGui::GetTime();
    if (gPerf.lastUpdate >= 0.0 && (now - gPerf.lastUpdate) < 0.50) {
        return;
    }
    gPerf.lastUpdate = now;

#if defined(__linux__)
    unsigned long long cpuTotal = 0, cpuIdle = 0, procTicks = 0;
    if (ReadSystemCpu(cpuTotal, cpuIdle) && ReadProcessCpu(procTicks)) {
        if (gPrevCpuTotal != 0 && cpuTotal > gPrevCpuTotal) {
            unsigned long long totalDelta = cpuTotal - gPrevCpuTotal;
            unsigned long long idleDelta = cpuIdle - gPrevCpuIdle;
            unsigned long long procDelta = procTicks - gPrevProcTicks;

            gPerf.cpuTotal = totalDelta > 0 ? ((float)(totalDelta - idleDelta) * 100.0f / (float)totalDelta) : -1.0f;
            gPerf.appCpu = totalDelta > 0 ? ((float)procDelta * 100.0f / (float)totalDelta) : -1.0f;
        }
        gPrevCpuTotal = cpuTotal;
        gPrevCpuIdle = cpuIdle;
        gPrevProcTicks = procTicks;
    }

    ReadMemory(gPerf.appRamMb, gPerf.totalRamMb, gPerf.ramUsedPct);

    float gpu = -1.0f;
    gPerf.gpuPct = ReadGpuPercent(gpu) ? gpu : -1.0f;

    float temp = -1.0f;
    gPerf.tempC = ReadThermalC(temp) ? temp : -1.0f;
#endif
}

static void PlaceOverlayWindow() {
    int corner = CVarGetInteger(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.Corner"), 1);
    if (corner < 0 || corner > 3) {
        corner = 1;
    }

    const float margin = 4.0f;
    ImVec2 display = ImGui::GetIO().DisplaySize;
    ImVec2 size = ImGui::GetWindowSize();
    if (size.x < 40.0f) {
        size.x = 170.0f;
    }
    if (size.y < 20.0f) {
        size.y = 54.0f;
    }

    ImVec2 pos;
    pos.x = (corner == 1 || corner == 3) ? std::max(margin, display.x - size.x - margin) : margin;
    pos.y = (corner == 2 || corner == 3) ? std::max(margin, display.y - size.y - margin) : margin;
    ImGui::SetWindowPos(pos, ImGuiCond_Always);
}

static float OverlayScale() {
    float scale = CVarGetFloat(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.Scale"), 0.78f);
    if (scale < 0.65f) {
        scale = 0.65f;
    } else if (scale > 1.05f) {
        scale = 1.05f;
    }
    return scale;
}

static void TextPercentOrDash(const char* label, float value) {
    if (value >= 0.0f) {
        ImGui::Text("%s %.0f%%", label, value);
    } else {
        ImGui::Text("%s --", label);
    }
}

} // namespace

void SohStatsWindow::DrawElement() {
    const float fps = ImGui::GetIO().Framerate;
    const float frameMs = ImGui::GetIO().DeltaTime * 1000.0f;
    UpdateFpsStats(fps);
    UpdatePerfMetrics();
    PlaceOverlayWindow();

    ImGui::SetWindowFontScale(OverlayScale());
    ImGui::SetWindowBgAlpha(0.42f);

    const bool detailed = CVarGetInteger(CVAR_ENHANCEMENT("Graphics.PerformanceOverlay.Detailed"), 0) != 0;
    const float fpsMin = (gFps.samples > 0) ? gFps.minimum : 0.0f;
    const float fpsMax = (gFps.samples > 0) ? gFps.maximum : 0.0f;

    ImGui::Text("FPS %.1f A%.1f", gFps.current, gFps.average);
    ImGui::Text("L%.1f H%.1f %.1fms", fpsMin, fpsMax, frameMs);

    if (!detailed) {
        if (gPerf.cpuTotal >= 0.0f) {
            ImGui::Text("CPU %.0f%% APP %.0f%%", gPerf.cpuTotal, std::max(0.0f, gPerf.appCpu));
        } else {
            ImGui::TextUnformatted("CPU -- APP --");
        }

        if (gPerf.gpuPct >= 0.0f && gPerf.tempC >= 0.0f) {
            ImGui::Text("RAM %lluM GPU %.0f%% %.0fC", gPerf.appRamMb, gPerf.gpuPct, gPerf.tempC);
        } else if (gPerf.gpuPct >= 0.0f) {
            ImGui::Text("RAM %lluM GPU %.0f%%", gPerf.appRamMb, gPerf.gpuPct);
        } else if (gPerf.tempC >= 0.0f) {
            ImGui::Text("RAM %lluM GPU -- %.0fC", gPerf.appRamMb, gPerf.tempC);
        } else {
            ImGui::Text("RAM %lluM GPU --", gPerf.appRamMb);
        }
        return;
    }

    TextPercentOrDash("CPU", gPerf.cpuTotal);
    TextPercentOrDash("APP", gPerf.appCpu);
    if (gPerf.ramUsedPct >= 0.0f) {
        ImGui::Text("RAM %lluM %.0f%%", gPerf.appRamMb, gPerf.ramUsedPct);
    } else {
        ImGui::Text("RAM %lluM", gPerf.appRamMb);
    }
    TextPercentOrDash("GPU", gPerf.gpuPct);
    if (gPerf.tempC >= 0.0f) {
        ImGui::Text("TMP %.0fC", gPerf.tempC);
    }
    ImGui::TextUnformatted("RST L1+R1+Y");
}
''')
print('Compact CPU/RAM/GPU/FPS overlay implementation: applied')


# --------------------------------------------------------------------------------------
# 4) Track per-texture mipmap generation state in the OpenGL backend.
# --------------------------------------------------------------------------------------
h = LUS / 'include' / 'fast' / 'backends' / 'gfx_opengl.h'
s = h.read_text()
old_texture_info = '''struct TextureInfo {
    uint16_t width;
    uint16_t height;
    uint16_t filtering;
};
'''
new_texture_info = '''struct TextureInfo {
    uint16_t width;
    uint16_t height;
    uint16_t filtering;
    bool hasMipmaps = false;
};
'''
s = replace_once(s, old_texture_info, new_texture_info, 'TextureInfo mipmap state')
h.write_text(s)


# --------------------------------------------------------------------------------------
# 5) Make OpenGL/GLES generate mipmaps only when enabled by the menu CVar.
# --------------------------------------------------------------------------------------
p = LUS / 'src' / 'fast' / 'backends' / 'gfx_opengl.cpp'
s = p.read_text()

namespace_marker = 'namespace Fast {\n'
helpers = r'''namespace {
constexpr const char* kTextureMipmapsEnabledCVar = "gEnhancements.Graphics.TextureMipmaps.Enabled";
constexpr const char* kTextureMipmapsBiasCVar = "gEnhancements.Graphics.TextureMipmaps.Bias";
constexpr const char* kTextureMipmapsLogCVar = "gDeveloperTools.TextureMipmaps.LogUploads";
int sMipmapLogCount = 0;

bool TextureMipmapsEnabled() {
    return Ship::Context::GetInstance()->GetConsoleVariables()->GetInteger(kTextureMipmapsEnabledCVar, 0) != 0;
}

float TextureMipmapBias() {
    float bias = Ship::Context::GetInstance()->GetConsoleVariables()->GetFloat(kTextureMipmapsBiasCVar, 0.0f);
    if (bias < -1.0f) {
        bias = -1.0f;
    } else if (bias > 2.0f) {
        bias = 2.0f;
    }
    return bias;
}

bool TextureMipmapLogUploads() {
    return Ship::Context::GetInstance()->GetConsoleVariables()->GetInteger(kTextureMipmapsLogCVar, 0) != 0;
}

void GenerateTextureMipmapsIfNeeded(TextureInfo& info) {
    if (!TextureMipmapsEnabled() || info.hasMipmaps || (info.width <= 1 && info.height <= 1)) {
        return;
    }

    glGenerateMipmap(GL_TEXTURE_2D);
    info.hasMipmaps = true;

#ifdef GL_TEXTURE_LOD_BIAS
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_LOD_BIAS, TextureMipmapBias());
#endif

    if (TextureMipmapLogUploads() && sMipmapLogCount < 32) {
        SPDLOG_INFO("[SOH-MIPMAP] generated {}x{} bias={}", info.width, info.height, TextureMipmapBias());
        sMipmapLogCount++;
    }
}
} // namespace

'''

if helpers not in s:
    if namespace_marker not in s:
        raise SystemExit('mipmap patch failed: namespace Fast marker not found')
    s = s.replace(namespace_marker, namespace_marker + helpers, 1)

old_upload = '''void GfxRenderingAPIOGL::UploadTexture(const uint8_t* rgba32_buf, uint32_t width, uint32_t height) {
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgba32_buf);
    textures[mCurrentTextureIds[mCurrentTile]].width = width;
    textures[mCurrentTextureIds[mCurrentTile]].height = height;
}
'''

new_upload = '''void GfxRenderingAPIOGL::UploadTexture(const uint8_t* rgba32_buf, uint32_t width, uint32_t height) {
    if (width == 0 || height == 0) {
        return;
    }

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgba32_buf);

    TextureInfo& info = textures[mCurrentTextureIds[mCurrentTile]];
    info.width = width;
    info.height = height;
    info.hasMipmaps = false;
    GenerateTextureMipmapsIfNeeded(info);
}
'''
s = replace_once(s, old_upload, new_upload, 'Texture upload mipmap generation')

old_sampler_line = '    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);\n    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);'
new_sampler_line = '''    TextureInfo& info = textures[mCurrentTextureIds[tile]];
    GenerateTextureMipmapsIfNeeded(info);

    const bool useMipmaps = TextureMipmapsEnabled();
    const GLint minFilter = useMipmaps ? (filter == GL_LINEAR ? GL_LINEAR_MIPMAP_LINEAR : GL_NEAREST_MIPMAP_NEAREST)
                                      : filter;

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
#ifdef GL_TEXTURE_LOD_BIAS
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_LOD_BIAS, useMipmaps ? TextureMipmapBias() : 0.0f);
#endif'''
s = replace_once(s, old_sampler_line, new_sampler_line, 'Texture sampler mipmap filter')
p.write_text(s)

print('Performance patch completed')
