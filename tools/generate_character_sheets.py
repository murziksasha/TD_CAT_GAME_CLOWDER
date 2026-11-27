"""Generate animation sheets for ALL Clowder characters.

Cats (1280x128, 10 frames of 128x128: 4 idle, 6 attack):
Group 1: pip, nibs, pudding, biscuit
Group 2: sable, nim, goldie, miso
Group 4 (Heroes): mittens, duchess, baron, pebble

Mice Walk Sheets (512x128, 4 frames of 128x128):
Group 1: rust, grain, iron, porcelain
Group 2: slate, moss, sugar, soot
Group 3: frost, ink, marble, prism

Rats Walk Sheets (512x128, 4 frames of 128x128):
Group 1: burrow
Group 2: bristle
Group 3: monarch, dusk
Group 4: matriarch
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART_CATS = ROOT / "presentation" / "art" / "cats"
ART_MICE = ROOT / "presentation" / "art" / "mice"
ART_RATS = ROOT / "presentation" / "art" / "rats"

def fit_to_cell(im: Image.Image, max_w: int = 110, max_h: int = 110) -> Image.Image:
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    scale = min(max_w / im.width, max_h / im.height)
    new_w = max(1, int(im.width * scale))
    new_h = max(1, int(im.height * scale))
    return im.resize((new_w, new_h), Image.Resampling.LANCZOS)

def place_at(canvas: Image.Image, sprite: Image.Image, cx: int, ground_y: int,
             dx: float = 0.0, dy: float = 0.0, angle: float = 0.0,
             sx: float = 1.0, sy: float = 1.0, alpha_mult: float = 1.0) -> None:
    if sprite is None:
        return
    s = sprite
    if abs(sx - 1.0) > 0.01 or abs(sy - 1.0) > 0.01:
        nw = max(1, int(s.width * abs(sx)))
        nh = max(1, int(s.height * abs(sy)))
        s = s.resize((nw, nh), Image.Resampling.BILINEAR)
        if sx < 0:
            s = s.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if abs(angle) > 0.5:
        s = s.rotate(angle, resample=Image.Resampling.BILINEAR, expand=True)
    if alpha_mult < 0.99:
        s = s.copy()
        r, g, b, a = s.split()
        a = a.point(lambda p: int(p * alpha_mult))
        s.putalpha(a)
    x = int(cx + dx - s.width / 2.0)
    y = int(ground_y + dy - s.height)
    canvas.paste(s, (x, y), s)

def make_cat_sheet(name: str) -> Image.Image:
    src_file = ART_CATS / f"{name}.png"
    if not src_file.exists():
        # Fallback to mittens if hero sprite not found yet
        src_file = ART_CATS / "mittens.png"
    base_raw = Image.open(src_file).convert("RGBA")
    base = fit_to_cell(base_raw, max_w=98, max_h=98)
    sheet = Image.new("RGBA", (1280, 128), (0, 0, 0, 0))
    ground_y = 114

    for frame in range(10):
        cell = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)
        cx = 64

        # Group 1 Cats
        if name == "pip":
            if frame < 4:
                bobs = [0, -2, -1, 0]
                tilts = [0, -1.5, 1.0, 0]
                place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.0, sy=1.0)
                draw.ellipse([cx + 6, ground_y - 38 + bobs[frame], cx + 22, ground_y - 22 + bobs[frame]], fill=(230, 125, 34, 230), outline=(180, 80, 20, 255))
                draw.line([cx + 12, ground_y - 42 + bobs[frame], cx + 18, ground_y - 18 + bobs[frame]], fill=(220, 220, 240, 240), width=2)
            elif frame == 4:
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=2, angle=-5.0, sx=0.95, sy=1.02)
                draw.ellipse([cx - 4, ground_y - 42, cx + 12, ground_y - 26], fill=(240, 140, 45, 240), outline=(180, 80, 20, 255))
                draw.line([cx + 4, ground_y - 34, cx + 28, ground_y - 48], fill=(255, 215, 120, 220), width=2)
            elif frame == 5:
                place_at(cell, base, cx + 4, ground_y, dx=0, dy=-2, angle=4.0, sx=1.04, sy=0.96)
                draw.line([cx + 12, ground_y - 44, cx + 38, ground_y - 42], fill=(255, 215, 120, 240), width=2)
            elif frame == 6:
                place_at(cell, base, cx + 8, ground_y, dx=0, dy=-3, angle=6.0, sx=1.08, sy=0.94)
                draw.ellipse([cx + 44, ground_y - 54, cx + 58, ground_y - 40], fill=(240, 130, 35, 255), outline=(180, 75, 15, 255))
                draw.line([cx + 20, ground_y - 44, cx + 44, ground_y - 47], fill=(255, 225, 140, 230), width=2)
            elif frame == 7:
                place_at(cell, base, cx + 5, ground_y, dx=0, dy=-1, angle=3.0, sx=1.02, sy=0.98)
            elif frame == 8:
                place_at(cell, base, cx + 1, ground_y, dx=0, dy=1, angle=-2.0, sx=0.98, sy=1.01)
            else:
                place_at(cell, base, cx, ground_y, dx=0, dy=0, angle=0, sx=1.0, sy=1.0)

        elif name == "nibs":
            if frame < 4:
                bobs = [2, 5, 0, 3]
                tilts = [0, -2.5, 1.5, -1.0]
                place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.02, sy=0.97)
            elif frame == 4:
                place_at(cell, base, cx - 3, ground_y, dx=0, dy=7, angle=-6.0, sx=1.08, sy=0.88)
            elif frame == 5:
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=4, angle=-12.0, sx=0.92, sy=1.04)
            elif frame == 6:
                place_at(cell, base, cx + 4, ground_y, dx=0, dy=-2, angle=14.0, sx=1.12, sy=0.92)
                draw.arc([cx - 36, ground_y - 68, cx + 44, ground_y + 4], start=210, end=350, fill=(235, 245, 255, 230), width=4)
                draw.arc([cx - 40, ground_y - 72, cx + 48, ground_y + 8], start=220, end=360, fill=(160, 210, 255, 200), width=3)
            elif frame == 7:
                place_at(cell, base, cx + 7, ground_y, dx=0, dy=-4, angle=8.0, sx=1.06, sy=0.95)
            elif frame == 8:
                place_at(cell, base, cx + 2, ground_y, dx=0, dy=4, angle=-3.0, sx=1.04, sy=0.94)
            else:
                place_at(cell, base, cx, ground_y, dx=0, dy=2, angle=0, sx=1.02, sy=0.97)

        elif name == "pudding":
            bowl_color = (130, 205, 245, 230)
            bowl_rim = (210, 245, 255, 255)
            if frame < 4:
                bobs = [4, 2, 5, 4]
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=bobs[frame], angle=0, sx=1.02, sy=0.96)
                draw.ellipse([cx + 12, ground_y - 28, cx + 38, ground_y - 6], fill=bowl_color, outline=bowl_rim, width=2)
            elif frame == 4:
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=3, angle=-1.5, sx=1.0, sy=0.98)
                draw.ellipse([cx + 12, ground_y - 28, cx + 38, ground_y - 6], fill=bowl_color, outline=bowl_rim, width=2)
                draw.ellipse([cx + 18, ground_y - 36, cx + 28, ground_y - 24], fill=(217, 236, 247, 240), outline=(160, 200, 225, 255))
            elif frame == 5:
                place_at(cell, base, cx - 5, ground_y, dx=0, dy=3, angle=0, sx=1.01, sy=0.97)
                draw.ellipse([cx + 12, ground_y - 28, cx + 38, ground_y - 6], fill=(160, 225, 255, 245), outline=bowl_rim, width=2)
                draw.ellipse([cx + 20, ground_y - 30, cx + 30, ground_y - 18], fill=(217, 236, 247, 240), outline=(160, 200, 225, 255))
            elif frame == 6:
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=4, angle=0, sx=1.02, sy=0.96)
                draw.ellipse([cx + 12, ground_y - 28, cx + 38, ground_y - 6], fill=(190, 240, 255, 255), outline=(255, 255, 255, 255), width=3)
                draw.arc([cx - 4, ground_y - 48, cx + 54, ground_y + 10], start=0, end=360, fill=(170, 230, 255, 220), width=3)
            elif frame == 7:
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=4, angle=0, sx=1.01, sy=0.97)
                draw.ellipse([cx + 12, ground_y - 28, cx + 38, ground_y - 6], fill=bowl_color, outline=bowl_rim, width=2)
            else:
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=4, angle=0, sx=1.02, sy=0.96)
                draw.ellipse([cx + 12, ground_y - 28, cx + 38, ground_y - 6], fill=bowl_color, outline=bowl_rim, width=2)

        elif name == "biscuit":
            basket_col = (185, 120, 65, 240)
            basket_rim = (120, 70, 30, 255)
            if frame < 4:
                bobs = [0, 1, -2, 0]
                tilts = [0, 2.0, -1.5, 0]
                place_at(cell, base, cx - 8, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.0, sy=1.0)
                draw.ellipse([cx + 10, ground_y - 34, cx + 36, ground_y - 6], fill=basket_col, outline=basket_rim, width=2)
                draw.line([cx + 20, ground_y - 44, cx + 26, ground_y - 24], fill=(245, 240, 225, 255), width=3)
            elif frame == 4:
                place_at(cell, base, cx - 5, ground_y, dx=0, dy=2, angle=3.0, sx=1.02, sy=0.98)
                draw.ellipse([cx + 10, ground_y - 34, cx + 36, ground_y - 6], fill=basket_col, outline=basket_rim, width=2)
            elif frame == 5:
                place_at(cell, base, cx - 9, ground_y, dx=0, dy=3, angle=-3.0, sx=1.03, sy=0.96)
                draw.ellipse([cx + 10, ground_y - 34, cx + 36, ground_y - 6], fill=basket_col, outline=basket_rim, width=2)
                draw.polygon([(cx + 8, ground_y - 22), (cx + 5, ground_y - 26), (cx + 11, ground_y - 26)], fill=(255, 220, 60, 255))
            elif frame == 6:
                place_at(cell, base, cx - 14, ground_y, dx=0, dy=-1, angle=-10.0, sx=0.92, sy=1.05)
                draw.ellipse([cx + 10, ground_y - 34, cx + 36, ground_y - 6], fill=(140, 90, 50, 255), outline=basket_rim, width=2)
                draw.ellipse([cx + 14, ground_y - 56, cx + 42, ground_y - 30], fill=(255, 200, 80, 240), outline=(240, 100, 30, 255))
                draw.line([cx + 28, ground_y - 74, cx + 42, ground_y - 92], fill=(250, 245, 235, 255), width=4)
            elif frame == 7:
                place_at(cell, base, cx - 11, ground_y, dx=0, dy=2, angle=-8.0, sx=0.94, sy=1.03)
                draw.ellipse([cx + 10, ground_y - 34, cx + 36, ground_y - 6], fill=basket_col, outline=basket_rim, width=2)
            else:
                place_at(cell, base, cx - 8, ground_y, dx=0, dy=0, angle=0, sx=1.0, sy=1.0)
                draw.ellipse([cx + 10, ground_y - 34, cx + 36, ground_y - 6], fill=basket_col, outline=basket_rim, width=2)

        # Group 2 Cats
        elif name == "sable":
            # Rooftop sniper with long rifle and monocle
            if frame < 4:
                bobs = [0, -1, 0, -1]
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=bobs[frame], angle=0, sx=1.0, sy=1.0)
                # Rifle rested low
                draw.line([cx - 10, ground_y - 38, cx + 28, ground_y - 48], fill=(90, 75, 60, 255), width=3)
                draw.ellipse([cx + 4, ground_y - 76, cx + 12, ground_y - 68], fill=(160, 220, 255, 220), outline=(220, 190, 90, 255)) # Monocle
            elif frame == 4:
                # Raises rifle to eye
                place_at(cell, base, cx - 2, ground_y, dx=0, dy=-1, angle=2.0, sx=0.99, sy=1.01)
                draw.line([cx - 8, ground_y - 60, cx + 38, ground_y - 62], fill=(85, 70, 55, 255), width=3)
                draw.ellipse([cx + 2, ground_y - 74, cx + 10, ground_y - 66], fill=(160, 220, 255, 220), outline=(220, 190, 90, 255))
            elif frame == 5:
                # Holds breath / precise lock
                place_at(cell, base, cx - 2, ground_y, dx=0, dy=-2, angle=1.0, sx=1.0, sy=1.0)
                draw.line([cx - 8, ground_y - 60, cx + 40, ground_y - 62], fill=(85, 70, 55, 255), width=3)
            elif frame == 6:
                # SNIPER CRACK! Muzzle flash, recoil lifts barrel, monocle slips
                place_at(cell, base, cx - 8, ground_y, dx=0, dy=1, angle=-7.0, sx=0.95, sy=1.03)
                draw.line([cx - 12, ground_y - 56, cx + 34, ground_y - 68], fill=(85, 70, 55, 255), width=3)
                # Muzzle flash spark
                draw.polygon([(cx + 42, ground_y - 70), (cx + 56, ground_y - 72), (cx + 44, ground_y - 64)], fill=(255, 235, 100, 255))
                draw.ellipse([cx + 6, ground_y - 66, cx + 14, ground_y - 58], fill=(160, 220, 255, 200), outline=(220, 190, 90, 255)) # Slipped monocle
            elif frame == 7:
                # Bolt action: casing ejects
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=0, angle=-2.0, sx=0.98, sy=1.01)
                draw.line([cx - 8, ground_y - 52, cx + 32, ground_y - 56], fill=(85, 70, 55, 255), width=3)
                # Brass casing flying up
                draw.rectangle([cx + 2, ground_y - 78, cx + 6, ground_y - 72], fill=(230, 190, 70, 255))
            elif frame == 8:
                # Chambering round
                place_at(cell, base, cx - 3, ground_y, dx=0, dy=0, angle=0, sx=1.0, sy=1.0)
                draw.line([cx - 8, ground_y - 48, cx + 30, ground_y - 52], fill=(85, 70, 55, 255), width=3)
            else:
                # Pushes monocle back in place
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=0, angle=0, sx=1.0, sy=1.0)
                draw.line([cx - 10, ground_y - 38, cx + 28, ground_y - 48], fill=(90, 75, 60, 255), width=3)

        elif name == "nim":
            # Hyperactive magic apprentice with crackling lightning orb
            if frame < 4:
                bobs = [0, -3, 1, -2]
                tilts = [0, 3.0, -2.0, 1.5]
                place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.0, sy=1.0)
                # Crackling hovering orb between paws
                draw.circle((cx + 16, ground_y - 42 + bobs[frame]), 8, fill=(160, 90, 230, 220))
                draw.circle((cx + 16, ground_y - 42 + bobs[frame]), 4, fill=(240, 220, 255, 255))
            elif frame == 4:
                # Channelling lightning: fur puffs out
                place_at(cell, base, cx - 2, ground_y, dx=0, dy=-2, angle=-4.0, sx=1.06, sy=0.96)
                draw.circle((cx + 20, ground_y - 46), 11, fill=(180, 110, 245, 240))
                draw.circle((cx + 20, ground_y - 46), 6, fill=(255, 255, 255, 255))
            elif frame == 5:
                # Arc buildup: lightning crackles to ground
                place_at(cell, base, cx - 1, ground_y, dx=0, dy=-3, angle=-2.0, sx=1.08, sy=0.94)
                draw.line([cx + 22, ground_y - 46, cx + 38, ground_y - 40], fill=(220, 200, 255, 255), width=3)
            elif frame == 6:
                # ZAP! Beam discharge with arcs
                place_at(cell, base, cx + 4, ground_y, dx=0, dy=-2, angle=6.0, sx=1.10, sy=0.93)
                draw.line([cx + 20, ground_y - 46, cx + 58, ground_y - 46], fill=(255, 255, 255, 255), width=4)
                draw.line([cx + 20, ground_y - 46, cx + 54, ground_y - 46], fill=(170, 90, 245, 200), width=8)
                draw.line([cx + 36, ground_y - 54, cx + 44, ground_y - 38], fill=(220, 180, 255, 230), width=2)
            elif frame == 7:
                # Follow-through: tingling paws
                place_at(cell, base, cx + 2, ground_y, dx=0, dy=-1, angle=2.0, sx=1.02, sy=0.98)
                draw.circle((cx + 22, ground_y - 44), 6, fill=(160, 90, 230, 180))
            elif frame == 8:
                # Shakes tingling paws
                place_at(cell, base, cx, ground_y, dx=0, dy=1, angle=-2.0, sx=0.98, sy=1.02)
            else:
                place_at(cell, base, cx, ground_y, dx=0, dy=0, angle=0, sx=1.0, sy=1.0)
                draw.circle((cx + 16, ground_y - 42), 8, fill=(160, 90, 230, 220))

        elif name == "goldie":
            # Portly dock merchant & fisherman with fishing net
            if frame < 4:
                bobs = [0, 2, 0, 1]
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=bobs[frame], angle=0, sx=1.04, sy=0.96)
                # Coiled rope net on shoulder
                draw.arc([cx - 18, ground_y - 68 + bobs[frame], cx + 6, ground_y - 42 + bobs[frame]], start=40, end=200, fill=(175, 140, 90, 255), width=3)
            elif frame == 4:
                # Wind up swing
                place_at(cell, base, cx - 8, ground_y, dx=0, dy=3, angle=-8.0, sx=1.02, sy=0.98)
                draw.arc([cx - 26, ground_y - 60, cx - 2, ground_y - 34], start=80, end=240, fill=(175, 140, 90, 255), width=4)
            elif frame == 5:
                # Full body torso throw
                place_at(cell, base, cx + 2, ground_y, dx=0, dy=-1, angle=6.0, sx=1.06, sy=0.95)
            elif frame == 6:
                # CAST! Expanding net in air with sinkers
                place_at(cell, base, cx + 8, ground_y, dx=0, dy=-2, angle=10.0, sx=1.08, sy=0.94)
                draw.ellipse([cx + 22, ground_y - 58, cx + 58, ground_y - 28], fill=(195, 160, 105, 140), outline=(150, 115, 70, 255), width=2)
                draw.circle((cx + 24, ground_y - 43), 2.5, fill=(70, 75, 80, 255))
                draw.circle((cx + 40, ground_y - 28), 2.5, fill=(70, 75, 80, 255))
                draw.circle((cx + 56, ground_y - 43), 2.5, fill=(70, 75, 80, 255))
            elif frame == 7:
                # Bracing on both feet, hauling line
                place_at(cell, base, cx + 3, ground_y, dx=0, dy=1, angle=3.0, sx=1.04, sy=0.96)
                draw.line([cx + 12, ground_y - 40, cx + 36, ground_y - 32], fill=(160, 130, 80, 255), width=2)
            elif frame == 8:
                place_at(cell, base, cx, ground_y, dx=0, dy=2, angle=0, sx=1.03, sy=0.97)
            else:
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=0, angle=0, sx=1.04, sy=0.96)
                draw.arc([cx - 18, ground_y - 68, cx + 6, ground_y - 42], start=40, end=200, fill=(175, 140, 90, 255), width=3)

        elif name == "miso":
            # Warm cafe host with steaming broth tray
            tray_col = (160, 110, 65, 255)
            bowl_col = (235, 230, 220, 255)
            if frame < 4:
                bobs = [0, -1, 1, 0]
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=bobs[frame], angle=0, sx=1.0, sy=1.0)
                # Tea/ramen tray
                draw.rectangle([cx + 6, ground_y - 42 + bobs[frame], cx + 28, ground_y - 38 + bobs[frame]], fill=tray_col)
                draw.ellipse([cx + 10, ground_y - 48 + bobs[frame], cx + 24, ground_y - 36 + bobs[frame]], fill=bowl_col, outline=(180, 140, 80, 255))
                # Gentle steam
                draw.arc([cx + 14, ground_y - 60 + bobs[frame], cx + 22, ground_y - 48 + bobs[frame]], start=200, end=340, fill=(255, 255, 255, 140), width=1)
            elif frame == 4:
                # Raises ladle
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=-1, angle=2.0, sx=1.01, sy=0.99)
                draw.rectangle([cx + 6, ground_y - 42, cx + 28, ground_y - 38], fill=tray_col)
                draw.line([cx + 18, ground_y - 48, cx + 32, ground_y - 64], fill=(190, 150, 90, 255), width=2)
            elif frame == 5:
                # Heats broth swirl
                place_at(cell, base, cx - 3, ground_y, dx=0, dy=-2, angle=3.0, sx=1.02, sy=0.98)
                draw.ellipse([cx + 10, ground_y - 48, cx + 24, ground_y - 36], fill=(255, 205, 80, 255))
            elif frame == 6:
                # SERVE! Aromatic golden steam splash radiates
                place_at(cell, base, cx - 2, ground_y, dx=0, dy=-1, angle=4.0, sx=1.03, sy=0.97)
                draw.ellipse([cx + 10, ground_y - 48, cx + 24, ground_y - 36], fill=(255, 215, 90, 255))
                draw.arc([cx - 4, ground_y - 70, cx + 46, ground_y - 20], start=0, end=360, fill=(255, 230, 130, 180), width=2)
                draw.arc([cx - 14, ground_y - 80, cx + 56, ground_y - 10], start=0, end=360, fill=(180, 240, 200, 120), width=1)
            elif frame == 7:
                # Steam clouds expand
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=0, angle=1.0, sx=1.01, sy=0.99)
                draw.rectangle([cx + 6, ground_y - 42, cx + 28, ground_y - 38], fill=tray_col)
                draw.ellipse([cx + 10, ground_y - 48, cx + 24, ground_y - 36], fill=bowl_col)
            else:
                place_at(cell, base, cx - 6, ground_y, dx=0, dy=0, angle=0, sx=1.0, sy=1.0)
                draw.rectangle([cx + 6, ground_y - 42, cx + 28, ground_y - 38], fill=tray_col)
                draw.ellipse([cx + 10, ground_y - 48, cx + 24, ground_y - 36], fill=bowl_col)

        # Group 4 Heroes
        elif name in ["mittens", "duchess", "baron", "pebble"]:
            bobs = [0, -2, 0, -1]
            if frame < 4:
                place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=0, sx=1.0, sy=1.0)
                if name == "mittens":
                    draw.circle((cx + 10, ground_y - 50 + bobs[frame]), 4, fill=(230, 180, 50, 255)) # Captain's brass whistle
                elif name == "duchess":
                    draw.arc([cx + 8, ground_y - 52 + bobs[frame], cx + 26, ground_y - 32 + bobs[frame]], start=220, end=350, fill=(225, 180, 240, 255), width=3) # Ornate fan
                elif name == "baron":
                    draw.line([cx + 8, ground_y - 62 + bobs[frame], cx + 18, ground_y - 60 + bobs[frame]], fill=(140, 90, 50, 255), width=2) # Sea pipe
                elif name == "pebble":
                    draw.circle((cx + 10, ground_y - 46 + bobs[frame]), 5, fill=(130, 200, 140, 240)) # Prayer rosary beads
            elif frame == 4:
                place_at(cell, base, cx - 4, ground_y, dx=0, dy=2, angle=-5.0, sx=0.96, sy=1.02)
            elif frame == 5:
                place_at(cell, base, cx - 2, ground_y, dx=0, dy=-1, angle=2.0, sx=1.02, sy=0.98)
            elif frame == 6:
                # HEROIC ACTION
                place_at(cell, base, cx + 6, ground_y, dx=0, dy=-3, angle=8.0, sx=1.08, sy=0.94)
                draw.arc([cx - 20, ground_y - 65, cx + 46, ground_y + 2], start=210, end=360, fill=(255, 240, 150, 220), width=3)
            elif frame == 7:
                place_at(cell, base, cx + 4, ground_y, dx=0, dy=-1, angle=4.0, sx=1.04, sy=0.96)
            else:
                place_at(cell, base, cx, ground_y, dx=0, dy=0, angle=0, sx=1.0, sy=1.0)

        sheet.paste(cell, (frame * 128, 0), cell)
    return sheet

def make_mouse_walk_sheet(name: str) -> Image.Image:
    base_raw = Image.open(ART_MICE / f"{name}.png").convert("RGBA")
    base = fit_to_cell(base_raw, max_w=94, max_h=94)
    sheet = Image.new("RGBA", (512, 128), (0, 0, 0, 0))
    ground_y = 114
    cx = 64

    for frame in range(4):
        cell = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)

        # Group 1
        if name == "rust":
            # Permanent SPEC 10 shapes: notched ear + chew marks
            bobs = [0, -4, 0, -3]
            tilts = [2, -2, 2, -1]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.0, sy=1.0)
            # Notched ear wedge & prominent chew-mark stripes on flank
            draw.polygon([(cx + 6, ground_y - 78 + bobs[frame]), (cx + 14, ground_y - 84 + bobs[frame]), (cx + 12, ground_y - 70 + bobs[frame])], fill=(45, 25, 18, 255))
            draw.line([cx - 20, ground_y - 40 + bobs[frame], cx - 10, ground_y - 26 + bobs[frame]], fill=(92, 42, 18, 255), width=4)
            draw.line([cx - 12, ground_y - 42 + bobs[frame], cx - 2, ground_y - 28 + bobs[frame]], fill=(92, 42, 18, 255), width=4)
        elif name == "grain":
            bobs = [-2, 1, -3, 2]
            tilts = [14, 18, 13, 17]
            place_at(cell, base, cx + 4, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.02, sy=0.98)
            draw.line([cx - 32, ground_y - 26 + bobs[frame], cx - 54, ground_y - 36 + bobs[frame]], fill=(217, 173, 54, 255), width=4)
            draw.rectangle([cx - 18, ground_y - 38 + bobs[frame], cx - 2, ground_y - 22 + bobs[frame]], fill=(168, 104, 42, 255), outline=(85, 42, 14, 255), width=2)
        elif name == "iron":
            # Prominent metal bucket helmet with rim & visor slit
            bobs = [0, 4, 0, 3]
            tilts = [-3, 2, -2, 3]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.05, sy=0.95)
            draw.rectangle([cx - 16, ground_y - 86 + bobs[frame], cx + 20, ground_y - 50 + bobs[frame]], fill=(162, 170, 182, 250), outline=(70, 76, 86, 255), width=3)
            draw.line([cx - 18, ground_y - 50 + bobs[frame], cx + 22, ground_y - 50 + bobs[frame]], fill=(215, 222, 230, 255), width=4)
            draw.line([cx - 8, ground_y - 66 + bobs[frame], cx + 14, ground_y - 66 + bobs[frame]], fill=(28, 30, 36, 255), width=4)
        elif name == "porcelain":
            bobs = [-1, 1, -2, 1]
            tilts = [4, 6, 3, 5]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=0.97, sy=1.02)
            draw.arc([cx - 18, ground_y - 70 + bobs[frame], cx + 18, ground_y - 32 + bobs[frame]], start=200, end=330, fill=(255, 255, 255, 235), width=3)
            draw.ellipse([cx - 22, ground_y - 58 + bobs[frame], cx + 22, ground_y - 18 + bobs[frame]], outline=(170, 178, 192, 220), width=2)

        # Group 2
        elif name == "slate":
            # Street ruffian in tilted flat cap
            bobs = [0, -3, 0, -2]
            tilts = [-2, 2, -1, 3]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.03, sy=0.97)
            draw.ellipse([cx - 16, ground_y - 84 + bobs[frame], cx + 18, ground_y - 66 + bobs[frame]], fill=(88, 98, 110, 255), outline=(42, 48, 56, 255), width=2)
            draw.line([cx - 18, ground_y - 70 + bobs[frame], cx + 12, ground_y - 68 + bobs[frame]], fill=(42, 48, 56, 255), width=3)
        elif name == "moss":
            # Camouflaged scout with leaf hat AND prominent leaf tail
            bobs = [-2, 2, -3, 1]
            tilts = [6, 10, 5, 9]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.0, sy=1.0)
            draw.polygon([(cx - 4, ground_y - 78 + bobs[frame]), (cx + 10, ground_y - 96 + bobs[frame]), (cx + 14, ground_y - 74 + bobs[frame])], fill=(88, 162, 62, 255), outline=(42, 86, 32, 255))
            draw.polygon([(cx - 28, ground_y - 28 + bobs[frame]), (cx - 54, ground_y - 44 + bobs[frame]), (cx - 44, ground_y - 18 + bobs[frame])], fill=(96, 174, 68, 255), outline=(42, 86, 32, 255))
            draw.line([cx - 28, ground_y - 28 + bobs[frame], cx - 49, ground_y - 36 + bobs[frame]], fill=(42, 86, 32, 255), width=2)
        elif name == "sugar":
            # Sweet tooth with giant pink spiral lollipop
            bobs = [-4, 2, -5, 3] # bouncy prance
            tilts = [3, -3, 4, -2]
            place_at(cell, base, cx - 2, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=0.98, sy=1.02)
            # Lollipop stick & candy
            draw.line([cx - 8, ground_y - 38 + bobs[frame], cx - 18, ground_y - 74 + bobs[frame]], fill=(240, 240, 240, 255), width=2)
            draw.circle((cx - 18, ground_y - 74 + bobs[frame]), 10, fill=(245, 130, 165, 255), outline=(215, 80, 120, 255))
            draw.arc([cx - 24, ground_y - 80 + bobs[frame], cx - 12, ground_y - 68 + bobs[frame]], start=0, end=270, fill=(255, 255, 255, 255), width=2)
        elif name == "soot":
            # Chimney sweep with soot smudges
            bobs = [0, -3, 0, -2]
            tilts = [2, -2, 1, -1]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.0, sy=1.0)
            # Soot sweep brush
            draw.line([cx - 16, ground_y - 20 + bobs[frame], cx - 24, ground_y - 66 + bobs[frame]], fill=(120, 80, 50, 255), width=2)
            draw.circle((cx - 24, ground_y - 66 + bobs[frame]), 6, fill=(35, 32, 30, 255))

        # Group 3
        elif name == "frost":
            # Shivering mouse in knit woolen scarf
            bobs = [0, 1, 0, 1]
            tilts = [-1, 1, -2, 1]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=0.98, sy=1.02)
            # Cozy striped cyan scarf around neck
            draw.rectangle([cx - 12, ground_y - 56 + bobs[frame], cx + 16, ground_y - 42 + bobs[frame]], fill=(100, 195, 220, 255), outline=(60, 140, 170, 255))
            draw.line([cx - 6, ground_y - 56 + bobs[frame], cx - 6, ground_y - 32 + bobs[frame]], fill=(240, 250, 255, 255), width=4)
        elif name == "ink":
            # Mystic thief with pointed sorcerer hat
            bobs = [0, -3, 0, -2]
            tilts = [1, -2, 2, -1]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.0, sy=1.0)
            # Wizard cap
            draw.polygon([(cx - 12, ground_y - 66 + bobs[frame]), (cx + 4, ground_y - 94 + bobs[frame]), (cx + 14, ground_y - 64 + bobs[frame])], fill=(65, 35, 95, 255), outline=(130, 80, 190, 255))
        elif name == "marble":
            # Heavy brute carrying stone slab
            bobs = [0, 4, 0, 3] # heavy stomp
            tilts = [-1, 2, -1, 1]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.04, sy=0.96)
            # Stone slab on back
            draw.rectangle([cx - 22, ground_y - 64 + bobs[frame], cx - 2, ground_y - 28 + bobs[frame]], fill=(130, 155, 165, 255), outline=(80, 105, 115, 255), width=2)
        elif name == "prism":
            # Agile tumbler with sparkling crystal prism
            bobs = [-3, 1, -4, 2]
            tilts = [4, -4, 5, -3]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=0.97, sy=1.03)
            # Crystalline prism
            draw.polygon([(cx + 10, ground_y - 56 + bobs[frame]), (cx + 20, ground_y - 68 + bobs[frame]), (cx + 24, ground_y - 48 + bobs[frame]), (cx + 14, ground_y - 42 + bobs[frame])], fill=(225, 150, 240, 220), outline=(255, 255, 255, 255))

        sheet.paste(cell, (frame * 128, 0), cell)
    return sheet

def make_rat_walk_sheet(name: str) -> Image.Image:
    base_raw = Image.open(ART_RATS / f"{name}.png").convert("RGBA")
    base = fit_to_cell(base_raw, max_w=104, max_h=104)
    sheet = Image.new("RGBA", (512, 128), (0, 0, 0, 0))
    ground_y = 118
    cx = 64

    for frame in range(4):
        cell = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)

        if name == "burrow":
            bobs = [0, 4, 0, 3]
            tilts = [-2, 3, -1, 2]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.04, sy=0.96)
            draw.ellipse([cx - 12, ground_y - 100 + bobs[frame], cx + 18, ground_y - 82 + bobs[frame]], fill=(245, 170, 35, 250), outline=(170, 100, 10, 255), width=2)
            draw.line([cx - 16, ground_y - 86 + bobs[frame], cx + 22, ground_y - 86 + bobs[frame]], fill=(255, 210, 70, 255), width=3)

        elif name == "bristle":
            # Barbed spine armor tank
            bobs = [0, 4, 0, 3]
            tilts = [2, -2, 1, -1]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.05, sy=0.95)
            # Spines along back
            for sp_i in range(4):
                draw.line([cx - 26 + sp_i * 8, ground_y - 70 + bobs[frame], cx - 34 + sp_i * 8, ground_y - 94 + bobs[frame]], fill=(190, 130, 80, 255), width=3)

        elif name == "monarch":
            # Regal king rat with golden crown and velvet mantle
            bobs = [0, 3, 0, 2]
            tilts = [-1, 2, -1, 1]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=1.03, sy=0.97)
            # Golden royal crown
            draw.polygon([(cx - 10, ground_y - 98 + bobs[frame]), (cx - 12, ground_y - 110 + bobs[frame]), (cx - 4, ground_y - 104 + bobs[frame]), (cx + 2, ground_y - 112 + bobs[frame]), (cx + 8, ground_y - 104 + bobs[frame]), (cx + 14, ground_y - 110 + bobs[frame]), (cx + 12, ground_y - 98 + bobs[frame])], fill=(255, 215, 60, 255), outline=(190, 150, 20, 255))
            # Purple velvet mantle collar
            draw.arc([cx - 20, ground_y - 80 + bobs[frame], cx + 20, ground_y - 54 + bobs[frame]], start=30, end=150, fill=(180, 40, 80, 255), width=4)

        elif name == "dusk":
            # Shadow spy in trenchcoat & sunglasses
            bobs = [-2, 1, -2, 1]
            tilts = [3, 4, 2, 4]
            place_at(cell, base, cx, ground_y, dx=0, dy=bobs[frame], angle=tilts[frame], sx=0.98, sy=1.02)
            # Dark sunglasses
            draw.rectangle([cx - 4, ground_y - 86 + bobs[frame], cx + 18, ground_y - 78 + bobs[frame]], fill=(25, 25, 30, 255), outline=(70, 70, 80, 255))

        elif name == "matriarch":
            # Massive queen rat on mobile wooden siege platform
            bobs = [0, 2, 0, 1]
            place_at(cell, base, cx, ground_y - 6, dx=0, dy=bobs[frame], angle=0, sx=1.06, sy=0.98)
            # Throne platform wheels & timber base
            draw.rectangle([cx - 36, ground_y - 12, cx + 36, ground_y - 4], fill=(130, 85, 45, 255), outline=(75, 45, 20, 255), width=2)
            draw.circle((cx - 24, ground_y - 4), 6, fill=(50, 45, 40, 255))
            draw.circle((cx + 24, ground_y - 4), 6, fill=(50, 45, 40, 255))

        sheet.paste(cell, (frame * 128, 0), cell)
    return sheet

def main():
    print("Generating ALL Cat & Hero Animation Sheets...")
    cats = ["pip", "nibs", "pudding", "biscuit", "sable", "nim", "goldie", "miso", "mittens", "duchess", "baron", "pebble"]
    for cat in cats:
        s = make_cat_sheet(cat)
        out_path = ART_CATS / f"{cat}_sheet.png"
        s.save(out_path)
        print(f"Saved {out_path.name} ({s.size[0]}x{s.size[1]})")

    print("\nGenerating ALL Mice Walk Sheets...")
    mice = ["rust", "grain", "iron", "porcelain", "slate", "moss", "sugar", "soot", "frost", "ink", "marble", "prism"]
    for mouse in mice:
        s = make_mouse_walk_sheet(mouse)
        out_path = ART_MICE / f"{mouse}_walk.png"
        s.save(out_path)
        print(f"Saved {out_path.name} ({s.size[0]}x{s.size[1]})")

    print("\nGenerating ALL Rat Walk Sheets...")
    rats = ["burrow", "bristle", "monarch", "dusk", "matriarch"]
    for rat in rats:
        s = make_rat_walk_sheet(rat)
        out_path = ART_RATS / f"{rat}_walk.png"
        s.save(out_path)
        print(f"Saved {out_path.name} ({s.size[0]}x{s.size[1]})")

    print("\nALL Animation Sheets generated successfully!")

if __name__ == "__main__":
    main()
