"""Generate App Store screenshot mockups for Ghost Sonar."""
from PIL import Image, ImageDraw, ImageFont
import math
import random
import os

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# iPhone 6.7" dimensions (1290x2796)
W, H = 1290, 2796

# Colors
BG_COLOR = (8, 15, 8)
SONAR_GREEN = (46, 230, 74)
SONAR_GREEN_DIM = (20, 100, 32)
SONAR_GREEN_FAINT = (10, 50, 16)
SONAR_RED = (242, 38, 26)
SONAR_YELLOW = (242, 217, 26)
SONAR_ORANGE = (242, 128, 26)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)


def draw_sonar_radar(draw, cx, cy, radius):
    """Draw the sonar radar grid."""
    # Outer ring
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius],
                 outline=SONAR_GREEN, width=3)

    # Inner rings
    for scale in [0.75, 0.5, 0.25]:
        r = int(radius * scale)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                     outline=SONAR_GREEN_FAINT, width=1)

    # Cross lines
    for i in range(12):
        angle = i * math.pi / 6
        ex = cx + int(math.cos(angle) * radius)
        ey = cy + int(math.sin(angle) * radius)
        opacity_color = SONAR_GREEN_DIM if i % 3 == 0 else SONAR_GREEN_FAINT
        draw.line([cx, cy, ex, ey], fill=opacity_color, width=1)

    # Center dot
    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=SONAR_GREEN)


def draw_sweep_line(draw, cx, cy, radius, angle):
    """Draw the sonar sweep line with trail."""
    # Trail
    for i in range(30):
        trail_angle = angle - i * 0.015
        alpha_factor = 1.0 - i / 30.0
        color = (int(46 * alpha_factor * 0.3), int(230 * alpha_factor * 0.3), int(74 * alpha_factor * 0.3))
        ex = cx + int(math.cos(trail_angle) * radius)
        ey = cy + int(math.sin(trail_angle) * radius)
        draw.line([cx, cy, ex, ey], fill=color, width=1)

    # Main sweep line
    ex = cx + int(math.cos(angle) * radius)
    ey = cy + int(math.sin(angle) * radius)
    draw.line([cx, cy, ex, ey], fill=SONAR_GREEN, width=3)


def draw_blip(draw, cx, cy, radius, angle, dist, color, size=12):
    """Draw a ghost blip on radar."""
    x = cx + int(math.cos(angle) * radius * dist)
    y = cy + int(math.sin(angle) * radius * dist)

    # Outer glow
    draw.ellipse([x - size * 2, y - size * 2, x + size * 2, y + size * 2],
                 fill=(color[0] // 4, color[1] // 4, color[2] // 4))
    # Core
    draw.ellipse([x - size, y - size, x + size, y + size], fill=color)
    # Bright center
    draw.ellipse([x - size // 3, y - size // 3, x + size // 3, y + size // 3],
                 fill=WHITE)


def draw_sensor_bar(draw, x, y, w, h, value, color, label):
    """Draw a sensor bar gauge."""
    # Background
    draw.rectangle([x, y, x + w, y + h], fill=SONAR_GREEN_FAINT, outline=SONAR_GREEN_FAINT)

    # Fill
    fill_h = int(h * value)
    draw.rectangle([x, y + h - fill_h, x + w, y + h], fill=color)

    # Segments
    for i in range(10):
        seg_y = y + int(h * i / 10)
        draw.rectangle([x, seg_y, x + w, seg_y + 2], fill=BG_COLOR)

    # Label
    try:
        font = ImageFont.truetype("arial.ttf", 20)
    except:
        font = ImageFont.load_default()
    draw.text((x + w // 2, y + h + 10), label, fill=SONAR_GREEN, font=font, anchor="mt")


def draw_threat_bar(draw, x, y, w, level):
    """Draw threat level indicator."""
    levels = [("LOW", SONAR_GREEN), ("MED", SONAR_YELLOW), ("HIGH", SONAR_ORANGE), ("CRIT", SONAR_RED)]
    seg_w = w // 4
    try:
        font = ImageFont.truetype("arial.ttf", 18)
    except:
        font = ImageFont.load_default()

    for i, (lbl, color) in enumerate(levels):
        active = i <= level
        fill = color if active else (color[0] // 6, color[1] // 6, color[2] // 6)
        draw.rectangle([x + i * seg_w, y, x + (i + 1) * seg_w - 4, y + 8], fill=fill)
        text_color = color if active else (color[0] // 4, color[1] // 4, color[2] // 4)
        draw.text((x + i * seg_w + seg_w // 2, y + 16), lbl, fill=text_color, font=font, anchor="mt")


def add_text(draw, text, x, y, size=24, color=SONAR_GREEN, anchor="lt"):
    """Add text with monospace-like font."""
    try:
        font = ImageFont.truetype("cour.ttf", size)
    except:
        try:
            font = ImageFont.truetype("arial.ttf", size)
        except:
            font = ImageFont.load_default()
    draw.text((x, y), text, fill=color, font=font, anchor=anchor)


def add_scanlines(img):
    """Add CRT scanline effect."""
    draw = ImageDraw.Draw(img)
    for y in range(0, H, 3):
        draw.line([(0, y), (W, y)], fill=(0, 0, 0, 30), width=1)


def add_vignette(img):
    """Add vignette effect."""
    from PIL import ImageFilter
    vignette = Image.new('RGB', (W, H), BLACK)
    vdraw = ImageDraw.Draw(vignette)
    for r in range(max(W, H), 0, -2):
        alpha = max(0, min(255, int((1 - r / max(W, H)) * 180)))
        color = (alpha, alpha, alpha)
        vdraw.ellipse([W // 2 - r, H // 2 - r, W // 2 + r, H // 2 + r], fill=color)
    from PIL import ImageChops
    img_result = ImageChops.multiply(img, vignette)
    return img_result


def screenshot_main_scanning():
    """Screenshot 1: Main scanning view with detections."""
    img = Image.new('RGB', (W, H), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Title bar
    add_text(draw, "GHOST SONAR", 60, 120, size=42, color=SONAR_GREEN)
    add_text(draw, "PARANORMAL DETECTION SYSTEM v2.1", 60, 175, size=16, color=SONAR_GREEN_DIM)
    add_text(draw, "21:47:33", W - 60, 120, size=30, color=SONAR_GREEN, anchor="rt")
    add_text(draw, "DEPTH: 000m", W - 60, 160, size=16, color=SONAR_GREEN_DIM, anchor="rt")

    # Status bar
    draw.rectangle([50, 210, W - 50, 250], fill=(10, 30, 10), outline=SONAR_GREEN_FAINT)
    draw.ellipse([70, 222, 82, 234], fill=SONAR_GREEN)
    add_text(draw, "SCANNING...", 95, 215, size=22)
    add_text(draw, "CONTACTS: 7", W - 70, 215, size=20, color=SONAR_GREEN_DIM, anchor="rt")

    # Sonar radar
    radar_cx, radar_cy = W // 2, 900
    radar_r = 480
    draw_sonar_radar(draw, radar_cx, radar_cy, radar_r)
    draw_sweep_line(draw, radar_cx, radar_cy, radar_r, -0.8)

    # Ghost blips
    draw_blip(draw, radar_cx, radar_cy, radar_r, 0.5, 0.6, SONAR_GREEN, 10)
    draw_blip(draw, radar_cx, radar_cy, radar_r, 2.1, 0.4, SONAR_YELLOW, 14)
    draw_blip(draw, radar_cx, radar_cy, radar_r, 3.8, 0.75, SONAR_GREEN, 8)
    draw_blip(draw, radar_cx, radar_cy, radar_r, 5.2, 0.3, SONAR_ORANGE, 16)

    # Cardinal markers
    add_text(draw, "N", radar_cx, radar_cy - radar_r - 30, size=24, anchor="mt")
    add_text(draw, "S", radar_cx, radar_cy + radar_r + 10, size=24, anchor="mt")
    add_text(draw, "E", radar_cx + radar_r + 15, radar_cy, size=24, anchor="lm")
    add_text(draw, "W", radar_cx - radar_r - 15, radar_cy, size=24, anchor="rm")

    # Threat indicator
    draw_threat_bar(draw, 60, 1430, W - 120, 1)

    # Sensor bars
    bar_y = 1500
    bar_h = 160
    bar_w = 50
    sensors = [("EMF", 0.45, SONAR_GREEN), ("EVP", 0.3, SONAR_GREEN),
               ("PRES", 0.15, SONAR_GREEN), ("VIB", 0.55, SONAR_YELLOW)]
    spacing = (W - 120) // 4
    for i, (label, val, color) in enumerate(sensors):
        bx = 60 + i * spacing + spacing // 2 - bar_w // 2
        draw_sensor_bar(draw, bx, bar_y, bar_w, bar_h, val, color, label)

    # Detection log area
    log_y = 1750
    add_text(draw, "DETECTION LOG", 60, log_y, size=20, color=SONAR_GREEN_DIM)
    add_text(draw, "7 CONTACTS", W - 60, log_y, size=18, color=SONAR_GREEN_DIM, anchor="rt")

    log_entries = [
        ("21:47:31", "EMF", "Electromagnetic field distortion", SONAR_GREEN),
        ("21:47:28", "EVP", "Audio anomaly captured", SONAR_GREEN),
        ("21:47:22", "MULTI", "WARNING: Multiple sensor anomaly", SONAR_YELLOW),
        ("21:47:15", "PRES", "Barometric pressure drop", SONAR_GREEN),
    ]
    for i, (time, typ, desc, color) in enumerate(log_entries):
        ly = log_y + 35 + i * 32
        draw.rectangle([50, ly - 2, W - 50, ly + 26], fill=(color[0] // 20, color[1] // 20, color[2] // 20))
        add_text(draw, time, 60, ly, size=16, color=SONAR_GREEN_DIM)
        add_text(draw, typ, 220, ly, size=16, color=color)
        add_text(draw, desc, 330, ly, size=14, color=(color[0] // 2, color[1] // 2, color[2] // 2))

    # Control buttons
    btn_y = 1920
    draw.rounded_rectangle([350, btn_y, 940, btn_y + 70], radius=10,
                           outline=SONAR_RED, width=2)
    draw.rounded_rectangle([352, btn_y + 2, 938, btn_y + 68], radius=10,
                           fill=(SONAR_RED[0] // 10, SONAR_RED[1] // 10, SONAR_RED[2] // 10))
    add_text(draw, "STOP SCAN", 645, btn_y + 20, size=28, color=SONAR_RED, anchor="mt")

    # Ad banner placeholder
    draw.rectangle([0, H - 120, W, H], fill=(20, 20, 20))
    add_text(draw, "AD", W // 2, H - 70, size=20, color=(80, 80, 80), anchor="mm")

    add_scanlines(img)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_01_scanning.png"))
    print("Generated: screenshot_01_scanning.png")


def screenshot_critical_detection():
    """Screenshot 2: Critical detection with horror effects."""
    img = Image.new('RGB', (W, H), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Red tinted background for horror
    overlay = Image.new('RGB', (W, H), (40, 5, 5))
    img = Image.blend(img, overlay, 0.3)
    draw = ImageDraw.Draw(img)

    # Title bar
    add_text(draw, "GHOST SONAR", 60, 120, size=42, color=SONAR_RED)
    add_text(draw, "PARANORMAL DETECTION SYSTEM v2.1", 60, 175, size=16, color=(100, 20, 20))
    add_text(draw, "03:33:13", W - 60, 120, size=30, color=SONAR_RED, anchor="rt")

    # Status bar - ALERT
    draw.rectangle([50, 210, W - 50, 250], fill=(50, 10, 10), outline=SONAR_RED)
    draw.ellipse([70, 222, 82, 234], fill=SONAR_RED)
    add_text(draw, "!! CONTACT DETECTED !!", 95, 215, size=22, color=SONAR_RED)
    add_text(draw, "CONTACTS: 23", W - 70, 215, size=20, color=SONAR_RED, anchor="rt")

    # Sonar radar
    radar_cx, radar_cy = W // 2, 900
    radar_r = 480
    draw_sonar_radar(draw, radar_cx, radar_cy, radar_r)
    draw_sweep_line(draw, radar_cx, radar_cy, radar_r, 1.2)

    # Many blips - critical
    blips = [
        (0.3, 0.2, SONAR_RED, 20), (1.0, 0.5, SONAR_RED, 18),
        (1.5, 0.35, SONAR_ORANGE, 14), (2.2, 0.7, SONAR_RED, 22),
        (2.8, 0.45, SONAR_YELLOW, 12), (3.5, 0.6, SONAR_RED, 16),
        (4.0, 0.25, SONAR_ORANGE, 14), (4.8, 0.8, SONAR_RED, 18),
        (5.5, 0.55, SONAR_RED, 20),
    ]
    for angle, dist, color, size in blips:
        draw_blip(draw, radar_cx, radar_cy, radar_r, angle, dist, color, size)

    # Cardinal markers
    add_text(draw, "N", radar_cx, radar_cy - radar_r - 30, size=24, color=SONAR_RED, anchor="mt")
    add_text(draw, "S", radar_cx, radar_cy + radar_r + 10, size=24, color=SONAR_RED, anchor="mt")
    add_text(draw, "E", radar_cx + radar_r + 15, radar_cy, size=24, color=SONAR_RED, anchor="lm")
    add_text(draw, "W", radar_cx - radar_r - 15, radar_cy, size=24, color=SONAR_RED, anchor="rm")

    # Horror text overlay
    try:
        horror_font = ImageFont.truetype("arial.ttf", 90)
    except:
        horror_font = ImageFont.load_default()
    # Red shadow
    draw.text((W // 2 + 4, 770), "IT'S HERE", fill=(150, 0, 0), font=horror_font, anchor="mm")
    # Main text
    draw.text((W // 2, 768), "IT'S HERE", fill=WHITE, font=horror_font, anchor="mm")

    # Threat indicator - CRITICAL
    draw_threat_bar(draw, 60, 1430, W - 120, 3)

    # Sensor bars - all high
    bar_y = 1500
    bar_h = 160
    bar_w = 50
    sensors = [("EMF", 0.92, SONAR_RED), ("EVP", 0.78, SONAR_ORANGE),
               ("PRES", 0.85, SONAR_RED), ("VIB", 0.95, SONAR_RED)]
    spacing = (W - 120) // 4
    for i, (label, val, color) in enumerate(sensors):
        bx = 60 + i * spacing + spacing // 2 - bar_w // 2
        draw_sensor_bar(draw, bx, bar_y, bar_w, bar_h, val, color, label)

    # Interference lines
    for _ in range(8):
        ly = random.randint(0, H)
        lh = random.randint(2, 6)
        draw.rectangle([0, ly, W, ly + lh], fill=(SONAR_GREEN[0] // 3, SONAR_GREEN[1] // 3, SONAR_GREEN[2] // 3))

    # Static noise patches
    for _ in range(200):
        nx = random.randint(0, W)
        ny = random.randint(0, H)
        ns = random.randint(2, 8)
        nb = random.randint(30, 100)
        draw.rectangle([nx, ny, nx + ns, ny + ns], fill=(nb, nb, nb))

    add_scanlines(img)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_02_critical.png"))
    print("Generated: screenshot_02_critical.png")


def screenshot_calibrating():
    """Screenshot 3: Calibration / startup view."""
    img = Image.new('RGB', (W, H), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Title bar
    add_text(draw, "GHOST SONAR", 60, 120, size=42, color=SONAR_GREEN)
    add_text(draw, "PARANORMAL DETECTION SYSTEM v2.1", 60, 175, size=16, color=SONAR_GREEN_DIM)
    add_text(draw, "22:15:08", W - 60, 120, size=30, color=SONAR_GREEN, anchor="rt")

    # Status bar - calibrating
    draw.rectangle([50, 210, W - 50, 250], fill=(10, 30, 10), outline=SONAR_GREEN_FAINT)
    draw.ellipse([70, 222, 82, 234], fill=SONAR_YELLOW)
    add_text(draw, "INITIALIZING...", 95, 215, size=22, color=SONAR_YELLOW)
    add_text(draw, "CALIBRATING 65%", W - 70, 215, size=20, color=SONAR_YELLOW, anchor="rt")

    # Sonar radar (clean, no detections)
    radar_cx, radar_cy = W // 2, 900
    radar_r = 480
    draw_sonar_radar(draw, radar_cx, radar_cy, radar_r)
    draw_sweep_line(draw, radar_cx, radar_cy, radar_r, 2.5)

    # Cardinal markers
    add_text(draw, "N", radar_cx, radar_cy - radar_r - 30, size=24, anchor="mt")
    add_text(draw, "S", radar_cx, radar_cy + radar_r + 10, size=24, anchor="mt")
    add_text(draw, "E", radar_cx + radar_r + 15, radar_cy, size=24, anchor="lm")
    add_text(draw, "W", radar_cx - radar_r - 15, radar_cy, size=24, anchor="rm")

    # Progress bar
    prog_y = 1420
    draw.rectangle([100, prog_y, W - 100, prog_y + 12], fill=SONAR_GREEN_FAINT)
    draw.rectangle([100, prog_y, 100 + int((W - 200) * 0.65), prog_y + 12], fill=SONAR_GREEN)

    # Calibration info
    add_text(draw, "CALIBRATING SENSORS", W // 2, prog_y + 40, size=22, color=SONAR_YELLOW, anchor="mt")
    add_text(draw, "Establishing baseline readings...", W // 2, prog_y + 72, size=16, color=SONAR_GREEN_DIM, anchor="mt")

    # Sensor bars - low during calibration
    bar_y = 1550
    bar_h = 160
    bar_w = 50
    sensors = [("EMF", 0.12, SONAR_GREEN), ("EVP", 0.08, SONAR_GREEN),
               ("PRES", 0.05, SONAR_GREEN), ("VIB", 0.03, SONAR_GREEN)]
    spacing = (W - 120) // 4
    for i, (label, val, color) in enumerate(sensors):
        bx = 60 + i * spacing + spacing // 2 - bar_w // 2
        draw_sensor_bar(draw, bx, bar_y, bar_w, bar_h, val, color, label)

    # Threat indicator - all low
    draw_threat_bar(draw, 60, 1780, W - 120, -1)

    # Start button
    btn_y = 1850
    draw.rounded_rectangle([350, btn_y, 940, btn_y + 70], radius=10,
                           outline=SONAR_GREEN, width=2)
    draw.rounded_rectangle([352, btn_y + 2, 938, btn_y + 68], radius=10,
                           fill=(SONAR_GREEN[0] // 10, SONAR_GREEN[1] // 10, SONAR_GREEN[2] // 10))
    add_text(draw, "BEGIN SCAN", 645, btn_y + 20, size=28, color=SONAR_GREEN, anchor="mt")

    add_scanlines(img)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_03_calibrating.png"))
    print("Generated: screenshot_03_calibrating.png")


def screenshot_japanese():
    """Screenshot 4: Japanese localization view."""
    img = Image.new('RGB', (W, H), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Title
    add_text(draw, "GHOST SONAR", 60, 120, size=42, color=SONAR_GREEN)
    add_text(draw, "超常現象探知システム v2.1", 60, 175, size=18, color=SONAR_GREEN_DIM)

    # Status
    draw.rectangle([50, 220, W - 50, 260], fill=(10, 30, 10), outline=SONAR_GREEN_FAINT)
    draw.ellipse([70, 232, 82, 244], fill=SONAR_GREEN)
    add_text(draw, "スキャン中...", 95, 225, size=22)
    add_text(draw, "検出数: 5", W - 70, 225, size=20, color=SONAR_GREEN_DIM, anchor="rt")

    # Radar
    radar_cx, radar_cy = W // 2, 900
    radar_r = 480
    draw_sonar_radar(draw, radar_cx, radar_cy, radar_r)
    draw_sweep_line(draw, radar_cx, radar_cy, radar_r, 4.0)

    # Blips
    draw_blip(draw, radar_cx, radar_cy, radar_r, 1.2, 0.5, SONAR_GREEN, 12)
    draw_blip(draw, radar_cx, radar_cy, radar_r, 3.0, 0.3, SONAR_YELLOW, 16)
    draw_blip(draw, radar_cx, radar_cy, radar_r, 4.5, 0.65, SONAR_GREEN, 10)

    # Cardinals
    add_text(draw, "N", radar_cx, radar_cy - radar_r - 30, size=24, anchor="mt")
    add_text(draw, "S", radar_cx, radar_cy + radar_r + 10, size=24, anchor="mt")
    add_text(draw, "E", radar_cx + radar_r + 15, radar_cy, size=24, anchor="lm")
    add_text(draw, "W", radar_cx - radar_r - 15, radar_cy, size=24, anchor="rm")

    # Threat
    draw_threat_bar(draw, 60, 1430, W - 120, 1)

    # Sensors
    bar_y = 1500
    bar_h = 160
    bar_w = 50
    sensors = [("EMF", 0.38, SONAR_GREEN), ("EVP", 0.52, SONAR_YELLOW),
               ("気圧", 0.2, SONAR_GREEN), ("振動", 0.15, SONAR_GREEN)]
    spacing = (W - 120) // 4
    for i, (label, val, color) in enumerate(sensors):
        bx = 60 + i * spacing + spacing // 2 - bar_w // 2
        draw_sensor_bar(draw, bx, bar_y, bar_w, bar_h, val, color, label)

    # Log
    log_y = 1750
    add_text(draw, "探知ログ", 60, log_y, size=20, color=SONAR_GREEN_DIM)
    log_entries = [
        ("22:30:15", "EMF", "電磁場の歪みを検出", SONAR_GREEN),
        ("22:30:08", "EVP", "音声異常をキャプチャ", SONAR_YELLOW),
        ("22:29:55", "気圧", "気圧の急降下", SONAR_GREEN),
    ]
    for i, (time, typ, desc, color) in enumerate(log_entries):
        ly = log_y + 35 + i * 32
        draw.rectangle([50, ly - 2, W - 50, ly + 26], fill=(color[0] // 20, color[1] // 20, color[2] // 20))
        add_text(draw, time, 60, ly, size=16, color=SONAR_GREEN_DIM)
        add_text(draw, typ, 220, ly, size=16, color=color)
        add_text(draw, desc, 330, ly, size=14, color=(color[0] // 2, color[1] // 2, color[2] // 2))

    # Button
    btn_y = 1900
    draw.rounded_rectangle([350, btn_y, 940, btn_y + 70], radius=10,
                           outline=SONAR_RED, width=2)
    add_text(draw, "スキャン停止", 645, btn_y + 20, size=28, color=SONAR_RED, anchor="mt")

    add_scanlines(img)
    img.save(os.path.join(OUTPUT_DIR, "screenshot_04_japanese.png"))
    print("Generated: screenshot_04_japanese.png")


if __name__ == "__main__":
    screenshot_main_scanning()
    screenshot_critical_detection()
    screenshot_calibrating()
    screenshot_japanese()
    print(f"\nAll screenshots saved to {OUTPUT_DIR}")
