[Dusklight](https://github.com/TwilitRealm/dusklight) — TwilitRealm's unofficial native PC reimplementation of *The Legend of Zelda: Twilight Princess* — released this week. Only a narrow slice of retro handhelds can actually run it, and there's a specific reason for that: the **Aurora** framework it's built on is **Vulkan-only**. No OpenGL, no GLES, no shim like gl4es or zink. If your device doesn't expose a working Vulkan driver, this port doesn't launch.

That cuts out most of the catalog. Mali G31, G52, Bifrost, stock S922X drivers — all surface OpenGL ES, none surface Vulkan. The practical working set is:

- **RK3588** (Mali-G610) via Panfork or Panfrost+Vulkan
- **Snapdragon** (Adreno) via Turnip
- **Apple Silicon** via MoltenVK

Combined with a `min_glibc: "2.41"` floor, the port has the most aggressive hardware gate of anything I've come across. The `vulkan` and `ultra` filter chips on the port grid exist exactly for cases like this. You can narrow to the niche and see what's compatible.

Recently someone in the ROCKNIX Discord mentioned Dusklight refused to launch on ODROID-GO-Ultra (S922X) despite the device technically having Vulkan and Wayland support, and I went down a small rabbit hole out of curiosity. It turned out to be a copy-paste bug in upstream Dawn: [`SwapChainVk.cpp`](https://github.com/google/dawn/blob/v20260423.175430/src/dawn/native/vulkan/SwapChainVk.cpp#L668-L685) checks `InstanceExt::XlibSurface` in the `WaylandSurface` case (an obvious paste from the adjacent X11 case), the guard fails on a Wayland-only system, and execution falls through to the "unsupported" error. Already fixed upstream in [`google/dawn@7fd46625`](https://github.com/google/dawn/commit/7fd466253b15deb117b23b8b68f6e7d1d897cc4d). The port picks it up automatically once Aurora bumps `AURORA_DAWN_VERSION` past that commit, and TwilitRealm is already aware and planning the bump.

If you're on a handheld that doesn't meet the bar, **Courage Reborn** is worth keeping an eye on — an upcoming Twilight Princess port built on **Rainfall**, an in-house framework, not Aurora. Per chatter on the project's Discord it's targeting OpenGL rather than Vulkan, which would widen the API working set on paper. Don't get your hopes up too high though: Twilight Princess is a GC-era game, and for most weak retro handhelds the bottleneck isn't the GL/Vulkan question — it's raw CPU and GPU. Even with a permissive GLES path, an RK3326 or H700 isn't going to run TP at a playable frame rate. Rainfall is a complementary effort, not a magic compatibility unlock for the low end.
