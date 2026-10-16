#!/usr/bin/env python3
"""Generate crisp, original Velocity Rush launcher icons from simple vector shapes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "icons"
OUT.mkdir(parents=True, exist_ok=True)
SIZE = 1024


def background(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / max(1, size - 1)
        top = (8, 18, 31)
        bottom = (13, 31, 46)
        color = tuple(round(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(size):
            glow = max(0.0, 1.0 - (((x - size * .53) / (size * .72)) ** 2 + ((y - size * .45) / (size * .72)) ** 2) ** .5)
            pixels[x, y] = tuple(min(255, round(color[i] + (17, 48, 62)[i] * glow * .32)) for i in range(3))
    return image.convert("RGBA")


def _scaled(points, size, scale):
    center = size / 2
    return [(center + (x - 512) * scale * size / 1024, center + (y - 512) * scale * size / 1024) for x, y in points]


def draw_car(layer: Image.Image, scale: float = .78, monochrome: bool = False) -> None:
    size = layer.width
    factor = size / 1024
    draw = ImageDraw.Draw(layer)
    body = [(136,671),(202,606),(335,579),(401,493),(428,459),(482,454),(615,458),(669,463),(712,520),(764,565),(855,589),(909,636),(897,687),(843,704),(190,704)]
    windows = [(420,494),(444,472),(484,468),(599,471),(642,474),(676,519),(703,550),(385,550)]
    body_pts = _scaled(body, size, scale)
    window_pts = _scaled(windows, size, scale)
    if monochrome:
        fill = (246, 250, 252, 255)
        edge = (246, 250, 252, 255)
    else:
        # Glow is rendered separately, then the solid vector body is composited on top.
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).polygon(body_pts, fill=255)
        glow = Image.new("RGBA", (size, size), (55, 205, 230, 0))
        glow.putalpha(mask.filter(ImageFilter.GaussianBlur(max(2, int(14 * factor)))))
        layer.alpha_composite(glow)
        ramp = Image.new("RGBA", (size, size), (0,0,0,0))
        ramp_px = ramp.load()
        for x in range(size):
            t = x / max(1, size - 1)
            a = (70, 216, 235)
            b = (242, 188, 79)
            col = tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3)) + (255,)
            for y in range(size):
                ramp_px[x,y] = col
        ramp.putalpha(mask)
        layer.alpha_composite(ramp)
        draw = ImageDraw.Draw(layer)
        fill = None
        edge = (198, 246, 255, 225)
    if not monochrome:
        draw.polygon(body_pts, fill=None, outline=edge, width=max(2, round(11 * factor * scale)))
    else:
        draw.polygon(body_pts, fill=fill)
    # Sculpted window, headlamp and lower aero line.
    draw.polygon(window_pts, fill=(12, 31, 47, 255) if not monochrome else (8, 18, 31, 255))
    if not monochrome:
        draw.line(_scaled([(156,660),(260,627),(347,616)], size, scale), fill=(255,244,210,190), width=max(2, round(8*factor*scale)))
        draw.line(_scaled([(711,576),(814,604),(877,642)], size, scale), fill=(255,244,210,190), width=max(2, round(8*factor*scale)))
    # Two high-contrast wheels with metal hubs.
    for x in (340, 740):
        cx = size/2 + (x-512)*scale*factor
        cy = size/2 + (692-512)*scale*factor
        r = 70*scale*factor
        draw.ellipse((cx-r,cy-r,cx+r,cy+r), fill=(6,16,27,255), outline=(146,215,228,255) if not monochrome else (246,250,252,255), width=max(2,round(12*scale*factor)))
        hub = 34*scale*factor
        draw.ellipse((cx-hub,cy-hub,cx+hub,cy+hub), fill=(21,45,61,255), outline=(232,194,106,255) if not monochrome else (246,250,252,255), width=max(2,round(9*scale*factor)))
    if not monochrome:
        draw.line(_scaled([(839,635),(896,649),(890,669),(831,665)], size, scale), fill=(255,245,218,255), width=max(2,round(10*scale*factor)))
        draw.line(_scaled([(169,680),(200,680)], size, scale), fill=(238,185,79,255), width=max(2,round(10*scale*factor)))


def rounded_icon(size: int) -> Image.Image:
    image = background(size)
    draw = ImageDraw.Draw(image)
    # Track arcs are atmospheric accents, not a real-world racing mark.
    def pts(points): return [(x*size/1024, y*size/1024) for x,y in points]
    draw.line(pts([(86,765),(276,676),(361,538),(503,430),(634,330),(778,281),(936,270)]), fill=(46,189,216,90), width=max(3,round(20*size/1024)), joint="curve")
    draw.line(pts([(120,835),(302,748),(388,631),(535,520),(658,427),(776,384),(914,368)]), fill=(232,185,91,140), width=max(2,round(8*size/1024)), joint="curve")
    car_layer = Image.new("RGBA", (size,size), (0,0,0,0))
    draw_car(car_layer, .96)
    image.alpha_composite(car_layer)
    mask = Image.new("L", (size,size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,size-1,size-1), radius=round(size*.18), fill=255)
    image.putalpha(mask)
    return image


# Main launcher icon and a full-size store/project icon.
rounded_icon(1024).save(OUT / "app_icon.png")
rounded_icon(512).save(OUT / "app_icon_512.png")
rounded_icon(64).save(OUT / "favicon.png")
# Android adaptive icon foreground is kept within the central safe zone.
fg = Image.new("RGBA", (432,432), (0,0,0,0))
draw_car(fg, .72)
fg.save(OUT / "adaptive_foreground.png")
# Adaptive background remains a plain opaque plate; Android applies its own mask.
background(432).save(OUT / "adaptive_background.png")
mono = Image.new("RGBA", (432,432), (0,0,0,0))
draw_car(mono, .72, monochrome=True)
mono.save(OUT / "adaptive_monochrome.png")
print("Generated launcher icons and 64px favicon in", OUT)
