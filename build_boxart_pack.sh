#!/usr/bin/env bash
# =============================================================================
# SC64 Boxart Pack Builder
# Run from anywhere -- does not need to be on the SD card.
#
# Builds a shareable zip of N64 boxart for ALL known titles (US + JP + EU)
# structured as menu/metadata/X/X/X/X/boxart_front.png so recipients just
# unzip into the root of their SC64 SD card.
#
# Sources:
#   1. Official n64-flashcart-menu-metadata repo (primary)
#   2. GameTDB (https://art.gametdb.com) as fallback for missing titles
#
# Requirements: git, python3, curl, Pillow (pip install Pillow)
# Usage: bash build_boxart_pack.sh
# Output: sc64_boxart_pack.zip in the current directory
# =============================================================================

set -euo pipefail

TMP_REPO="/tmp/n64_metadata_repo"
TMP_PACK="/tmp/sc64_boxart_pack"
OUTPUT_ZIP="./sc64_boxart_pack.zip"

METADATA_REPO="https://github.com/n64-tools/n64-flashcart-menu-metadata.git"

# GameTDB cover URL format:
# https://art.gametdb.com/N64/cover/{REGION}/{CODE}.png
# Region codes: US, JA, EU
GAMETDB_BASE="https://art.gametdb.com/N64/cover"

# Target dimensions per the SC64 menu spec
SIZE_NTSC="158x112"   # US and EU (landscape)
SIZE_NTSC_W=158
SIZE_NTSC_H=112
SIZE_JP_W=112         # JP (portrait)
SIZE_JP_H=158

echo ""
echo "=== STEP 1: Install Pillow if needed ==="
python3 -c "import PIL" 2>/dev/null || pip3 install Pillow --quiet --break-system-packages

echo ""
echo "=== STEP 2: Clone/update official metadata repo ==="
if [[ -d "$TMP_REPO" ]]; then
  echo "Pulling latest..."
  git -C "$TMP_REPO" pull --quiet
else
  echo "Cloning..."
  git clone --depth=1 --quiet "$METADATA_REPO" "$TMP_REPO"
fi

echo ""
echo "=== STEP 3: Extract and resize boxart_front.png from official metadata ==="
rm -rf "$TMP_PACK"
mkdir -p "$TMP_PACK/menu/metadata"

# Only copy boxart_front.png and resize to SC64 spec.
# The official repo contains full-res images plus back/top/gamepak views
# which balloon the zip to 1.6GB -- we only need the front cover at thumbnail size.
python3 << 'PYEOF'
import os
from pathlib import Path
from PIL import Image

SRC = "/tmp/n64_metadata_repo/metadata"
DST = "/tmp/sc64_boxart_pack/menu/metadata"

REGION_SIZE = {
    "E": (158, 112), "P": (158, 112), "X": (158, 112),
    "D": (158, 112), "F": (158, 112), "S": (158, 112),
    "I": (158, 112), "H": (158, 112), "M": (158, 112),
    "J": (112, 158),
}

copied = 0
for root, dirs, files in os.walk(SRC):
    if "boxart_front.png" not in files:
        continue
    parts = Path(root).parts
    if len(parts) < 4:
        continue
    code = "".join(parts[-4:])
    if len(code) != 4:
        continue

    region_char = code[3]
    w, h = REGION_SIZE.get(region_char, (158, 112))

    src_file = os.path.join(root, "boxart_front.png")
    dst_dir = os.path.join(DST, *list(code))
    dst_file = os.path.join(dst_dir, "boxart_front.png")
    os.makedirs(dst_dir, exist_ok=True)

    try:
        img = Image.open(src_file).convert("RGBA")
        img = img.resize((w, h), Image.LANCZOS)
        img.save(dst_file, "PNG", optimize=True)
        copied += 1
    except Exception as e:
        print(f"  [SKIP] {code}: {e}")

print(f"  Resized and staged {copied} official boxart images.")
PYEOF

echo ""
echo "=== STEP 4: Fetch all game codes from GameTDB XML database ==="

python3 << 'PYEOF'
import os, urllib.request, urllib.error, zipfile, io, xml.etree.ElementTree as ET
from PIL import Image

TMP_PACK = "/tmp/sc64_boxart_pack"
METADATA_DIR = f"{TMP_PACK}/menu/metadata"
GAMETDB_BASE = "https://art.gametdb.com/N64/cover"
N64TDB_URL = "https://www.gametdb.com/n64tdb.zip"
HEADERS = {"User-Agent": "SC64-BoxartBuilder/1.0 (glazed-watermelon)"}

REGION_MAP = {
    "US":  ("US",  158, 112),
    "JA":  ("JA",  112, 158),
    "JP":  ("JA",  112, 158),
    "EU":  ("EU",  158, 112),
    "EN":  ("EU",  158, 112),
    "AU":  ("AU",  158, 112),
    "FR":  ("FR",  158, 112),
    "DE":  ("DE",  158, 112),
    "ES":  ("ES",  158, 112),
    "IT":  ("IT",  158, 112),
    "NL":  ("NL",  158, 112),
    "PT":  ("PT",  158, 112),
    "KO":  ("KO",  158, 112),
    "ZHCN":("ZHCN",158, 112),
    "ZHTW":("ZHTW",158, 112),
}

# Map 4-char code last byte to GameTDB region
CODE_REGION_MAP = {
    "E": "US", "J": "JA", "P": "EU", "X": "EU",
    "D": "DE", "F": "FR", "S": "ES", "I": "IT",
    "H": "NL", "U": "AU", "M": "US",
}

def resize_and_save(data, dest, w, h):
    try:
        img = Image.open(io.BytesIO(data)).convert("RGBA")
        img = img.resize((w, h), Image.LANCZOS)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        img.save(dest, "PNG", optimize=True)
        return True
    except Exception as e:
        return False

def fetch_url(url):
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=15) as r:
            if r.status == 200:
                return r.read()
    except Exception:
        pass
    return None

# Step 4a: Download GameTDB N64 XML database
print("  Downloading GameTDB N64 XML database...")
try:
    req = urllib.request.Request(N64TDB_URL, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=60) as r:
        zip_data = r.read()
    with zipfile.ZipFile(io.BytesIO(zip_data)) as z:
        xml_name = next(n for n in z.namelist() if n.endswith(".xml"))
        xml_data = z.read(xml_name)
    print(f"  Downloaded {xml_name} ({len(xml_data)//1024}KB)")
except Exception as e:
    print(f"  WARNING: Could not download GameTDB XML: {e}")
    print("  Falling back to hardcoded code list.")
    xml_data = None

# Parse XML and extract all game codes with their regions
all_codes = {}  # code -> (gametdb_region, w, h)

if xml_data:
    try:
        root = ET.fromstring(xml_data)
        for game in root.findall(".//game"):
            id_el = game.find("id")
            region_el = game.find("region")
            if id_el is None or region_el is None:
                continue
            code = (id_el.text or "").strip()
            region = (region_el.text or "").strip()
            if len(code) != 4:
                continue
            # Get dimensions from region
            region_char = code[3]
            gametdb_region = CODE_REGION_MAP.get(region_char, "US")
            w, h = REGION_MAP.get(gametdb_region, ("US", 158, 112))[1:]
            all_codes[code] = (gametdb_region, w, h)
        print(f"  Found {len(all_codes)} game codes in GameTDB N64 database.")
    except Exception as e:
        print(f"  WARNING: XML parse error: {e}")

# Step 4b: Find which codes already have art from official repo
existing = set()
for root_dir, dirs, files in os.walk(METADATA_DIR):
    if "boxart_front.png" in files:
        from pathlib import Path
        parts = Path(root_dir).parts
        if len(parts) >= 4:
            code = "".join(parts[-4:])
            if len(code) == 4:
                existing.add(code)

print(f"  Official metadata already covers {len(existing)} codes.")
missing_codes = {c: v for c, v in all_codes.items() if c not in existing}
print(f"  Fetching {len(missing_codes)} remaining codes from GameTDB...")

downloaded = 0
failed = 0

for code, (gametdb_region, w, h) in sorted(missing_codes.items()):
    dest = os.path.join(METADATA_DIR, code[0], code[1], code[2], code[3], "boxart_front.png")
    if os.path.exists(dest):
        continue

    url = f"{GAMETDB_BASE}/{gametdb_region}/{code}.png"
    data = fetch_url(url)

    if data and resize_and_save(data, dest, w, h):
        print(f"  [GET] {code} ({gametdb_region})  {url}")
        downloaded += 1
    else:
        failed += 1

print(f"\n  GameTDB fetch complete:")
print(f"    Already covered by official repo: {len(existing)}")
print(f"    Downloaded from GameTDB:          {downloaded}")
print(f"    Not found / failed:               {failed}")
print(f"    Total codes in database:          {len(all_codes)}")
PYEOF

echo ""
echo "=== STEP 5: Package into zip ==="
rm -f "$OUTPUT_ZIP"
cd "$TMP_PACK"
zip -r -q "$OLDPWD/$OUTPUT_ZIP" menu/
cd "$OLDPWD"

SIZE=$(du -sh "$OUTPUT_ZIP" | cut -f1)
echo "  Done! Pack size: $SIZE"
echo ""
echo "=== DONE ==="
echo "Output: $OUTPUT_ZIP"
echo ""
echo "Recipients unzip into the root of their SC64 SD card:"
echo "  unzip sc64_boxart_pack.zip -d /Volumes/SUMCART64"
