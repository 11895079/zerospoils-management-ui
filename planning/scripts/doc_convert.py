#!/usr/bin/env python3
"""Convert a .docx Word document to Markdown.

Uses `mammoth` to convert the .docx to HTML and `html2text` to convert
the HTML to Markdown. Images are extracted to an images directory and
referenced relatively from the generated Markdown file.

Example:
    python scripts/doc_convert.py input.docx -o output.md --images-dir assets/img
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Tuple

import mammoth
import html2text


def convert_docx_to_md(
    input_path: Path, output_path: Path | None = None, images_dir: Path | None = None
) -> Tuple[Path, Path]:
    input_path = Path(input_path)
    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    if output_path is None:
        output_path = input_path.with_suffix(".md")
    output_path = Path(output_path)

    if images_dir is None:
        images_dir = output_path.parent / (output_path.stem + "_images")
    images_dir = Path(images_dir)
    images_dir.mkdir(parents=True, exist_ok=True)

    def _convert_image(image):
        content_type = image.content_type
        ext = {
            "image/png": ".png",
            "image/jpeg": ".jpg",
            "image/gif": ".gif",
            "image/svg+xml": ".svg",
        }.get(content_type, "")

        idx = _convert_image.counter
        _convert_image.counter += 1

        filename = f"image_{idx}{ext}"
        path = images_dir / filename
        with open(path, "wb") as f:
            f.write(image.read())

        # Return a relative URL from the markdown file directory
        rel = os.path.relpath(path, output_path.parent).replace("\\", "/")
        return {"src": rel}

    _convert_image.counter = 1

    with open(input_path, "rb") as f:
        result = mammoth.convert_to_html(f, convert_image=mammoth.images.inline(_convert_image))
        html = result.value
        messages = result.messages

    if messages:
        for msg in messages:
            print("[mammoth]", msg, file=sys.stderr)

    h = html2text.HTML2Text()
    h.ignore_images = False
    h.body_width = 0
    md = h.handle(html)

    with open(output_path, "w", encoding="utf-8") as out_fp:
        out_fp.write(md)

    return output_path, images_dir


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Convert .docx to Markdown")
    p.add_argument("input", help="Path to input .docx file")
    p.add_argument("-o", "--output", help="Path to output .md file")
    p.add_argument("--images-dir", help="Directory to write extracted images")
    return p


def main(argv=None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    parser = _build_parser()
    args = parser.parse_args(argv)

    input_path = Path(args.input)
    output_path = Path(args.output) if args.output else None
    images_dir = Path(args.images_dir) if args.images_dir else None

    try:
        out, imgs = convert_docx_to_md(input_path, output_path, images_dir)
        print(f"Wrote: {out}")
        print(f"Images: {imgs}")
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
