import io
import math
from typing import List

from PIL import Image
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader


class PosterizationError(Exception):
    """Custom exception for posterization failures."""


def mm_to_points(value_mm: float) -> float:
    return value_mm * mm


def mm_to_inches(value_mm: float) -> float:
    return value_mm / 25.4


def create_tiles(image: Image.Image, pages_across: int, margin_mm: float, dpi: int) -> List[Image.Image]:
    page_width_mm, page_height_mm = 210, 297
    printable_width_mm = page_width_mm - 2 * margin_mm
    printable_height_mm = page_height_mm - 2 * margin_mm

    if printable_width_mm <= 0 or printable_height_mm <= 0:
        raise PosterizationError("Kies een kleinere marge zodat er ruimte op de pagina overblijft.")

    tile_width_px = int(round(mm_to_inches(printable_width_mm) * dpi))
    tile_height_px = int(round(mm_to_inches(printable_height_mm) * dpi))

    cols = pages_across
    ideal_total_width_px = tile_width_px * cols
    required_total_height_px = ideal_total_width_px * image.height / image.width
    rows = max(1, math.ceil(required_total_height_px / tile_height_px))

    total_height_px = tile_height_px * rows

    scale_for_width = ideal_total_width_px / image.width
    scale_for_height = total_height_px / image.height
    scale = min(scale_for_width, scale_for_height)

    scaled_width = max(1, int(round(image.width * scale)))
    scaled_height = max(1, int(round(image.height * scale)))

    scaled_image = image.resize((scaled_width, scaled_height), Image.LANCZOS)

    poster_canvas = Image.new("RGB", (ideal_total_width_px, total_height_px), color="white")
    offset_x = (ideal_total_width_px - scaled_width) // 2
    offset_y = (total_height_px - scaled_height) // 2
    poster_canvas.paste(scaled_image, (offset_x, offset_y))

    tiles: List[Image.Image] = []
    for row in range(rows):
        for col in range(cols):
            left = col * tile_width_px
            upper = row * tile_height_px
            right = min(left + tile_width_px, ideal_total_width_px)
            lower = min(upper + tile_height_px, total_height_px)

            tile = poster_canvas.crop((left, upper, right, lower))
            # Pad the last row/column so every tile matches the printable area.
            padded_tile = Image.new("RGB", (tile_width_px, tile_height_px), color="white")
            padded_tile.paste(tile, (0, 0))
            tiles.append(padded_tile)

    return tiles


def build_pdf_from_tiles(tiles: List[Image.Image], margin_mm: float, dpi: int) -> bytes:
    buffer = io.BytesIO()
    page_width_pt, page_height_pt = A4
    margin_pt = mm_to_points(margin_mm)

    pdf = canvas.Canvas(buffer, pagesize=A4)

    for tile in tiles:
        tile_buffer = io.BytesIO()
        tile.save(tile_buffer, format="PNG")
        tile_buffer.seek(0)
        image_reader = ImageReader(tile_buffer)

        tile_width_pt = (tile.width / dpi) * 72
        tile_height_pt = (tile.height / dpi) * 72

        width_available = page_width_pt - 2 * margin_pt
        height_available = page_height_pt - 2 * margin_pt

        render_width = min(tile_width_pt, width_available)
        render_height = min(tile_height_pt, height_available)

        pdf.drawImage(
            image_reader,
            margin_pt,
            page_height_pt - margin_pt - render_height,
            width=render_width,
            height=render_height,
            preserveAspectRatio=True,
            anchor="sw",
        )
        pdf.showPage()

    pdf.save()
    buffer.seek(0)
    return buffer.getvalue()


def create_poster_pdf(image_file: io.BytesIO, pages_across: int, margin_mm: float, dpi: int = 300) -> bytes:
    try:
        image = Image.open(image_file).convert("RGB")
    except Exception as exc:  # pylint: disable=broad-except
        raise PosterizationError("Het bestand kon niet worden gelezen als afbeelding.") from exc

    if pages_across < 1:
        raise PosterizationError("Gebruik minstens één pagina in de breedte.")
    if margin_mm < 0:
        raise PosterizationError("Marge kan niet negatief zijn.")
    if dpi < 72:
        raise PosterizationError("Kies een DPI van 72 of hoger voor een nette afdruk.")

    tiles = create_tiles(image, pages_across=pages_across, margin_mm=margin_mm, dpi=dpi)
    pdf_bytes = build_pdf_from_tiles(tiles, margin_mm=margin_mm, dpi=dpi)
    return pdf_bytes
