"""Cut chroma-key lineup sheets into transparent PNG sprites."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Path(r"C:\Users\murzi\.grok\sessions\c%3A%5CUsers%5Cmurzi%5CDesktop%5Cproject%5CTD_game\01a18e18-4216-79d2-9e3c-11e2f130e718\images")
ART = ROOT / "presentation" / "art"

CATS = ["pip", "nibs", "pudding", "biscuit", "sable", "nim", "goldie", "miso", "mittens"]
MICE = ["rust", "slate", "moss", "grain", "sugar", "soot", "frost", "ink", "iron", "marble", "prism", "porcelain"]
RATS = ["burrow", "bristle", "monarch", "dusk", "matriarch"]
PROPS = ["stall", "lantern", "crates", "puddle"]


def key_green(im: Image.Image, tol: int = 78) -> Image.Image:
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    corners = [px[2, 2], px[w - 3, 2], px[2, h - 3], px[w - 3, h - 3]]
    kr = sum(c[0] for c in corners) // 4
    kg = sum(c[1] for c in corners) // 4
    kb = sum(c[2] for c in corners) // 4
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dist = abs(r - kr) + abs(g - kg) + abs(b - kb)
            # Green-dominant fringe around the key.
            greenish = g > r + 18 and g > b + 18 and g > 90
            if dist < tol or (greenish and dist < tol + 50):
                px[x, y] = (0, 0, 0, 0)
            elif greenish and g > 140 and (g - max(r, b)) > 30:
                # Despill leftover green halo into transparency.
                spill = min(255, (g - max(r, b)) * 3)
                na = max(0, a - spill)
                px[x, y] = (r, min(g, max(r, b) + 8), b, na)
    return im


def ink_columns(im: Image.Image, y0: int, y1: int, thresh: int = 18) -> list:
    w, _h = im.size
    px = im.load()
    cols = []
    for x in range(w):
        count = 0
        for y in range(y0, y1, 2):
            if px[x, y][3] > 40:
                count += 1
                if count >= thresh:
                    cols.append(x)
                    break
    return cols


def runs_from_columns(cols: list, gap: int) -> list:
    if not cols:
        return []
    runs = []
    start = cols[0]
    prev = cols[0]
    for x in cols[1:]:
        if x - prev > gap:
            runs.append((start, prev))
            start = x
        prev = x
    runs.append((start, prev))
    return runs


def row_bands(im: Image.Image, min_ink: int = 12) -> list:
    w, h = im.size
    px = im.load()
    ink_rows = []
    for y in range(h):
        count = 0
        for x in range(0, w, 3):
            if px[x, y][3] > 40:
                count += 1
                if count >= min_ink:
                    ink_rows.append(y)
                    break
    if not ink_rows:
        return []
    bands = []
    start = ink_rows[0]
    prev = ink_rows[0]
    for y in ink_rows[1:]:
        if y - prev > 18:
            bands.append((start, prev))
            start = y
        prev = y
    bands.append((start, prev))
    return bands


def crop_run(im: Image.Image, x0: int, x1: int, y0: int, y1: int, pad: int = 8) -> Image.Image:
    w, h = im.size
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(w - 1, x1 + pad)
    y1 = min(h - 1, y1 + pad)
    sprite = im.crop((x0, y0, x1 + 1, y1 + 1))
    bbox = sprite.getbbox()
    if bbox:
        sprite = sprite.crop(bbox)
    # Uniform padding on a transparent canvas.
    pw = max(4, sprite.width // 16)
    ph = max(4, sprite.height // 16)
    canvas = Image.new("RGBA", (sprite.width + pw * 2, sprite.height + ph * 2), (0, 0, 0, 0))
    canvas.paste(sprite, (pw, ph), sprite)
    return canvas


def column_density(im: Image.Image, y0: int, y1: int) -> list:
    w, _h = im.size
    px = im.load()
    density = [0] * w
    for x in range(w):
        count = 0
        for y in range(y0, y1, 2):
            if px[x, y][3] > 40:
                count += 1
        density[x] = count
    return density


def _smooth(values: list, radius: int = 6) -> list:
    out = []
    n = len(values)
    for i in range(n):
        lo = max(0, i - radius)
        hi = min(n, i + radius + 1)
        out.append(sum(values[lo:hi]) / (hi - lo))
    return out


def _ink_runs(density: list, thresh: float) -> list:
    runs = []
    start = None
    for i, value in enumerate(density):
        if value > thresh and start is None:
            start = i
        elif value <= thresh and start is not None:
            runs.append([start, i - 1])
            start = None
    if start is not None:
        runs.append([start, len(density) - 1])
    return [run for run in runs if run[1] - run[0] > 16]


def split_band_by_peaks(im: Image.Image, y0: int, y1: int, count: int) -> list:
    density = _smooth(column_density(im, y0, y1), 5)
    peak = max(density) if density else 1
    runs = _ink_runs(density, peak * 0.12)
    guard = 0
    while len(runs) < count and guard < 12:
        guard += 1
        widest = max(runs, key=lambda run: run[1] - run[0])
        lo = widest[0] + 12
        hi = widest[1] - 12
        if hi <= lo:
            break
        valley = min(range(lo, hi), key=lambda i: density[i])
        # Only split a real gap inside the blob, not a flat body.
        if density[valley] > peak * 0.55:
            break
        runs.remove(widest)
        runs.append([widest[0], valley])
        runs.append([valley + 1, widest[1]])
        runs.sort()
    while len(runs) > count and len(runs) > 1:
        # Merge the pair separated by the smallest gap.
        gap_i = min(range(len(runs) - 1), key=lambda i: runs[i + 1][0] - runs[i][1])
        merged = [runs[gap_i][0], runs[gap_i + 1][1]]
        runs = runs[:gap_i] + [merged] + runs[gap_i + 2 :]
    return [crop_run(im, run[0], run[1], y0, y1) for run in runs]


def split_names(im: Image.Image, names: list, gap: int) -> list:
    bands = row_bands(im)
    if not bands:
        return []
    # One row: peak-split the whole cast. Two rows: split names in half.
    if len(bands) == 1 or len(names) <= 6:
        y0, y1 = bands[0][0], bands[-1][1]
        return split_band_by_peaks(im, y0, y1, len(names))
    per = len(names) // len(bands)
    crops = []
    for i, (y0, y1) in enumerate(bands):
        crops.extend(split_band_by_peaks(im, y0, y1, per))
    return crops


def save_set(crops: list, names: list, folder: Path) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    count = min(len(crops), len(names))
    for i in range(count):
        crops[i].save(folder / f"{names[i]}.png")
    print(f"{folder.name}: saved {count}, found {len(crops)}, expected {len(names)}")
    if count != len(names):
        print("  MISMATCH")


def copy_tile(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    Image.open(src).convert("RGB").save(dest)
    print(f"tile {dest.name}")


def main() -> None:
    cats = key_green(Image.open(SRC / "3.jpg"))
    mice = key_green(Image.open(SRC / "5.jpg"))
    rats = key_green(Image.open(SRC / "6.jpg"))
    props = key_green(Image.open(SRC / "4.jpg"), tol=70)
    save_set(split_names(cats, CATS, gap=14), CATS, ART / "cats")
    save_set(split_names(mice, MICE, gap=12), MICE, ART / "mice")
    save_set(split_names(rats, RATS, gap=16), RATS, ART / "rats")
    save_set(split_names(props, PROPS, gap=20), PROPS, ART / "props")
    copy_tile(SRC / "1.jpg", ART / "tiles" / "grass.png")
    copy_tile(SRC / "2.jpg", ART / "tiles" / "cobble.png")


if __name__ == "__main__":
    main()
