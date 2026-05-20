#!/usr/bin/env python3
"""
Externalize GameMaker 2zoq textures and shrink the data.win.
"""

import argparse
import bz2
import mmap
import struct
import subprocess
import tempfile
from pathlib import Path


ZOQ_MAGIC = b"2zoq"
QOIF_MAGIC_YYG = b"fioq"


# ---------- TXTR chunk lookup ----------

def find_txtr(buf: memoryview) -> tuple[int, int]:
    """Return (payload_start, payload_size) of the TXTR chunk in a FORM/IFF file."""
    if bytes(buf[:4]) != b"FORM":
        raise SystemExit("Not a GMS data file (missing FORM header).")
    i = 8
    while i < len(buf):
        cname = bytes(buf[i:i+4])
        csize = struct.unpack_from("<I", buf, i+4)[0]
        if cname == b"TXTR":
            return i+8, csize
        i += 8 + csize
    raise SystemExit("No TXTR chunk in input.")


# ---------- Sequential 2zoq blob walker ----------

def find_next_zoq(fp, start: int, end: int) -> int:
    """Return the file offset of the next ZOQ_MAGIC in [start, end), or -1."""
    pos = start
    carry = b""
    while pos < end:
        fp.seek(pos)
        n = min(1 << 22, end - pos)  # 4MB scan window
        data = carry + fp.read(n)
        i = data.find(ZOQ_MAGIC)
        if i >= 0:
            return pos - len(carry) + i
        carry = data[-3:] if len(data) >= 3 else data
        pos += n
    return -1


def parse_2zoq_at(fp, off: int, end: int) -> tuple[bytes, int] | None:
    """
    Parse the 2zoq blob at `off`. On success return (decompressed_qoif, blob_len).
    Returns None on false-positive magic or invalid bz2 stream. Concatenates
    multiple bz2 streams when YYG split a single QOIF across them.
    """
    fp.seek(off + 8)
    decomp_size = struct.unpack("<I", fp.read(4))[0]

    qoif = bytearray()
    consumed = 0
    while len(qoif) < decomp_size:
        decomp = bz2.BZ2Decompressor()
        while not decomp.eof:
            remaining = end - (off + 12 + consumed)
            if remaining <= 0:
                return bytes(qoif), 12 + consumed if qoif else None
            chunk = fp.read(min(1 << 16, remaining))
            if not chunk:
                break
            try:
                qoif += decomp.decompress(chunk)
            except OSError:
                return None if not qoif else (bytes(qoif), 12 + consumed)
            consumed += len(chunk)
        if not decomp.eof:
            break
        unused = decomp.unused_data
        if unused:
            fp.seek(off + 12 + consumed - len(unused))
            consumed -= len(unused)
    return bytes(qoif), 12 + consumed


# ---------- YYG-QOIF decoder ----------


def _sx(value: int, bits: int) -> int:
    """Sign-extend a `bits`-wide unsigned value to a signed int."""
    mask = (1 << bits) - 1
    value &= mask
    if value & (1 << (bits - 1)):
        return value - (1 << bits)
    return value


def _yyg_hash(p: int) -> int:
    """XOR-fold the 4 channel bytes, take low 6 bits."""
    return (p ^ (p >> 8) ^ (p >> 16) ^ (p >> 24)) & 0x3F


def qoi_decode(buf: bytes) -> tuple[int, int, bytearray]:
    if buf[:4] != QOIF_MAGIC_YYG:
        raise ValueError(f"QOIF magic mismatch: got {buf[:4]!r}")
    width = struct.unpack_from("<H", buf, 4)[0]
    height = struct.unpack_from("<H", buf, 6)[0]
    if width == 0 or height == 0:
        return width, height, bytearray()

    p = 12
    total_px = width * height
    out = bytearray(total_px * 4)
    out_pos = 0

    pixel = 0xFF000000          # opaque black: A=0xFF, RGB=0
    index = [0] * 64
    n_px = 0
    buf_len = len(buf)

    while n_px < total_px and p < buf_len:
        b1 = buf[p]; p += 1
        run = 0
        update_cache = True

        if b1 < 0x40:
            # INDEX: pixel already at index[b1], skip the cache rewrite.
            pixel = index[b1]
            update_cache = False
        elif b1 < 0x60:
            # RUN: store 1 + (b1 & 0x1F) additional, pixel unchanged.
            run = b1 & 0x1F
            update_cache = False
        elif b1 < 0x80:
            # BIG_RUN: 1 + ((b1 & 0x1F) << 8 | b2) + 32 additional, pixel unchanged.
            b2 = buf[p]; p += 1
            run = ((b1 & 0x1F) << 8 | b2) + 32
            update_cache = False
        elif b1 < 0xC0:
            # DIFF: 3 signed 2-bit deltas, alpha unchanged.
            dR = _sx((b1 >> 4) & 0x3, 2)
            dG = _sx((b1 >> 2) & 0x3, 2)
            dB = _sx( b1       & 0x3, 2)
            R = ((pixel       & 0xFF) + dR) & 0xFF
            G = (((pixel >> 8)  & 0xFF) + dG) & 0xFF
            B = (((pixel >> 16) & 0xFF) + dB) & 0xFF
            A =  (pixel >> 24) & 0xFF
            pixel = R | (G << 8) | (B << 16) | (A << 24)
        elif b1 < 0xE0:
            # LUMA1: 5-bit R delta in b1, 4-bit G/B deltas in b2, alpha unchanged.
            b2 = buf[p]; p += 1
            dR = _sx(b1 & 0x1F, 5)
            dG = _sx((b2 >> 4) & 0xF, 4)
            dB = _sx( b2       & 0xF, 4)
            R = ((pixel       & 0xFF) + dR) & 0xFF
            G = (((pixel >> 8)  & 0xFF) + dG) & 0xFF
            B = (((pixel >> 16) & 0xFF) + dB) & 0xFF
            A =  (pixel >> 24) & 0xFF
            pixel = R | (G << 8) | (B << 16) | (A << 24)
        elif b1 < 0xF0:
            # LUMA2: 4-channel deltas, payload bits scattered:
            #   dR (5 bits): bit 7 of b2 + bits 0-3 of b1; sign from b1[3]
            #   dG (-16..+15): signed_7bit(b2 & 0x7F) // 4
            #   dB (-16..+15): signed_10bit((b2 & 0x3) << 8 | b3) // 32
            #   dA (5 bits): signed_5bit(b3 & 0x1F)
            # b2[0..1] feeds both dG (low) and dB (high). b3[0..4] feeds dB and dA.
            b2 = buf[p]; p += 1
            b3 = buf[p]; p += 1
            dR = _sx(((b1 & 0xF) << 1) | ((b2 >> 7) & 1), 5)
            dG = _sx(b2 & 0x7F, 7) // 4
            dB = _sx(((b2 & 0x3) << 8) | b3, 10) // 32
            dA = _sx(b3 & 0x1F, 5)
            R = ((pixel        & 0xFF) + dR) & 0xFF
            G = (((pixel >> 8)  & 0xFF) + dG) & 0xFF
            B = (((pixel >> 16) & 0xFF) + dB) & 0xFF
            A = (((pixel >> 24) & 0xFF) + dA) & 0xFF
            pixel = R | (G << 8) | (B << 16) | (A << 24)
        else:
            # CHAN: low nibble = R/G/B/A mask. Read 1 byte per set bit, in order.
            mask = b1 & 0x0F
            R =  pixel        & 0xFF
            G = (pixel >> 8)  & 0xFF
            B = (pixel >> 16) & 0xFF
            A = (pixel >> 24) & 0xFF
            if mask & 0x8: R = buf[p]; p += 1
            if mask & 0x4: G = buf[p]; p += 1
            if mask & 0x2: B = buf[p]; p += 1
            if mask & 0x1: A = buf[p]; p += 1
            pixel = R | (G << 8) | (B << 16) | (A << 24)

        if update_cache:
            index[_yyg_hash(pixel)] = pixel
        struct.pack_into("<I", out, out_pos, pixel)
        out_pos += 4
        n_px += 1
        for _ in range(run):
            if n_px >= total_px: break
            struct.pack_into("<I", out, out_pos, pixel)
            out_pos += 4
            n_px += 1

    if n_px != total_px:
        print(f"  WARN: decoded {n_px}/{total_px} pixels, consumed {p}/{buf_len} bytes")
    return width, height, out


# ---------- ASTC compression via astcenc ----------

# PVR3 format codes the gmloader-next texhack accepts. Smaller block = higher
# quality, more VRAM; larger block = more compression, less VRAM. Memory cost
# per pixel: 4x4 = 1.00 byte, 5x5 = 0.64 byte, 6x6 = 0.44 byte, 8x8 = 0.25 byte.
ASTC_FORMATS = {
    "4x4": 0x1B,
    "5x5": 0x1D,
    "6x6": 0x1F,
}

def _write_tga_rgba(path: Path, rgba, w: int, h: int) -> None:
    """Top-left-origin uncompressed 32bpp TGA (type 2, descriptor 0x28). Streams
    row-by-row -- peak Python overhead is one row of swap buffer (w*4 bytes),
    not a full image copy."""
    hdr = bytearray(18)
    hdr[2] = 2
    struct.pack_into("<HH", hdr, 12, w, h)
    hdr[16] = 32
    hdr[17] = 0x28
    stride = w * 4
    row_swap = bytearray(stride)
    src = memoryview(rgba)
    with open(path, "wb") as f:
        f.write(hdr)
        for y in range(h):
            row = src[y*stride:(y+1)*stride]
            row_swap[0::4] = row[2::4]   # B
            row_swap[1::4] = row[1::4]   # G
            row_swap[2::4] = row[0::4]   # R
            row_swap[3::4] = row[3::4]   # A
            f.write(row_swap)


def astc_compress_tga(tga: Path, astc_out: Path, astcenc: str, quality: str,
                       block: str) -> bytes:
    """Run astcenc on a written TGA, return raw ASTC payload (header stripped)."""
    subprocess.run(
        [astcenc, "-cs", str(tga), str(astc_out), block, quality, "-silent"],
        check=True,
    )
    data = astc_out.read_bytes()
    if data[:4] != b"\x13\xAB\xA1\x5C":
        raise RuntimeError("Unexpected astc header magic")
    return data[16:]


# ---------- PVR3 wrapper ----------

def pvr3_wrap_astc(payload: bytes, width: int, height: int, block: str) -> bytes:
    """Wrap an ASTC payload in a PVR v3 header. Format code depends on block size."""
    format_code = ASTC_FORMATS[block]
    return struct.pack(
        "<IIQIIIIIIIII",
        0x03525650,  # Version
        0,           # Flags
        format_code,
        0,           # ColourSpace
        0,           # ChannelType
        height,
        width,
        1,           # Depth
        1,           # NumSurfaces
        1,           # NumFaces
        1,           # MipCount
        0,           # MetadataSize
    ) + payload


# ---------- 2zoq stub ----------

def build_2zoq_stub(idx: int) -> bytes:
    """
    Minimum 2zoq blob (~60-70B) whose decoded image is 2x1 RGBA: pixel0 =
    DE AD BE FF (the texhack magic gmloader-next looks for), pixel1 = idx
    encoded in the low 24 bits of RGB.
    """
    qoif = bytearray(QOIF_MAGIC_YYG)
    qoif += struct.pack("<HH", 2, 1)
    qoif += b"\x04\x00\x00\x00"
    qoif += bytes([0xFF, 0xDE, 0xAD, 0xBE, 0xFF])
    qoif += bytes([0xFF, idx & 0xFF, (idx >> 8) & 0xFF, (idx >> 16) & 0xFF, 0xFF])
    qoif += b"\x00" * 7 + b"\x01"
    bz = bz2.compress(bytes(qoif), 9)
    header = bytearray(ZOQ_MAGIC)
    header += struct.pack("<HH", 2, 1)
    header += struct.pack("<I", len(qoif))
    return bytes(header) + bz


# ---------- TXTR compactor ----------

def compact_txtr(f, txtr_start: int, txtr_size: int,
                 stubs_by_idx: dict[int, bytes]) -> int:
    """
    Repack the TXTR chunk: keep the header + entry table at their original
    positions, pack stubs right after the last entry, update each entry's
    BlobOffset / BlobSize, shift the tail of the file up, and truncate.
    Returns the new total file size.

    Requires every texture index from 0 to count-1 to be in stubs_by_idx.
    """
    f.seek(txtr_start)
    count = struct.unpack("<I", f.read(4))[0]
    if set(stubs_by_idx.keys()) != set(range(count)):
        raise SystemExit(
            f"Need a stub for every texture; have {sorted(stubs_by_idx)} of {count}.")

    ptrs = list(struct.unpack(f"<{count}I", f.read(count * 4)))
    # Each TextureEntry is u32 [Scaled, _, BlobSize, BlobOffset].
    entries = []
    for ptr in ptrs:
        f.seek(ptr)
        entries.append(list(struct.unpack("<IIII", f.read(16))))

    entries_end = max(ptrs) + 16
    blob_cursor = entries_end
    for i in range(count):
        stub = stubs_by_idx[i]
        entries[i][2] = len(stub)
        entries[i][3] = blob_cursor
        blob_cursor += len(stub)
    new_payload_size = blob_cursor - txtr_start

    if new_payload_size > txtr_size:
        raise SystemExit("Compact would grow TXTR; not safe.")

    f.seek(txtr_start + txtr_size)
    tail = f.read()

    # Rewrite chunk size, entry fields, packed stubs; shift tail; truncate.
    f.seek(txtr_start - 4)
    f.write(struct.pack("<I", new_payload_size))
    for i, ptr in enumerate(ptrs):
        f.seek(ptr)
        f.write(struct.pack("<IIII", *entries[i]))
    f.seek(entries_end)
    for i in range(count):
        f.write(stubs_by_idx[i])
    new_tail_start = txtr_start + new_payload_size
    f.seek(new_tail_start)
    f.write(tail)
    new_total = new_tail_start + len(tail)
    f.truncate(new_total)
    # FORM size header at file offset 4.
    f.seek(4)
    f.write(struct.pack("<I", new_total - 8))
    return new_total


# ---------- main loop ----------

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    ap.add_argument("data_win", type=Path)
    ap.add_argument("out_dir", type=Path, help="Where <idx>.pvr files are written.")
    ap.add_argument("--astcenc", default="astcenc-native", help="Path to astcenc binary.")
    ap.add_argument("--quality", default="-medium", help="astcenc preset (-fast / -medium / -thorough).")
    ap.add_argument("--block", choices=sorted(ASTC_FORMATS.keys()), default="4x4",
                    help="ASTC block size. Smaller = higher quality + more VRAM; larger = less VRAM.")
    ap.add_argument("--tmpdir", default=None, help="Scratch directory for astcenc TGA input (default: system tmp).")
    args = ap.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    size = args.data_win.stat().st_size

    with open(args.data_win, "r+b") as f:
        with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
            txtr_start, txtr_size = find_txtr(memoryview(mm))
        txtr_end = txtr_start + txtr_size
        print(f"TXTR chunk: offset=0x{txtr_start:x}  size={txtr_size} ({txtr_size/1048576:.1f} MB)")

        stubs_by_idx: dict[int, bytes] = {}
        idx = 0
        scan_from = txtr_start
        while scan_from < txtr_end:
            off = find_next_zoq(f, scan_from, txtr_end)
            if off < 0:
                break
            parsed = parse_2zoq_at(f, off, txtr_end)
            if parsed is None:
                scan_from = off + 1
                continue
            qoif, blob_len = parsed
            if qoif[:4] != QOIF_MAGIC_YYG:
                scan_from = off + blob_len
                continue

            tex_w = struct.unpack_from("<H", qoif, 4)[0]
            tex_h = struct.unpack_from("<H", qoif, 6)[0]
            print(f"Texture {idx} ({tex_w}x{tex_h}): decoding...", flush=True)

            width, height, rgba = qoi_decode(qoif)
            del qoif

            # Free `rgba` (up to 256MB for 8K textures) once the TGA is on disk
            # so astcenc has the full memory budget for its own working set.
            with tempfile.TemporaryDirectory(dir=args.tmpdir) as tmp:
                tga = Path(tmp, "in.tga")
                astc_out = Path(tmp, "out.astc")
                print(f"Texture {idx} ({tex_w}x{tex_h}): writing scratch TGA...", flush=True)
                _write_tga_rgba(tga, rgba, width, height)
                del rgba
                print(f"Texture {idx} ({tex_w}x{tex_h}): ASTC {args.block} compressing...", flush=True)
                payload = astc_compress_tga(tga, astc_out, args.astcenc, args.quality, args.block)
            (args.out_dir / f"{idx}.pvr").write_bytes(
                pvr3_wrap_astc(payload, width, height, args.block))
            del payload
            stubs_by_idx[idx] = build_2zoq_stub(idx)
            print(f"Texture {idx} ({tex_w}x{tex_h}): done", flush=True)

            idx += 1
            scan_from = off + blob_len

        print(f"Found {idx} 2zoq textures.")
        new_size = compact_txtr(f, txtr_start, txtr_size, stubs_by_idx)
        print(f"Updated {args.data_win}: {size} -> {new_size} "
              f"({(size - new_size) / 1048576:.1f} MB saved)")


if __name__ == "__main__":
    main()
