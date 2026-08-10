"""
One-shot WebP converter for Plöntukrot assets.
Creates .webp copies alongside .png — NEVER touches originals.
Run: python tools/compress_images.py
"""
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
WEBP_QUALITY = 85


def format_size(size_bytes: int) -> str:
    if size_bytes >= 1_000_000:
        return f"{size_bytes / 1_000_000:.1f} MB"
    elif size_bytes >= 1_000:
        return f"{size_bytes / 1_000:.0f} KB"
    return f"{size_bytes} B"


def convert_to_webp(png_path: Path, quality: int = WEBP_QUALITY) -> tuple[int, int]:
    """Convert PNG to WebP, preserving alpha. Returns (png_size, webp_size)."""
    png_size = png_path.stat().st_size
    img = Image.open(png_path)
    # Preserve original mode — never force RGB conversion
    webp_path = png_path.with_suffix(".webp")
    img.save(webp_path, "WEBP", quality=quality, method=6, lossless=False)
    webp_size = webp_path.stat().st_size
    return png_size, webp_size


def main():
    png_files = sorted(ASSETS_DIR.rglob("*.png"))
    if not png_files:
        print("No PNG files found in assets/")
        return

    print("=" * 60)
    print("  Plöntukrot — WebP Converter (originals untouched)")
    print("=" * 60)
    print(f"\nFound {len(png_files)} PNG files\n")

    total_before = 0
    total_webp = 0

    for png_path in png_files:
        rel = png_path.relative_to(ASSETS_DIR)
        orig_size = png_path.stat().st_size

        try:
            png_sz, webp_sz = convert_to_webp(png_path)
        except Exception as e:
            print(f"  SKIP {rel}: {e}")
            continue

        total_before += orig_size
        total_webp += webp_sz
        pct = (1 - webp_sz / orig_size) * 100 if orig_size else 0

        print(f"  {rel}")
        print(f"    {format_size(orig_size)} → {format_size(webp_sz)}  ({pct:+.0f}%)")

    print("\n" + "=" * 60)
    print("  SUMMARY")
    print("=" * 60)
    print(f"  Total PNG:   {format_size(total_before)}")
    print(f"  Total WebP:  {format_size(total_webp)}  ({format_size(total_before - total_webp)} saved)")
    print(f"\n  Originals untouched. WebP copies alongside.")
    print(f"  Update Image.asset() paths from .png to .webp in lib/.")


if __name__ == "__main__":
    main()
