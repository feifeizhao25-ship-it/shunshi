# Local web font fallbacks

The Flutter bootstrap uses `fontFallbackBaseUrl: "assets/fallback_fonts/"`. `flutter build web` copies this `web/` directory verbatim.

- Default **Roboto** is declared in `pubspec.yaml` and bundled under `assets/fonts/` (Google Fonts Roboto v2.138, `https://github.com/googlefonts/roboto/releases/tag/v2.138`, Apache-2.0; license alongside the fonts). Flutter's font collection sees the Roboto manifest entry and skips its implicit download.
- **Noto Color Emoji v32** stays, because CI builds with Flutter 3.38.5 and that engine asks for `notocoloremoji/v32/`. **v39** (10 shards) is what Flutter 3.50 asks for; a release built with 3.50 was requesting v39 and drawing 🌿 as an empty box. Both sets are shipped. v39 was downloaded 2026-11-26 from `https://fonts.gstatic.com/s/notocoloremoji/v39/<filename>`. SIL OFL 1.1; license under `notocoloremoji/`.
- **Noto Sans Symbols 2 v25**: six shards from `https://fonts.gstatic.com/s/notosanssymbols2/v25/<filename>`. SIL OFL 1.1, license beside the files.
- A logged-in pass over the release web app also 404'd three `notosanssc/v40` shards and one `notosanskr/v39` shard. Those four files are shipped too. Image URLs (png, jpg, webp, svg) on that pass returned no 404.

2026-11-21 test: missing Roboto produced 404 and left every default-font string blank. Bundling it restored the text; browser verification then found the missing emoji shards, now bundled too. Other scripts may still need a fallback not shipped here. On a Flutter upgrade, recheck its fallback filenames and browser network log; do not silently re-enable a remote CDN.
