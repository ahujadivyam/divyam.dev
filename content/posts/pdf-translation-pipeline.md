---
title: "Building a PDF Translation Pipeline"
date: 2026-02-11
description: "How I built a pipeline to translate Hindi PDFs to English using OCR and neural machine translation."
tags: ["python", "ocr", "ml"]
---

Recently, I needed to translate a PDF document from Hindi to English. Sounds simple enough, right? Turns out, it's a surprisingly deep rabbit hole.

## The Pipeline

The approach I settled on follows this flow:

```
PDF → Images → OCR → Translation → Rendered Images → PDF
```

Each step has its own set of challenges:

1. **PDF to Images**: Convert each page to a high-DPI image for better OCR accuracy
2. **OCR**: Extract text with position data using PaddleOCR
3. **Translation**: Run extracted text through NLLB (No Language Left Behind)
4. **Rendering**: Paint translated text back onto the original image
5. **Assembly**: Combine rendered images back into a PDF

## Lessons Learned

- **DPI matters a lot** — bumping from 150 to 300 DPI dramatically improved OCR accuracy for Hindi text
- **Font rendering is hard** — getting translated text to fit in the same bounding boxes required careful font size calculation
- **Fallback strategies** — TrOCR as a fallback when PaddleOCR fails on certain text regions

The code is messy but it works. Sometimes that's enough.
