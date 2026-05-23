import math, pathlib

R, sw, cx, cy = 58, 14, 300, 170
half = math.pi * (R + sw//2)

lines = []
lines.append('<?xml version="1.0" encoding="UTF-8"?>')
lines.append('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400">')
lines.append('<rect width="600" height="400" fill="#ffffff"/>')

lines.append(f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="none" stroke="#1A1A2E" stroke-width="{sw}" stroke-dasharray="{half:.2f} {half:.2f}" stroke-linecap="butt"/>')
lines.append(f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="none" stroke="#00D4AA" stroke-width="{sw}" stroke-dasharray="{half:.2f} {half:.2f}" stroke-dashoffset="-{half:.2f}" stroke-linecap="butt"/>')

for deg in [25, 60, 95, 130, 155]:
    a = math.radians(deg)
    r2 = R + sw//2
    x, y = cx + r2 * math.cos(a), cy + r2 * math.sin(a)
    lines.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5" fill="#00D4AA"/>')

r3 = R - 6
lines.append(f'<path d="M {cx-r3*0.866:.1f},{cy-r3*0.5:.1f} A {r3},{r3} 0 0,0 {cx-r3*0.5:.1f},{cy+r3*0.866:.1f}" fill="none" stroke="#00D4AA" stroke-width="2.5" stroke-linecap="round"/>')

lines.append('<text x="300" y="290" text-anchor="middle" font-family="Inter,Segoe UI,Helvetica,Arial,sans-serif" font-weight="700" font-size="42" fill="#1A1A2E" letter-spacing="4">OneCom</text>')
lines.append('<text x="300" y="325" text-anchor="middle" font-family="Inter,Segoe UI,Helvetica,Arial,sans-serif" font-weight="300" font-size="13" fill="#999" letter-spacing="7">iOS APPS + AI AGENTS</text>')
lines.append('<circle cx="428" cy="290" r="2.5" fill="#00D4AA"/>')
lines.append('</svg>')

pathlib.Path("E:/onecom/assets/onecom-logo.svg").write_text("\n".join(lines), encoding="utf-8")
print("Logo generated: onecom-logo.svg")
