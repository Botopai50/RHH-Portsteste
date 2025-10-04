#!/usr/bin/env python3
import argparse
import subprocess
from pathlib import Path

MIN_SIZE = 1024 * 1024  # 1 MB

def recompress_ogg(file_path, out_path, bitrate=0, downmix=False, resample=0, recompress=False):
    # Decode to WAV quietly
    wav_path = out_path.with_suffix(".wav")
    subprocess.run(
        ["oggdec", str(file_path), "-o", str(wav_path)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    # Encode back to OGG with chosen options
    cmd = ["oggenc", str(wav_path), "-o", str(out_path)]
    if bitrate > 0:
        cmd += ["-b", str(bitrate)]
    if downmix:
        cmd.append("--downmix")
    if resample > 0:
        cmd += ["--resample", str(resample)]

    # Run oggenc quietly
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Cleanup WAV
    wav_path.unlink(missing_ok=True)

def main():
    parser = argparse.ArgumentParser(description="Recompress OGG files in a LÖVE project")
    parser.add_argument("indir", help="Input directory (extracted .love folder)")
    parser.add_argument("-d", "--destdir", default="./recompressed", help="Destination directory")
    parser.add_argument("-m", "--minsize", default=MIN_SIZE, type=int, help="Minimum file size in bytes to target (default 1MB)")
    parser.add_argument("-b", "--bitrate", default=0, type=int, help="Nominal bitrate in kbps (oggenc -b). 0 = auto")
    parser.add_argument("-D", "--downmix", action="store_true", help="Downmix stereo to mono")
    parser.add_argument("-R", "--resample", default=0, type=int, help="Resample to n Hz (8000–48000). 0 = no change")
    parser.add_argument("-r", "--recompress", action="store_true", help="Allow recompressing OGG files")
    parser.add_argument("-y", "--yes", action="store_true", help="Overwrite without asking")
    args = parser.parse_args()

    indir = Path(args.indir)
    outdir = Path(args.destdir)
    outdir.mkdir(parents=True, exist_ok=True)

    ogg_files = list(indir.rglob("*.ogg"))
    total = len(ogg_files)

    for i, ogg_file in enumerate(ogg_files, start=1):
        rel_path = ogg_file.relative_to(indir)
        out_path = outdir / rel_path
        out_path.parent.mkdir(parents=True, exist_ok=True)

        if out_path.exists() and not args.yes:
            print(f"[{i}/{total}] Skipping {rel_path}, already exists")
            continue

        if ogg_file.stat().st_size < args.minsize and not args.recompress:
            print(f"[{i}/{total}] Skipping small file {rel_path} ({ogg_file.stat().st_size} bytes)")
            continue

        print(f"[{i}/{total}] Compressing {rel_path}")
        recompress_ogg(ogg_file, out_path, args.bitrate, args.downmix, args.resample, args.recompress)

if __name__ == "__main__":
    main()
