# TuitionLuma Website

Static public site for TuitionLuma App Store marketing, support, privacy, and terms URLs.

## Local Preview

This site has no build step. Preview it with a tiny local server so absolute links match deployment:

```bash
cd Website
python3 -m http.server 8081
```

Then visit:

- `http://localhost:8081/`
- `http://localhost:8081/support/`
- `http://localhost:8081/privacy/`
- `http://localhost:8081/terms/`

## Cloudflare Pages

Recommended Pages settings:

- Framework preset: None
- Build command: blank
- Build output directory: `Website`
- Production branch: `main`

The site currently uses `https://tuitionluma.pages.dev/` in canonical URLs, Open Graph tags, `robots.txt`, and `sitemap.xml`. Replace this with a custom domain later if needed.
