# PDFLab Crop & OCR

**Produced by Giux-Lab — https://giux-lab.it**

Copyright © 2026 Giuseppe Lanzani / Giux-Lab  
License: **GNU General Public License v3.0 or later (GPL-3.0-or-later)**

## Overview

PDFLab Crop & OCR is a Tcl/Tk desktop utility for working with technical PDF documents on the Giux-Lab server. It is designed for datasheets, scanned manuals, old technical literature and similar documents where figures, graphs, tables or small text regions need to be extracted without modifying the original PDF.

The application uses the PDF/OCR tools already available on the server: Poppler, ImageMagick, Tesseract, OCRmyPDF and qpdf.

## Main features

- Open PDF documents without modifying them.
- Navigate through pages.
- Render pages at 150, 200, 300, 400 or 600 DPI.
- Zoom with the mouse wheel, centered on the pointer.
- Pan with the arrow keys.
- Free pan by dragging with the middle mouse button.
- Create rectangular selections with the left mouse button.
- Move an existing selection by dragging inside it.
- Resize an existing selection using eight handles.
- Export selected graphs, figures or tables as high-resolution PNG files.
- Run OCR only on the selected rectangle.
- Export PNG + UTF-8 OCR text together.
- Run OCR on the whole PDF using OCRmyPDF.
- OCR languages:
  - `eng`
  - `chi_sim+eng` — Simplified Chinese + English
  - `chi_tra+eng` — Traditional Chinese + English
- OCR layout modes:
  - Auto — Tesseract PSM 3
  - Block — PSM 6
  - Single line — PSM 7
  - Sparse text — PSM 11

## Quick guide

1. Start the application and choose **File > Open PDF**.
2. Select the page and render DPI, then press **Render**.
3. Use the mouse wheel to zoom.
4. Use the arrow keys or middle-button drag to move around the page.
5. Drag with the left mouse button to create a rectangular selection.
6. Refine it by dragging the selection itself or one of its eight resize handles.
7. Choose:
   - **Export PNG** for graphs, figures and other image regions;
   - **OCR Selection** to recognize text only inside the rectangle;
   - **PNG + OCR TXT** to save both the raster crop and recognized text.
8. Use **OCR Whole PDF** when a searchable copy of the complete document is needed.

The crop coordinates are always kept in the full-resolution source raster. Zooming the preview does not reduce the resolution of exported images.

## Preferences

Open **Settings > Preferences** to configure persistent defaults.

Available settings:

- **PDF input directory** — default directory used by `Open PDF`.
- **Images / text output directory** — default destination for PNG, TXT and OCR PDF results.
- **Temporary working directory** — location used for rendered pages, preview images and temporary OCR crops.
- Default render DPI.
- Default preview zoom.
- Default OCR language.
- Default OCR layout mode.

The initial Giux-Lab PDFLab paths are:

```text
PDF input:          /home/giu/pdf-lab/Input_Originali
Temporary work:     /home/giu/pdf-lab/Lavoro_Temporaneo_PDF
Images/text output: /home/giu/pdf-lab/Risultati
```

User preferences are stored in:

```text
~/.config/giux-lab/pdflab-crop-ocr.conf
```

The configuration file contains only application preferences; no credentials are stored.

## Mouse and keyboard controls

- **Mouse wheel** — zoom around the pointer.
- **Arrow keys** — pan the page.
- **Middle mouse button + drag** — free pan.
- **Left button + drag outside the current selection** — create a new selection.
- **Left button + drag inside the selection** — move it.
- **Left button + drag a handle** — resize it.

## Dependencies

- Tcl/Tk 8.6
- `pdfinfo`
- `pdftoppm`
- ImageMagick `magick`
- `tesseract`
- `ocrmypdf`
- `qpdf`

The program invokes external tools directly through Tcl `exec`; it does not construct shell command strings with `sh -c`.

## Data handling

The original PDF is never overwritten by the application. Rendering, previews and temporary OCR crops are created in the configured temporary working directory. Persistent results are saved only when requested by the user.

## License and authorship

**PDFLab Crop & OCR is produced by Giux-Lab — https://giux-lab.it.**

Copyright © 2026 Giuseppe Lanzani / Giux-Lab.

The software is distributed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**. See `LICENSE_PDFLab_Crop_OCR.txt` and the application's **Help > License** dialog.
