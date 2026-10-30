import csv
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "build" / "store" / "feature_art.png"
TRANSLATIONS = ROOT / "i18n" / "translations.csv"
FONT_BOLD = ROOT / "assets" / "fonts" / "Geist-Bold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "Geist-Regular.ttf"
OUTPUT = ROOT / "docs" / "store"

WIDTH, HEIGHT = 1024, 500
BACKGROUND = (11, 16, 32)
GLOW = (26, 39, 71)
ENERGY = (62, 232, 255)
ON_SURFACE_VARIANT = (169, 180, 208)
TEXT_LEFT = 72
TEXT_WIDTH = 520
ART_CENTER = (790, HEIGHT // 2)
TITLE_KEY = "APP_TITLE"
TAGLINE_KEY = "MENU_TAGLINE"
LOCALES = ("en", "de")
SPARKS = 90
SEED = 7


def read_texts(path: Path) -> dict:
    texts = {}
    with path.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            if row["keys"] in (TITLE_KEY, TAGLINE_KEY):
                texts[row["keys"]] = row
    return texts


def wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, width: int) -> list:
    lines, current = [], ""
    for word in text.split():
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=font) <= width or not current:
            current = candidate
        else:
            lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def fitted_font(draw: ImageDraw.ImageDraw, text: str, path: Path, size: int, width: int) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(path), size)
    while draw.textlength(text, font=font) > width and size > 24:
        size -= 2
        font = ImageFont.truetype(str(path), size)
    return font


def backdrop() -> Image.Image:
    image = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    halo = Image.radial_gradient("L").resize((WIDTH * 2, HEIGHT * 3))
    halo = halo.crop((WIDTH // 2 - (ART_CENTER[0] - WIDTH // 2), HEIGHT, WIDTH // 2 - (ART_CENTER[0] - WIDTH // 2) + WIDTH, HEIGHT * 2))
    image.paste(Image.new("RGB", (WIDTH, HEIGHT), GLOW), (0, 0), Image.eval(halo, lambda value: 255 - value))
    draw = ImageDraw.Draw(image)
    rng = random.Random(SEED)
    for _ in range(SPARKS):
        x, y = rng.uniform(0, WIDTH), rng.uniform(0, HEIGHT)
        radius = rng.uniform(0.6, 2.2)
        shade = tuple(int(BACKGROUND[i] + (ENERGY[i] - BACKGROUND[i]) * rng.uniform(0.2, 0.6)) for i in range(3))
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=shade)
    return image


def glow_text(image: Image.Image, position: tuple, text: str, font: ImageFont.FreeTypeFont, color: tuple) -> None:
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text(position, text, font=font, fill=color + (170,))
    image.paste(layer.filter(ImageFilter.GaussianBlur(14)), (0, 0), layer.filter(ImageFilter.GaussianBlur(14)))
    ImageDraw.Draw(image).text(position, text, font=font, fill=color)


def compose(art: Image.Image, title: str, tagline: str) -> Image.Image:
    image = backdrop()
    aura = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(aura).ellipse((ART_CENTER[0] - 170, ART_CENTER[1] - 170, ART_CENTER[0] + 170, ART_CENTER[1] + 170), fill=ENERGY + (40,))
    aura = aura.filter(ImageFilter.GaussianBlur(60))
    image.paste(aura, (0, 0), aura)
    image.paste(art, (ART_CENTER[0] - art.width // 2, ART_CENTER[1] - art.height // 2), art)
    draw = ImageDraw.Draw(image)
    title_font = fitted_font(draw, title, FONT_BOLD, 96, TEXT_WIDTH)
    tag_font = ImageFont.truetype(str(FONT_REGULAR), 30)
    lines = wrap(draw, tagline, tag_font, TEXT_WIDTH)
    title_height = title_font.getbbox(title)[3]
    line_height = 40
    block = title_height + 28 + line_height * len(lines)
    top = (HEIGHT - block) // 2
    glow_text(image, (TEXT_LEFT, top), title, title_font, ENERGY)
    for index, line in enumerate(lines):
        draw.text((TEXT_LEFT, top + title_height + 28 + index * line_height), line, font=tag_font, fill=ON_SURFACE_VARIANT)
    return image


def main() -> int:
    if not ART.exists():
        print(f"missing {ART}, run render_icons.gd first", file=sys.stderr)
        return 1
    art = Image.open(ART).convert("RGBA")
    texts = read_texts(TRANSLATIONS)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for locale in LOCALES:
        image = compose(art, texts[TITLE_KEY][locale].upper(), texts[TAGLINE_KEY][locale])
        target = OUTPUT / f"feature-graphic-{locale}.png"
        image.convert("RGB").save(target, optimize=True)
        print(f"{target} ({image.width}x{image.height})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
