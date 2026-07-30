import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

# Ensure output directory exists
OUTPUT_DIR = "google_play_assets"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Colors
BG_DARK = (14, 8, 24, 255)
BG_VIGNETTE = (27, 14, 42, 255)
ACCENT_YELLOW = (245, 184, 0, 255)
ACCENT_GREEN = (34, 197, 94, 255)
ACCENT_RED = (239, 68, 68, 255)
TEXT_WHITE = (255, 255, 255, 255)
TEXT_MUTED = (180, 175, 200, 255)
CARD_BG_LIGHT = (248, 249, 250, 255)
CARD_BORDER = (230, 233, 240, 255)

# Try loading fonts
def get_font(size, bold=False):
    font_names = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNS.ttf",
        "/Library/Fonts/Arial.ttf"
    ]
    for name in font_names:
        if os.path.exists(name):
            try:
                return ImageFont.truetype(name, size)
            except Exception:
                continue
    return ImageFont.load_default()

FONT_TITLE_LARGE = get_font(64, bold=True)
FONT_TITLE_MED = get_font(48, bold=True)
FONT_SUBTITLE = get_font(28, bold=False)
FONT_BODY = get_font(22, bold=False)
FONT_BOLD = get_font(24, bold=True)
FONT_SMALL = get_font(18, bold=False)
FONT_FEATURE_TITLE = get_font(40, bold=True)

# Helper: Draw Radial Gradient Background
def create_background(width, height):
    base = Image.new('RGBA', (width, height), BG_DARK)
    glow = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw_glow = ImageDraw.Draw(glow)
    
    # Center ambient glows
    cx1, cy1 = int(width * 0.3), int(height * 0.4)
    cx2, cy2 = int(width * 0.7), int(height * 0.6)
    
    max_r = int(max(width, height) * 0.6)
    for r in range(max_r, 0, -10):
        factor = (1 - r / max_r) ** 2
        a = int(60 * factor)
        draw_glow.ellipse((cx1 - r, cy1 - r, cx1 + r, cy1 + r), fill=(80, 40, 140, a))
        draw_glow.ellipse((cx2 - r, cy2 - r, cx2 + r, cy2 + r), fill=(180, 120, 30, int(35 * factor)))

    base = Image.alpha_composite(base, glow)
    draw = ImageDraw.Draw(base)

    # Decorative stars / sparkles
    stars = [
        (int(width * 0.08), int(height * 0.15), 18, (245, 184, 0, 200)),
        (int(width * 0.92), int(height * 0.12), 24, (34, 197, 94, 200)),
        (int(width * 0.88), int(height * 0.85), 20, (239, 68, 68, 200)),
        (int(width * 0.06), int(height * 0.78), 22, (255, 255, 255, 180)),
        (int(width * 0.50), int(height * 0.06), 16, (245, 184, 0, 180)),
    ]
    for sx, sy, size, col in stars:
        draw_star(draw, sx, sy, size, col)

    return base

def draw_star(draw, cx, cy, size, color):
    # 4-point star burst
    pts = [
        (cx, cy - size), (cx + size//4, cy - size//4),
        (cx + size, cy), (cx + size//4, cy + size//4),
        (cx, cy + size), (cx - size//4, cy + size//4),
        (cx - size, cy), (cx - size//4, cy - size//4)
    ]
    draw.polygon(pts, fill=color)

# Draw Rounded Rect Helper
def draw_rounded_rect(draw, bbox, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)

# Render App Logo with Text
def get_worqly_branding(scale=1.0):
    logo_path = "worqly_logo.png"
    if os.path.exists(logo_path):
        logo_img = Image.open(logo_path).convert("RGBA")
        target_size = int(60 * scale)
        logo_img = logo_img.resize((target_size, target_size), Image.Resampling.LANCZOS)
    else:
        logo_img = Image.new("RGBA", (int(60*scale), int(60*scale)), (0,0,0,0))
    
    font_brand = get_font(int(36 * scale), bold=True)
    font_sub = get_font(int(14 * scale), bold=True)
    
    # Canvas for logo + text
    bw, bh = int(260 * scale), int(70 * scale)
    brand_canvas = Image.new("RGBA", (bw, bh), (0,0,0,0))
    brand_canvas.paste(logo_img, (0, 0), logo_img)
    
    bdraw = ImageDraw.Draw(brand_canvas)
    tx = int(72 * scale)
    bdraw.text((tx, int(4 * scale)), "worqly", font=font_brand, fill=(255, 255, 255, 255))
    bdraw.text((tx, int(44 * scale)), "WORK  +  ORG", font=font_sub, fill=(180, 180, 200, 255))
    
    return brand_canvas

# UI Screen 1 Generator: Enquiry Tracker
def render_ui_enquiry_tracker(w=450, h=950):
    ui = Image.new("RGBA", (w, h), (245, 247, 250, 255))
    draw = ImageDraw.Draw(ui)
    
    # Status bar
    font_st = get_font(14, bold=True)
    font_head = get_font(22, bold=True)
    font_card_t = get_font(18, bold=True)
    font_sub = get_font(14)
    font_badge = get_font(12, bold=True)
    
    draw.text((20, 12), "2:54", font=font_st, fill=(0, 0, 0, 255))
    draw.text((w-70, 12), "📶 🔋 100%", font=font_st, fill=(0, 0, 0, 255))
    
    # App Bar
    draw.text((20, 48), "Enquiry Tracker", font=font_head, fill=(0, 0, 0, 255))
    draw.text((w-40, 48), "📊", font=font_head, fill=(0, 0, 0, 255))
    
    # Search Box
    draw_rounded_rect(draw, (20, 95, w-20, 140), 12, fill=(255,255,255,255), outline=(220,225,230,255))
    draw.text((36, 107), "🔍   Search by client, ID, phone...", font=font_sub, fill=(160, 165, 175, 255))
    
    # Filter Chips
    chips = [("All", True), ("In Progress", False), ("Settled", False), ("Executed", False)]
    cx = 20
    for title, active in chips:
        bg = (254, 243, 199, 255) if active else (255, 255, 255, 255)
        border = (245, 184, 0, 255) if active else (220, 225, 230, 255)
        tc = (180, 120, 0, 255) if active else (100, 100, 110, 255)
        cw = len(title) * 9 + 28
        draw_rounded_rect(draw, (cx, 155, cx+cw, 188), 16, fill=bg, outline=border)
        draw.text((cx+14, 163), title, font=font_sub, fill=tc)
        cx += cw + 10

    # Card 1: Jeddah Coffee Roasters
    def draw_enquiry_card(top_y, id_code, service, status, client, phone, date, days, loc, offered, agreed, rating):
        draw_rounded_rect(draw, (16, top_y, w-16, top_y+320), 18, fill=(255,255,255,255), outline=(230,235,240,255))
        # Top line
        draw_rounded_rect(draw, (28, top_y+16, 85, top_y+40), 6, fill=(254, 243, 199, 255))
        draw.text((36, top_y+20), id_code, font=font_badge, fill=(217, 119, 6, 255))
        draw.text((95, top_y+20), service, font=font_sub, fill=(100, 100, 120, 255))
        
        # Status badge
        draw_rounded_rect(draw, (w-115, top_y+16, w-28, top_y+40), 12, fill=(220, 252, 231, 255), outline=(134, 239, 172, 255))
        draw.text((w-104, top_y+20), f"• {status}", font=font_badge, fill=(21, 128, 61, 255))
        
        # Client name & Phone
        draw.text((28, top_y+56), client, font=font_card_t, fill=(15, 23, 42, 255))
        draw_rounded_rect(draw, (w-155, top_y+54, w-28, top_y+78), 12, fill=(240, 253, 244, 255), outline=(187, 247, 208, 255))
        draw.text((w-146, top_y+58), f"💬 {phone}", font=font_badge, fill=(22, 163, 74, 255))
        
        # Info pills
        pills = [f"📅 {date}", f"⏱️ {days}", f"🇸🇦 {loc}"]
        px = 28
        for p in pills:
            pw = len(p)*7 + 20
            draw_rounded_rect(draw, (px, top_y+94, px+pw, top_y+118), 8, fill=(241, 245, 249, 255))
            draw.text((px+10, top_y+98), p, font=font_badge, fill=(71, 85, 105, 255))
            px += pw + 8
            
        # Amount box
        draw_rounded_rect(draw, (28, top_y+132, w-28, top_y+230), 12, fill=(248, 250, 252, 255))
        draw.text((44, top_y+144), "OFFERED", font=font_badge, fill=(148, 163, 184, 255))
        draw.text((44, top_y+164), f"SAR {offered}", font=FONT_BOLD, fill=(15, 23, 42, 255))
        
        draw.text((150, top_y+144), "AGREED", font=font_badge, fill=(148, 163, 184, 255))
        draw.text((150, top_y+164), f"SAR {agreed}", font=FONT_BOLD, fill=(22, 163, 74, 255))
        
        if rating:
            draw_rounded_rect(draw, (w-130, top_y+152, w-44, top_y+188), 12, fill=(220, 252, 231, 255))
            draw.text((w-118, top_y+161), f"★ {rating}", font=font_badge, fill=(21, 128, 61, 255))
            
        # Footer line
        draw.text((44, top_y+250), "👤 Omar Bakr", font=font_sub, fill=(100, 116, 139, 255))
        draw.text((180, top_y+250), "🏢 No office", font=font_sub, fill=(100, 116, 139, 255))

    draw_enquiry_card(205, "R 004", "Muqeem Service (Sharika)", "Settled", "Jeddah Coffee Roasters", "+966505556667", "13 Jun 2026", "5 days", "Saudi Arabia", "500", "500", "Excellent")
    draw_enquiry_card(540, "R 006", "Absher", "Settled", "Dammam Trading House", "+966502233445", "11 Jun 2026", "5 days", "Saudi Arabia", "700", "500", None)
    
    # FAB Floating Button
    draw_rounded_rect(draw, (w-200, h-140, w-20, h-85), 24, fill=ACCENT_YELLOW)
    draw.text((w-175, h-120), "+  New Enquiry", font=FONT_BOLD, fill=(255,255,255,255))
    
    # Bottom Nav Bar
    draw_rounded_rect(draw, (0, h-70, w, h), 0, fill=(255,255,255,255), outline=(230,230,230,255))
    nav_items = [("Home", "🏠"), ("Leaves", "📅"), ("Works", "📋"), ("Profile", "👤"), ("Enquiries", "🎯")]
    nw = w // 5
    for idx, (label, icon) in enumerate(nav_items):
        nx = idx * nw + nw//2 - 15
        is_active = (idx == 4)
        col = (15, 23, 42, 255) if is_active else (148, 163, 184, 255)
        draw.text((nx+4, h-60), icon, font=FONT_BODY, fill=col)
        draw.text((nx-10, h-32), label, font=font_badge, fill=col)

    return ui

# UI Screen 2 Generator: Attendance & Dashboard
def render_ui_attendance_home(w=450, h=950):
    ui = Image.new("RGBA", (w, h), (245, 247, 250, 255))
    draw = ImageDraw.Draw(ui)
    
    # Top Header Dark Area
    draw_rounded_rect(draw, (0, 0, w, 190), 28, fill=(15, 15, 20, 255))
    
    font_st = get_font(14, bold=True)
    font_name = get_font(24, bold=True)
    font_sub = get_font(14)
    font_card_t = get_font(18, bold=True)
    font_bold = get_font(20, bold=True)
    font_badge = get_font(13, bold=True)
    
    draw.text((20, 12), "2:53", font=font_st, fill=(255, 255, 255, 255))
    draw.text((w-70, 12), "📶 🔋 100%", font=font_st, fill=(255, 255, 255, 255))
    
    # Profile avatar
    draw.ellipse((20, 50, 80, 110), fill=(80, 80, 95, 255))
    draw.text((42, 68), "👤", font=font_card_t, fill=(255, 255, 255, 255))
    
    draw.text((95, 52), "Omar Bakr", font=font_name, fill=(255, 255, 255, 255))
    draw.text((95, 82), "STAFF   |   ID: C3333333", font=font_sub, fill=(180, 180, 200, 255))
    draw.text((w-70, 65), "🔔   🔤", font=font_card_t, fill=(255, 255, 255, 255))

    # Card 1: Attendance
    draw_rounded_rect(draw, (20, 140, w-20, 390), 22, fill=(255,255,255,255), outline=(230,235,240,255))
    draw.text((40, 160), "🕒   ATTENDANCE / تسجيل الحضور", font=font_card_t, fill=(70, 70, 85, 255))
    draw_rounded_rect(draw, (w-140, 155, w-40, 185), 10, fill=(245, 245, 250, 255))
    draw.text((w-128, 162), "30 Jul 2026", font=font_badge, fill=(100, 100, 120, 255))

    # Alert Box inside Attendance
    draw_rounded_rect(draw, (40, 205, w-40, 275), 12, fill=(255, 247, 237, 255), outline=(254, 215, 170, 255))
    draw.text((56, 217), "⚠️   Not Checked In", font=font_bold, fill=(194, 65, 12, 255))
    draw.text((56, 244), "Please check in to start your work shift", font=font_sub, fill=(154, 52, 18, 255))

    # Check In Button
    draw_rounded_rect(draw, (40, 295, w-40, 360), 16, fill=(15, 23, 42, 255))
    draw.text((w//2 - 95, 317), "➡️   CHECK IN / حضور", font=font_bold, fill=(255, 255, 255, 255))

    # Card 2: My Works
    draw_rounded_rect(draw, (20, 410, w-20, 640), 22, fill=(255,255,255,255), outline=(230,235,240,255))
    draw.text((40, 430), "💼   MY WORKS", font=font_card_t, fill=(15, 23, 42, 255))
    draw_rounded_rect(draw, (w-110, 425, w-40, 455), 10, fill=(241, 245, 249, 255))
    draw.text((w-98, 432), "Active", font=font_badge, fill=(51, 65, 85, 255))

    draw_rounded_rect(draw, (40, 470, w-40, 550), 12, fill=(248, 250, 252, 255))
    draw.text((56, 482), "• ASSIGNED TASKS", font=font_badge, fill=(100, 116, 139, 255))
    draw.text((56, 502), "0 Tasks Pending", font=font_bold, fill=(15, 23, 42, 255))
    draw.text((56, 526), "Check your task list for new assignments", font=font_sub, fill=(148, 163, 184, 255))

    draw_rounded_rect(draw, (40, 565, w-40, 620), 14, fill=(15, 23, 42, 255))
    draw.text((w//2 - 60, 582), "View All Works", font=font_bold, fill=(255, 255, 255, 255))

    # Card 3: Leaves
    draw_rounded_rect(draw, (20, 660, w-20, 800), 22, fill=(255,255,255,255), outline=(230,235,240,255))
    draw.text((40, 680), "📅   LEAVES", font=font_card_t, fill=(202, 138, 4, 255))
    draw.text((40, 715), "21 Days", font=font_bold, fill=(15, 23, 42, 255))
    draw.text((40, 750), "Annual Leave Balance", font=font_sub, fill=(148, 163, 184, 255))

    draw_rounded_rect(draw, (w-130, 715, w-40, 765), 14, fill=ACCENT_YELLOW)
    draw.text((w-105, 730), "Apply", font=font_bold, fill=(255, 255, 255, 255))

    # Floating "+" Action Button
    draw.ellipse((w//2 - 30, h-120, w//2 + 30, h-60), fill=(15, 23, 42, 255))
    draw.text((w//2 - 10, h-104), "+", font=get_font(32, bold=True), fill=(255, 255, 255, 255))

    # Bottom Nav Bar
    draw_rounded_rect(draw, (0, h-70, w, h), 0, fill=(255,255,255,255), outline=(230,230,230,255))
    nav_items = [("Home", "🏠"), ("Leaves", "📅"), ("Works", "📋"), ("Profile", "👤"), ("Enquiries", "🎯")]
    nw = w // 5
    for idx, (label, icon) in enumerate(nav_items):
        nx = idx * nw + nw//2 - 15
        is_active = (idx == 0)
        col = (15, 23, 42, 255) if is_active else (148, 163, 184, 255)
        draw.text((nx+4, h-60), icon, font=FONT_BODY, fill=col)
        draw.text((nx-10, h-32), label, font=font_badge, fill=col)

    return ui

# Create Realistic Mobile Device Frame containing UI Screen
def create_device_mockup(ui_image, phone_w=480, phone_h=980, radius=40):
    device = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
    ddraw = ImageDraw.Draw(device)

    # Phone Shadow
    shadow = Image.new("RGBA", (phone_w+40, phone_h+40), (0,0,0,0))
    sdraw = ImageDraw.Draw(shadow)
    draw_rounded_rect(sdraw, (20, 20, phone_w+20, phone_h+20), radius+5, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(15))
    
    # Outer device bezel (dark phone frame)
    draw_rounded_rect(ddraw, (0, 0, phone_w, phone_h), radius, fill=(25, 25, 30, 255), outline=(60, 60, 75, 255), width=3)
    
    # Inner Screen container
    border_margin = 12
    sw, sh = phone_w - border_margin*2, phone_h - border_margin*2
    resized_ui = ui_image.resize((sw, sh), Image.Resampling.LANCZOS)
    
    # Mask rounded corners of screen
    mask = Image.new("L", (sw, sh), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle((0, 0, sw, sh), radius=radius-10, fill=255)
    
    # Paste UI onto device frame
    device.paste(resized_ui, (border_margin, border_margin), mask)
    
    # Draw Dynamic Island / Camera Notch
    ddraw = ImageDraw.Draw(device)
    ddraw.rounded_rectangle((phone_w//2 - 50, border_margin + 6, phone_w//2 + 50, border_margin + 26), radius=10, fill=(10, 10, 12, 255))
    
    # Composite shadow + device
    final_mockup = Image.new("RGBA", (phone_w+40, phone_h+40), (0,0,0,0))
    final_mockup.paste(shadow, (0, 0), shadow)
    final_mockup.paste(device, (20, 20), device)
    
    return final_mockup


# -------------------------------------------------------------
# GENERATOR 1: Google Play Feature Graphic (1024 x 500 px)
# -------------------------------------------------------------
def generate_feature_graphic():
    fw, fh = 1024, 500
    bg = create_background(fw, fh)
    
    # Paste Worqly Branding
    brand = get_worqly_branding(scale=1.1)
    bg.paste(brand, (50, 45), brand)
    
    draw = ImageDraw.Draw(bg)
    
    # Main Tagline
    draw.text((50, 145), "All-in-One Service &", font=FONT_FEATURE_TITLE, fill=(255, 255, 255, 255))
    draw.text((50, 195), "Operations Manager", font=FONT_FEATURE_TITLE, fill=ACCENT_YELLOW)
    
    draw.text((50, 260), "Streamline client enquiries, staff attendance,", font=FONT_BODY, fill=TEXT_MUTED)
    draw.text((50, 290), "work orders, and team leave tracking.", font=FONT_BODY, fill=TEXT_MUTED)

    # Feature Badges
    badges = ["⚡ Real-Time Tracking", "🎯 Enquiry Management", "📅 Attendance & Leaves"]
    by = 350
    for b in badges:
        bw = len(b) * 10 + 20
        draw_rounded_rect(draw, (50, by, 50+bw, by+36), 18, fill=(30, 20, 50, 220), outline=(100, 70, 160, 255))
        draw.text((62, by+8), b, font=FONT_SMALL, fill=(255, 255, 255, 255))
        by += 44

    # Phone Mockups on Right Side
    ui1 = render_ui_enquiry_tracker(400, 850)
    mock1 = create_device_mockup(ui1, phone_w=220, phone_h=440, radius=24)
    
    ui2 = render_ui_attendance_home(400, 850)
    mock2 = create_device_mockup(ui2, phone_w=210, phone_h=420, radius=24)
    
    # Paste overlapping angled mockups
    bg.paste(mock1, (710, 45), mock1)
    bg.paste(mock2, (540, 85), mock2)
    
    # Save PNG & JPEG
    png_path = os.path.join(OUTPUT_DIR, "worqly_feature_graphic_1024x500.png")
    jpg_path = os.path.join(OUTPUT_DIR, "worqly_feature_graphic_1024x500.jpg")
    bg.save(png_path, "PNG")
    bg.convert("RGB").save(jpg_path, "JPEG", quality=95)
    print(f"✅ Generated Feature Graphic: {png_path} ({os.path.getsize(png_path)//1024} KB)")


# -------------------------------------------------------------
# GENERATOR 2: Phone Promotional Screenshots (1080 x 1920 px)
# -------------------------------------------------------------
def generate_phone_screenshots():
    sw, sh = 1080, 1920
    
    screenshots_data = [
        {
            "filename": "phone_screenshot_1_enquiries.png",
            "title_line1": "Track & Manage",
            "title_line2": "Client Enquiries",
            "highlight": "Client Enquiries",
            "subtitle": "Monitor proposals, agreed SAR amounts, and status updates in real time",
            "ui_func": render_ui_enquiry_tracker,
            "badge": "🎯 Enquiry Tracker"
        },
        {
            "filename": "phone_screenshot_2_attendance.png",
            "title_line1": "Instant Staff",
            "title_line2": "Attendance Check-In",
            "highlight": "Attendance Check-In",
            "subtitle": "One-tap check in, shift status tracking, and staff profile management",
            "ui_func": render_ui_attendance_home,
            "badge": "🕒 Staff Check-In"
        },
        {
            "filename": "phone_screenshot_3_works.png",
            "title_line1": "Assign Tasks &",
            "title_line2": "Monitor Work Orders",
            "highlight": "Monitor Work Orders",
            "subtitle": "Assign jobs, manage task lists, and track execution progress seamlessly",
            "ui_func": render_ui_attendance_home,
            "badge": "💼 Work Orders"
        },
        {
            "filename": "phone_screenshot_4_leaves.png",
            "title_line1": "Manage Team",
            "title_line2": "Leaves & Balances",
            "highlight": "Leaves & Balances",
            "subtitle": "View annual leave balances, submit leave requests, and approve on the go",
            "ui_func": render_ui_attendance_home,
            "badge": "📅 Leave Tracking"
        },
        {
            "filename": "phone_screenshot_5_overview.png",
            "title_line1": "Work + Org",
            "title_line2": "Complete Business Suite",
            "highlight": "Complete Business Suite",
            "subtitle": "All your business operations and service workflows unified in Worqly",
            "ui_func": render_ui_enquiry_tracker,
            "badge": "🚀 All-In-One"
        }
    ]

    for item in screenshots_data:
        canvas = create_background(sw, sh)
        draw = ImageDraw.Draw(canvas)
        
        # Branding top left
        brand = get_worqly_branding(scale=1.4)
        canvas.paste(brand, (70, 70), brand)
        
        # Top Feature Badge
        draw_rounded_rect(draw, (70, 175, 340, 225), 20, fill=(40, 25, 65, 230), outline=(130, 90, 200, 255))
        draw.text((92, 190), item["badge"], font=FONT_BOLD, fill=ACCENT_YELLOW)
        
        # Main Headings
        ty = 250
        draw.text((70, ty), item["title_line1"], font=get_font(72, bold=True), fill=TEXT_WHITE)
        draw.text((70, ty + 85), item["title_line2"], font=get_font(72, bold=True), fill=ACCENT_YELLOW if item["highlight"] in item["title_line2"] else ACCENT_GREEN)
        
        # Subtitle
        draw.text((70, ty + 180), item["subtitle"], font=get_font(30), fill=TEXT_MUTED)

        # Phone Frame Presentation Card
        # Render dynamic light background card frame behind phone
        card_x1, card_y1, card_x2, card_y2 = 70, 560, sw-70, sh-70
        draw_rounded_rect(draw, (card_x1, card_y1, card_x2, card_y2), 48, fill=(248, 249, 252, 255), outline=(220, 225, 235, 255), width=2)
        
        # Render App UI Inside Frame
        ui_img = item["ui_func"](520, 1120)
        phone_mockup = create_device_mockup(ui_img, phone_w=680, phone_h=1380, radius=50)
        
        # Paste Mockup Centered on Card
        mx = (sw - phone_mockup.width) // 2
        my = card_y1 + 40
        canvas.paste(phone_mockup, (mx, my), phone_mockup)

        # Save Screenshot PNG
        out_path = os.path.join(OUTPUT_DIR, item["filename"])
        canvas.save(out_path, "PNG")
        print(f"✅ Generated Phone Screenshot: {out_path}")


# -------------------------------------------------------------
# GENERATOR 3: Tablet Promotional Screenshots (7-inch & 10-inch)
# -------------------------------------------------------------
def generate_tablet_screenshots():
    # 10-Inch Tablet Screenshot (2560 x 1600 px - Landscape)
    tw, th = 2560, 1600
    canvas10 = create_background(tw, th)
    draw10 = ImageDraw.Draw(canvas10)
    
    brand = get_worqly_branding(scale=1.6)
    canvas10.paste(brand, (100, 90), brand)

    # Left Headline
    draw10.text((100, 250), "Complete Business & Team", font=get_font(76, bold=True), fill=TEXT_WHITE)
    draw10.text((100, 340), "Management on Tablet", font=get_font(76, bold=True), fill=ACCENT_YELLOW)
    
    draw10.text((100, 440), "Track enquiries, manage staff check-ins, leaves,", font=get_font(34), fill=TEXT_MUTED)
    draw10.text((100, 490), "and work execution from a high-resolution dashboard.", font=get_font(34), fill=TEXT_MUTED)

    # Tablet Mockup Card
    ui_enq = render_ui_enquiry_tracker(580, 1100)
    mock_enq = create_device_mockup(ui_enq, phone_w=620, phone_h=1200, radius=44)
    
    ui_att = render_ui_attendance_home(580, 1100)
    mock_att = create_device_mockup(ui_att, phone_w=620, phone_h=1200, radius=44)

    # Display side-by-side tablet displays
    canvas10.paste(mock_enq, (1180, 260), mock_enq)
    canvas10.paste(mock_att, (1840, 260), mock_att)

    t10_path = os.path.join(OUTPUT_DIR, "tablet_screenshot_10inch_2560x1600.png")
    canvas10.save(t10_path, "PNG")
    print(f"✅ Generated 10-Inch Tablet Screenshot: {t10_path}")

    # 7-Inch Tablet Screenshot (1536 x 2048 px - Portrait)
    t7w, t7h = 1536, 2048
    canvas7 = create_background(t7w, t7h)
    draw7 = ImageDraw.Draw(canvas7)
    
    brand7 = get_worqly_branding(scale=1.5)
    canvas7.paste(brand7, (80, 80), brand7)

    draw7.text((80, 230), "Streamlined Workflow &", font=get_font(74, bold=True), fill=TEXT_WHITE)
    draw7.text((80, 320), "Service Operations", font=get_font(74, bold=True), fill=ACCENT_GREEN)
    
    draw7.text((80, 420), "Empower your operations with real-time updates,", font=get_font(32), fill=TEXT_MUTED)
    draw7.text((80, 465), "client agreements, and staff attendance tracking.", font=get_font(32), fill=TEXT_MUTED)

    # Card & Device Frame
    draw_rounded_rect(draw7, (80, 560, t7w-80, t7h-80), 48, fill=(248, 249, 252, 255), outline=(220, 225, 235, 255), width=2)
    
    ui7 = render_ui_enquiry_tracker(650, 1300)
    mock7 = create_device_mockup(ui7, phone_w=820, phone_h=1580, radius=52)
    
    mx7 = (t7w - mock7.width) // 2
    canvas7.paste(mock7, (mx7, 600), mock7)

    t7_path = os.path.join(OUTPUT_DIR, "tablet_screenshot_7inch_1536x2048.png")
    canvas7.save(t7_path, "PNG")
    print(f"✅ Generated 7-Inch Tablet Screenshot: {t7_path}")


if __name__ == "__main__":
    print("🚀 Starting Google Play Store Asset Generation...")
    generate_feature_graphic()
    generate_phone_screenshots()
    generate_tablet_screenshots()
    print("🎉 All Play Store Assets successfully generated!")
