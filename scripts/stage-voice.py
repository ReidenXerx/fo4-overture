#!/usr/bin/env python3
"""Stage Overture's voiced lines where the engine looks for them, with lip sync.

    python scripts/stage-voice.py                  # build/Overture.esp -> build/voice/
    python scripts/stage-voice.py --check          # report only, write nothing
    python scripts/stage-voice.py --esp <plugin> --rapport <fo4-rapport checkout>

The audio is rendered by fo4-rapport's pipeline (scripts/render-barks.py, the six
core voices). A render is named by LINE ID, because it cannot know a FormID. The
engine looks a line up by its INFO's FormID (fo4-rapport V-6):

    Sound/Voice/Overture.esp/<VoiceType>/<INFO & 0x00FFFFFF, 8 hex>_1.fuz

ESL-flagged plugins follow the same rule. It was measured on three shipped ESL mods,
where the ESL slot never appears in a file name.

THE MAP FROM LINE TO INFO IS READ FROM THE BUILT PLUGIN, not from the builder's
intent. Each INFO's NAM1, the spoken text, is matched to the bank line with exactly
that text. NAM1 is literal ASCII because the plugin is not localized, and no two
bank lines share a text. One line can be several INFOs (O-31's lover sets reuse
lines in other registers), and every one of them gets the file.

IT REFUSES, rather than stages:
- audio whose recorded words (fo4-rapport voice/render-manifest.json, "text") are
  not the bank's words now. This is O-6's failure, where 33 rewritten lines kept
  their old audio;
- audio with no recorded words at all, because what it says is unknown.

LIP SYNC. Overture's lines are ordinary dialogue, spoken outside Rapport's per-actor
face block, so unlike Rapport's pair barks (V-5) they need lip data. The game's own
LipGenerator makes it from a 44.1 kHz mono wav (scripts/make-lip.py). It runs ONE
AT A TIME: it writes tmp16khz.wav into its own folder, and two runs would share that
file. fo4-rapport's pcm-to-fuz.py --lip packs it into the .fuz. The lip header
matches a shipped mod's (01000000 .... 0d000000 ....0300). Whether a face actually
moves is verified only in game.
"""
import argparse
import hashlib
import importlib.util
import json
import pathlib
import struct
import subprocess
import sys
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PLUGIN = "Overture.esp"
COMPRESSED = 0x00040000


def subrecords(body):
    """[(signature, bytes)] in file order, honouring XXXX (a >64 KB field)."""
    out, o, big = [], 0, None
    while o < len(body):
        sig = body[o:o + 4].decode("ascii")
        n = struct.unpack_from("<H", body, o + 4)[0]
        o += 6
        if sig == "XXXX":
            big = struct.unpack_from("<I", body, o)[0]
            o += n
            continue
        if big is not None:
            n, big = big, None
        out.append((sig, body[o:o + n]))
        o += n
    return out


def read_infos(esp):
    """(formid, spoken text, is the player's line) for every INFO in the plugin."""
    found = []

    def walk(o, end):
        while o < end:
            sig = esp[o:o + 4]
            size = struct.unpack_from("<I", esp, o + 4)[0]
            if sig == b"GRUP":
                walk(o + 24, o + size)
                o += size
                continue
            if sig == b"INFO":
                flags, fid = struct.unpack_from("<II", esp, o + 8)
                body = esp[o + 24:o + 24 + size]
                if flags & COMPRESSED:
                    body = zlib.decompress(body[4:])
                fields = subrecords(body)
                spoken = [v for s, v in fields if s == "NAM1"]
                if len(spoken) > 1:
                    # Response 2 would be <id>_2.fuz. Nothing here writes one,
                    # and staging only _1 would silently leave it unvoiced.
                    raise SystemExit(f"INFO {fid:08X} has {len(spoken)} responses; "
                                     f"this stages response 1 only")
                text = spoken[0].split(b"\0")[0].decode("ascii") if spoken else ""
                found.append((fid, text, any(s == "RNAM" for s, _ in fields)))
            o += 24 + size

    walk(0, len(esp))
    return found


def wav_bytes(pcm):
    return (b"RIFF" + struct.pack("<I", 36 + len(pcm)) + b"WAVEfmt " +
            struct.pack("<IHHIIHH", 16, 1, 1, 44100, 88200, 2, 16) +
            b"data" + struct.pack("<I", len(pcm)) + pcm)


def load_make_lip():
    spec = importlib.util.spec_from_file_location("make_lip", ROOT / "scripts" / "make-lip.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def build_fuz(rapport, lip_tool, make_lip, vt, lid, text, work):
    """<work>/<vt>/<lid>.fuz with lip data, rebuilt only when the audio or the
    words changed. Returns its path."""
    pcm_path = rapport / "voice" / "pcm" / vt / f"{lid}.pcm"
    pcm = pcm_path.read_bytes()
    d = work / vt
    d.mkdir(parents=True, exist_ok=True)
    fuz, stamp_path = d / f"{lid}.fuz", d / f"{lid}.json"
    stamp = {"pcm_sha1": hashlib.sha1(pcm).hexdigest(), "text": text}
    if fuz.is_file() and stamp_path.is_file() and \
            json.loads(stamp_path.read_text(encoding="utf-8")) == stamp:
        return fuz
    wav = d / f"{lid}.wav"
    wav.write_bytes(wav_bytes(pcm))
    # The text drives the phoneme alignment, so it must be the line as SPOKEN:
    # Overture renders carry no audio tag, so that is the bank text itself.
    lip = make_lip.one(lip_tool, wav, text)
    r = subprocess.run([sys.executable, str(rapport / "scripts" / "pcm-to-fuz.py"),
                        str(pcm_path), str(fuz), "--pcm", "--lip", str(lip)],
                       capture_output=True, text=True)
    # The artifact, not the exit code: xwmaencode has exited 0 having written nothing.
    if not fuz.is_file() or fuz.read_bytes()[:4] != b"FUZE":
        raise RuntimeError(f"no .fuz for {vt}/{lid}: {(r.stderr or r.stdout).strip()[:200]}")
    lip_len = struct.unpack_from("<I", fuz.read_bytes(), 8)[0]
    if lip_len == 0:
        raise RuntimeError(f"{vt}/{lid}.fuz was packed without its lip data")
    stamp_path.write_text(json.dumps(stamp), encoding="utf-8")
    wav.unlink(missing_ok=True)
    return fuz


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--esp", default=str(ROOT / "build" / PLUGIN))
    ap.add_argument("--rapport", default=str(ROOT.parent / "fo4-rapport"),
                    help="the fo4-rapport checkout holding voice/out, voice/pcm and the manifest")
    ap.add_argument("--out", default=str(ROOT / "build" / "voice"),
                    help="the folder that becomes the mod's root: Sound/Voice/... goes inside")
    ap.add_argument("--lipgen", default=None, help="path to LipGenerator.exe")
    ap.add_argument("--check", action="store_true", help="report only, write nothing")
    a = ap.parse_args()

    rapport = pathlib.Path(a.rapport)
    esp = pathlib.Path(a.esp).read_bytes()
    bank = json.loads((ROOT / "voice" / "lines.json").read_text(encoding="utf-8"))["lines"]
    line_of = {ln["text"]: ln["id"] for ln in bank}
    if len(line_of) != len(bank):
        raise SystemExit("two bank lines share a text: a spoken text no longer names one line")
    doc = json.loads((rapport / "voice" / "render-manifest.json").read_text(encoding="utf-8"))
    said = doc.get("text", {})

    infos = read_infos(esp)
    player = [i for i in infos if i[2]]
    # "..." and the like: a line with no word in it is silent by design (the
    # fallbacks), not a line somebody forgot to voice.
    npc = [i for i in infos if not i[2] and any(c.isalpha() for c in i[1])]
    silent = [i for i in infos if not i[2] and not any(c.isalpha() for c in i[1])]
    registry, unmatched = {}, []
    for fid, text, _ in npc:
        lid = line_of.get(text)
        if lid is None:
            unmatched.append((fid, text))
        else:
            registry[f"{fid:08X}"] = {"line": lid, "file": f"{fid & 0x00FFFFFF:08X}_1.fuz"}
    lines_used = sorted({e["line"] for e in registry.values()})
    text_of = {ln["id"]: ln["text"] for ln in bank}

    # Every voice type with a render of any line this plugin speaks.
    out_root = rapport / "voice" / "out"
    vts = sorted(d.name for d in out_root.iterdir()
                 if d.is_dir() and not d.name.startswith(".")
                 and any((d / f"{lid}.fuz").is_file() for lid in lines_used))

    refused, missing, ready = [], [], {}
    for vt in vts:
        for lid in lines_used:
            if not (rapport / "voice" / "pcm" / vt / f"{lid}.pcm").is_file():
                missing.append((vt, lid))
                continue
            recorded = said.get(vt, {}).get(lid)
            if recorded != text_of[lid]:
                refused.append((vt, lid, "no recorded words" if recorded is None
                                else f"rendered as {recorded!r}"))
                continue
            ready[(vt, lid)] = True

    print(f"plugin        : {a.esp}")
    print(f"INFOs         : {len(infos)}  ({len(npc)} NPC lines, {len(player)} the player's, "
          f"{len(silent)} wordless by design)")
    print(f"voiced lines  : {len(lines_used)} bank lines -> {len(registry)} INFOs")
    print(f"voice types   : {len(vts)}  ({', '.join(vts)})")
    files = sum(1 for e in registry.values() for vt in vts if (vt, e["line"]) in ready)
    print(f"to stage      : {len(ready)} renders -> {files} files")
    if unmatched:
        print(f"UNVOICED NPC lines (no bank line has this exact text - subtitle only): {len(unmatched)}")
        for fid, text in unmatched[:12]:
            print(f"    {fid:08X}  {text[:80]}")
    if missing:
        print(f"no render for {len(missing)} voice/line pairs (subtitle only for that voice):")
        for vt, lid in missing[:12]:
            print(f"    {vt}/{lid}")
    if refused:
        print(f"REFUSED {len(refused)} renders - their words are not the bank's now; re-render them:")
        for vt, lid, why in refused[:20]:
            print(f"    {vt}/{lid}: {why}")
    if a.check:
        return 1 if refused else 0

    make_lip = load_make_lip()
    lip_tool = make_lip.find_lipgen(a.lipgen)
    work = ROOT / "build" / "voice-work"
    voice_root = pathlib.Path(a.out) / "Sound" / "Voice" / PLUGIN
    wanted, made = {}, 0
    for n, (vt, lid) in enumerate(sorted(ready), 1):
        fuz = build_fuz(rapport, lip_tool, make_lip, vt, lid, text_of[lid], work)
        for fid_hex, e in registry.items():
            if e["line"] == lid:
                wanted[voice_root / vt / e["file"]] = fuz
        if n % 100 == 0:
            print(f"  {n}/{len(ready)}", flush=True)

    written = kept = 0
    for dst, src in wanted.items():
        data = src.read_bytes()
        # Content, not size: a same-size re-render would otherwise be skipped
        # and the old audio stay deployed while everything reports success.
        if dst.is_file() and dst.read_bytes() == data:
            kept += 1
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_bytes(data)
        written += 1
    # Our own folder only: a file here that no INFO names is audio for a line
    # that no longer exists, and would be the first thing wrong if its id came back.
    removed = 0
    if voice_root.is_dir():
        for f in voice_root.rglob("*"):
            if f.is_file() and f not in wanted:
                f.unlink()
                removed += 1

    reg_path = ROOT / "build" / "voice-registry.json"
    reg_path.write_text(json.dumps(
        {"_": "INFO FormID -> the bank line it speaks and its voice file name. Read from the "
              "built plugin by scripts/stage-voice.py.",
         "plugin": a.esp, "voice_types": vts, "infos": registry,
         "unvoiced": {f"{fid:08X}": text for fid, text in unmatched}}, indent=2),
        encoding="utf-8")
    print(f"staged        : {written} written, {kept} unchanged, {removed} stale removed "
          f"-> {voice_root}")
    print(f"registry      : {reg_path}")
    return 1 if refused else 0


if __name__ == "__main__":
    sys.exit(main())
