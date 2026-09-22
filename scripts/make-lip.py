"""Generate .lip files for Overture's voice lines.

Uses Bethesda's own LipGenerator, which SHIPS WITH THE GAME at
`<game>/Tools/LipGen/LipGenerator/LipGenerator.exe`, with `FonixData.cdf` beside
it. No Creation Kit, no download, no third-party tool.

    LipGenerator <wav> "<spoken text>" [-Language:USEnglish]
                 [-GestureExaggeration:1.0] [-OutputFileName:...]
                 [-LipAnimDelay:..] [-LipAnimSpeed:..]

MEASURED 2026-09-22, and the two facts worth keeping:

- It accepts a **44.1kHz mono 16-bit** wav directly and writes the .lip beside
  it. That matters because the widely-cited alternative, Nukem9's
  FaceFXWrapper, demands a 16kHz mono file and makes you resample first. Ours
  do not need resampling.
- What was verified is that a .lip is PRODUCED (1,981 bytes from a real line).
  Whether the game accepts it and the mouth actually moves is NOT yet verified -
  that needs the game, and until somebody watches a face move this is an
  untested output, not a working pipeline. Say so rather than assume.

The text argument matters: the phoneme alignment is driven by it, so it must be
the line as SPOKEN. Pass the same string that went to the text-to-speech, not a
cleaned-up subtitle.
"""
import argparse
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Both GOG and Steam layouts; first one that exists wins.
CANDIDATES = [
    pathlib.Path(r"D:\GOGGames\Fallout 4 GOTY\Tools\LipGen\LipGenerator\LipGenerator.exe"),
    pathlib.Path(r"C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Tools\LipGen\LipGenerator\LipGenerator.exe"),
]


def find_lipgen(explicit=None):
    if explicit:
        p = pathlib.Path(explicit)
        if not p.is_file():
            sys.exit(f"no LipGenerator at {p}")
        return p
    for p in CANDIDATES:
        if p.is_file():
            return p
    sys.exit(
        "LipGenerator.exe not found. It ships with the game at\n"
        "  <game>/Tools/LipGen/LipGenerator/LipGenerator.exe\n"
        "Pass --lipgen <path> if your install is elsewhere."
    )


def one(lipgen, wav, text, exaggeration=None):
    """Generate <wav>.lip. Returns the path, or raises."""
    wav = pathlib.Path(wav).resolve()
    if not wav.is_file():
        raise FileNotFoundError(wav)
    args = [str(lipgen), str(wav), text]
    if exaggeration is not None:
        args.append(f"-GestureExaggeration:{exaggeration}")
    # It writes beside the wav and reports nothing useful on success, so the
    # file appearing is the only evidence there is - check for it rather than
    # trusting the exit code.
    out = wav.with_suffix(".lip")
    before = out.stat().st_mtime if out.exists() else None
    proc = subprocess.run(args, cwd=str(lipgen.parent), capture_output=True, text=True)
    if not out.exists():
        raise RuntimeError(f"no .lip written for {wav.name}\n{proc.stdout}\n{proc.stderr}")
    if before is not None and out.stat().st_mtime == before:
        raise RuntimeError(f".lip for {wav.name} was not rewritten - stale output")
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--lines", default=str(ROOT / "voice" / "lines.json"),
                    help="the line bank, for id -> spoken text")
    ap.add_argument("--voice-dir", default=str(ROOT / "voice" / "out"),
                    help="rendered audio, <voice type>/<line id>.wav")
    ap.add_argument("--lipgen", default=None, help="path to LipGenerator.exe")
    ap.add_argument("--exaggeration", type=float, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    lipgen = find_lipgen(args.lipgen)
    bank = json.loads(pathlib.Path(args.lines).read_text(encoding="utf-8"))
    text_of = {l["id"]: l["text"] for l in bank["lines"]}

    root = pathlib.Path(args.voice_dir)
    wavs = sorted(root.rglob("*.wav")) if root.is_dir() else []
    if not wavs:
        print(f"no wavs under {root} - nothing to do")
        return

    made = skipped = failed = 0
    for wav in wavs:
        text = text_of.get(wav.stem)
        if text is None:
            # A wav with no line behind it is a packaging mistake, not a
            # no-op: it would ship audio nothing can select.
            print(f"  SKIP {wav.relative_to(root)} - no line with id {wav.stem!r}")
            skipped += 1
            continue
        if args.dry_run:
            print(f"  would lip {wav.relative_to(root)}")
            made += 1
            continue
        try:
            one(lipgen, wav, text, args.exaggeration)
            made += 1
        except Exception as exc:  # noqa: BLE001 - report and keep going
            print(f"  FAIL {wav.relative_to(root)}: {exc}")
            failed += 1

    print(f"{made} lip file(s), {skipped} skipped, {failed} failed  [{lipgen}]")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
