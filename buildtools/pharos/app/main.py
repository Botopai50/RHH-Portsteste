#!/usr/bin/env python3
"""
Pharos/main.py
Entrypoint to the Pharos companion app.
"""

import glob
import os
import sys
import zipfile

from config import DATA_DIR, INSTALL_DIR

def apply_pending_update() -> None:
    update_zip = os.path.join(DATA_DIR, ".pending_update.zip")
    if not os.path.exists(update_zip):
        print(f"[Update] No pending update at {update_zip}; skipping.")
        return
    print(f"[Update] Applying pending update from {update_zip} "
          f"(size {os.path.getsize(update_zip)} bytes)...")

    # The update zip mirrors the install layout. Extract one level above
    # the install dir so the launchscript and binary both get replaced.
    # Linux refuses to overwrite a running binary with O_TRUNC (ETXTBSY on
    # overlay-style filesystems used by ROCKNIX/Knulli/MuOS), so write each
    # entry to a sibling .tmp and os.replace() it onto the target. The
    # inode swap leaves the currently-running process undisturbed and the
    # new file is in place for the next launch.
    target = os.path.abspath(os.path.join(INSTALL_DIR, ".."))
    try:
        with zipfile.ZipFile(update_zip, "r") as zf:
            for entry in zf.infolist():
                dest = os.path.join(target, entry.filename)
                if entry.is_dir():
                    os.makedirs(dest, exist_ok=True)
                    continue
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                tmp = dest + ".tmp"
                with zf.open(entry, "r") as src, open(tmp, "wb") as dst:
                    while True:
                        chunk = src.read(64 * 1024)
                        if not chunk:
                            break
                        dst.write(chunk)
                # Preserve original mode bits (e.g. 0o755 on the binary).
                mode = (entry.external_attr >> 16) & 0o777
                if mode:
                    os.chmod(tmp, mode)
                os.replace(tmp, dest)
        os.remove(update_zip)
        print(f"[Update] Applied pending update to {target}.")
    except (zipfile.BadZipFile, OSError) as e:
        print(f"[Update] Failed to apply pending update: {e}", file=sys.stderr)
        # Drop the zip so we don't keep retrying a broken/partial download.
        try:
            os.remove(update_zip)
        except OSError:
            pass


apply_pending_update()

# Minimal CFWs (Knulli) ship Python without CA certs in OpenSSL's default
# search path, so HTTPS requests fail with CERTIFICATE_VERIFY_FAILED. Point
# urllib + ssl at our bundled certifi store before anything tries to fetch.
import certifi
os.environ.setdefault("SSL_CERT_FILE", certifi.where())
os.environ.setdefault("REQUESTS_CA_BUNDLE", certifi.where())

import sdl2

# Global log file descriptor
_log_fd = None

# ----------------------------------------------------------------------
# Logging setup
# ----------------------------------------------------------------------
def initialise_logging() -> None:
    global _log_fd
    log_dir = os.path.join(DATA_DIR, "logs")
    os.makedirs(log_dir, exist_ok=True)

    # Delete oldest logs if more than 5 exist
    log_files = sorted(glob.glob(os.path.join(log_dir, "*.txt")), key=os.path.getmtime)
    while len(log_files) >= 5:
        os.remove(log_files[0])
        log_files.pop(0)

    log_file = os.environ.get("LOG_FILE", os.path.join(log_dir, "log.txt"))
    try:
        _log_fd = open(log_file, "w", buffering=1)
        sys.stdout = sys.stderr = _log_fd
    except Exception as e:
        print(f"Failed to open log file {log_file}: {e}", file=sys.__stdout__)
        _log_fd = sys.__stdout__

# ----------------------------------------------------------------------
# Cleanup helper
# ----------------------------------------------------------------------
def cleanup(pharos_instance, exit_code: int) -> None:
    if pharos_instance:
        try:
            pharos_instance.cleanup()
        except Exception as e:
            print(f"Pharos cleanup error: {e}", file=sys.__stderr__)
        try:
            pharos_instance.ui.cleanup()
            pharos_instance.input.cleanup()
        except Exception as e:
            print(f"UI/Input cleanup error: {e}", file=sys.__stderr__)

    if _log_fd and not getattr(_log_fd, "closed", True):
        try:
            _log_fd.flush()
            _log_fd.close()
        except Exception:
            pass

    sdl2.SDL_Quit()

    os._exit(exit_code)

# ----------------------------------------------------------------------
# Main entry point
# ----------------------------------------------------------------------
def main() -> None:
    from pharos import Pharos

    initialise_logging()

    if sdl2.SDL_Init(sdl2.SDL_INIT_VIDEO | sdl2.SDL_INIT_GAMECONTROLLER) < 0:
        print(f"SDL2 init failed: {sdl2.SDL_GetError()}")
        sys.exit(1)

    pharos = None
    try:
        pharos = Pharos()
        pharos.start()

        # Optional: memory leak debug
        _check_leaks = lambda: None
        if os.getenv("DEBUG_MEMORY"):
            import tracemalloc
            tracemalloc.start(25)
            _snapshot = tracemalloc.take_snapshot()
            frame = 0
            def _check_leaks():
                nonlocal _snapshot, frame
                frame += 1
                if frame % 1000 == 0:
                    s = tracemalloc.take_snapshot()
                    stats = s.compare_to(_snapshot, 'lineno')
                    print("\n=== MEMORY GROWTH (top 5) ===")
                    for stat in stats[:5]:
                        print(stat)
                    _snapshot = s
            import atexit
            atexit.register(tracemalloc.stop)

        while pharos.running:
            _check_leaks()
            pharos.ui.draw_start()
            pharos.update()
            pharos.ui.render_to_screen()
            pharos.input.clear_pressed()
            sdl2.SDL_Delay(16)

    except KeyboardInterrupt:
        print("\nInterrupted by user.")
        cleanup(pharos, 0)
    except Exception as e:
        print(f"Unhandled exception: {e}")
        cleanup(pharos, 1)
    else:
        print("Exiting Pharos...")
        cleanup(pharos, 0)
    finally:
        if pharos is None and sdl2.SDL_WasInit(0):
            sdl2.SDL_Quit()

if __name__ == "__main__":
    main()