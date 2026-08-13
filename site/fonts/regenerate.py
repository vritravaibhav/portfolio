#!/usr/bin/env python3
"""Refresh the self-hosted fonts.

Downloads the latin-subset woff2 files from Google Fonts into this directory
and rewrites ../fonts.css. Run it from anywhere:

    python3 site/fonts/regenerate.py

Add a weight to SPECS below only when styles.css actually references it —
every face here is bytes the visitor downloads.
"""
import re, subprocess, pathlib, sys

OUT = pathlib.Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

# Only the weights styles.css actually references.
SPECS = [
    ("Syne", "https://fonts.googleapis.com/css2?family=Syne:wght@600;700&display=swap"),
    ("IBM+Plex+Sans", "https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,400;1,400&display=swap"),
    ("IBM+Plex+Mono", "https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;700&display=swap"),
]

BLOCK = re.compile(r"/\*\s*(?P<subset>[\w\-\[\]]+)\s*\*/\s*@font-face\s*\{(?P<body>[^}]+)\}")

def field(body, name):
    m = re.search(rf"{name}:\s*([^;]+);", body)
    return m.group(1).strip() if m else None

faces = []
for label, url in SPECS:
    css = subprocess.run(["curl", "-sSL", "-A", UA, url],
                         capture_output=True, text=True, check=True).stdout
    if not css.strip():
        sys.exit(f"empty CSS for {label}")
    for m in BLOCK.finditer(css):
        if m.group("subset") != "latin":
            continue          # skip cyrillic / greek / vietnamese / latin-ext
        body = m.group("body")
        family = field(body, "font-family").strip('"\'')
        weight = field(body, "font-weight")
        style = field(body, "font-style") or "normal"
        src = re.search(r"url\((https://[^)]+\.woff2)\)", body).group(1)

        slug = family.lower().replace(" ", "-")
        fname = f"{slug}-{weight}{'-italic' if style == 'italic' else ''}.woff2"
        subprocess.run(["curl", "-sSL", "-o", str(OUT / fname), src], check=True)
        faces.append((family, weight, style, fname))
        print(f"  {fname:38} <- {family} {weight} {style}")

lines = ["/* Self-hosted latin subsets. Regenerate with site/fonts/regenerate.py. */"]
for family, weight, style, fname in faces:
    lines += [
        "@font-face {",
        f"  font-family: '{family}';",
        f"  font-style: {style};",
        f"  font-weight: {weight};",
        "  font-display: swap;",
        f"  src: url('fonts/{fname}') format('woff2');",
        "}",
    ]
(OUT.parent / "fonts.css").write_text("\n".join(lines) + "\n")
print(f"\n{len(faces)} faces -> site/fonts.css")
