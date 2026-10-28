# PDFLab Crop & OCR

**Standalone Tcl/Tk desktop utility for extracting figures, tables and text from technical PDF documents.**

[Giux-Lab website](https://giux-lab.it/) · [Full original guide](README_PDFLab_Crop_OCR.md) · [GPL-3.0-or-later license](LICENSE)

PDFLab Crop & OCR is intended for scanned datasheets, technical manuals and historical scientific literature. It allows precise high-resolution cropping and OCR of individual regions, as well as searchable whole-document PDF generation.

## Main features

- Open multipage PDFs; render pages at 150, 200, 300, 400 or 600 DPI.
- Zoom around the mouse pointer; pan using the keyboard or middle-button drag.
- Create, move and resize rectangular selections using eight resize handles.
- Export selected graphs, diagrams or tables to **high-resolution PNG**, independent of the preview zoom.
- Run OCR on a selection, or export **PNG + UTF-8 TXT** together.
- Run OCRmyPDF on a complete document to produce a searchable PDF copy.
- OCR languages: English (`eng`), Simplified Chinese + English (`chi_sim+eng`), Traditional Chinese + English (`chi_tra+eng`).
- OCR page layout modes: Auto (PSM 3), Block (PSM 6), Single line (PSM 7), Sparse text (PSM 11).
- Save persistent input/output/temporary directory preferences, render DPI and OCR settings.
- Leave the original PDF unchanged.

## Requirements

- **Tcl/Tk 8.6** (`wish`)
- **Poppler** (`pdfinfo`, `pdftoppm`)
- **ImageMagick 7** (`magick`)
- **Tesseract OCR** (`tesseract`)
- **OCRmyPDF** (`ocrmypdf`)
- **qpdf** (`qpdf`)

On Debian, install the relevant tools from your distribution packages; check that `magick` is available (some releases provide older ImageMagick under a different executable name). Install the Tesseract Chinese language models to use the corresponding OCR options.

## Run

```bash
wish pdflab_crop_ocr.tcl
```

Alternatively, use `./pdflab_crop_ocr.tcl` when the file is executable. The application requires a graphical Linux desktop or an X11-forwarded display.

## Getting started

1. Open **Settings → Preferences** and configure your input, temporary and output directories.
2. Use **File → Open PDF** to select the document.
3. Select a page and DPI, then press **Render**.
4. Drag to draw a rectangular selection; move or resize it as needed.
5. Choose **Export PNG**, **OCR Selection** or **PNG + OCR TXT**. Use **OCR Whole PDF** for a searchable full-document copy.

The original distribution contains **Giux-Lab server-specific default paths**:

```text
/home/giu/pdf-lab/Input_Originali
/home/giu/pdf-lab/Lavoro_Temporaneo_PDF
/home/giu/pdf-lab/Risultati
```

On other computers, change these defaults in Preferences before first use. Settings are stored in `~/.config/giux-lab/pdflab-crop-ocr.conf`.

## Repository contents

| File | Purpose |
|---|---|
| `pdflab_crop_ocr.tcl` | Original Tcl/Tk application |
| `README_PDFLab_Crop_OCR.md` | Original complete application guide |
| `LICENSE_PDFLab_Crop_OCR.txt` | Original license and attribution |
| `LICENSE` | Identical copy of the original GPL license |
| `SOURCE_ARCHIVE_SHA256.txt` | Identity of the author's original distribution ZIP |

The initial GitHub release includes **the unchanged original ZIP**. No separate GitHub Pages site is maintained.

## Copyright and license

Copyright © 2026 **Giuseppe Lanzani / Giux-Lab**. Distributed under the **GNU General Public License, version 3 or later (GPL-3.0-or-later)**.

PDFLab Crop & OCR is an independent Tcl/Tk utility; it does not require the GX-TXT scientific framework. The PDF/OCR tools are external dependencies distributed under their respective licenses.
