.PHONY: all serve build resume clean

# Build everything
all: resume build

# Start Hugo dev server
serve:
	hugo server -D

# Build static site
build:
	hugo --gc --minify

# Compile resume PDF from YAML via Typst
resume:
	typst compile --root . --font-path resume/ resume/main.typ static/resume.pdf

# Watch resume for changes
resume-watch:
	typst watch --root . --font-path resume/ resume/main.typ static/resume.pdf

# Clean build artifacts
clean:
	rm -rf public/
	rm -f static/resume.pdf
