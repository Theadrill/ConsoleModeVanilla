"""Create eye icons for range indicator."""
from PIL import Image, ImageDraw
import math

SIZE = 64  # skill-slot sized
WHITE = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)
SLASH_WIDTH = 5
SLASH_MARGIN = 8

def draw_eye(draw, size):
    """Draw a white eye shape (open eye)."""
    cx, cy = size // 2, size // 2
    pad = 6

    # Eye outline (almond/ellipse shape)
    eye_rx = (size // 2) - pad
    eye_ry = (size // 4) + 2
    draw.ellipse(
        [cx - eye_rx, cy - eye_ry, cx + eye_rx, cy + eye_ry],
        outline=WHITE, width=3
    )

    # Iris (filled circle)
    iris_r = eye_ry - 1
    draw.ellipse(
        [cx - iris_r, cy - iris_r, cx + iris_r, cy + iris_r],
        outline=WHITE, width=2
    )

    # Pupil (small filled circle)
    pupil_r = 3
    draw.ellipse(
        [cx - pupil_r, cy - pupil_r, cx + pupil_r, cy + pupil_r],
        fill=WHITE
    )


def draw_slash(draw, size):
    """Draw a diagonal slash line."""
    cx, cy = size // 2, size // 2
    r = (size // 2) - SLASH_MARGIN
    # Diagonal from top-right to bottom-left
    x1 = cx + int(r * math.cos(math.radians(45)))
    y1 = cy - int(r * math.sin(math.radians(45)))
    x2 = cx - int(r * math.cos(math.radians(45)))
    y2 = cy + int(r * math.sin(math.radians(45)))
    draw.line([x1, y1, x2, y2], fill=WHITE, width=SLASH_WIDTH)


# --- In-range icon (open eye) ---
img_in = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
draw_in = ImageDraw.Draw(img_in)
draw_eye(draw_in, SIZE)
img_in.save("icon_inrange.png")

# --- Out-of-range icon (eye with slash) ---
img_out = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
draw_out = ImageDraw.Draw(img_out)
draw_eye(draw_out, SIZE)
draw_slash(draw_out, SIZE)
img_out.save("icon_outrange.png")

print("Created: icon_inrange.png, icon_outrange.png")
