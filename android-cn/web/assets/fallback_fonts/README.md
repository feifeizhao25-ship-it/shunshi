# Local web font fallbacks

The Flutter bootstrap uses `fontFallbackBaseUrl: "assets/fallback_fonts/"`. `flutter build web` copies this `web/` directory verbatim.

- Default **Roboto** is declared in `pubspec.yaml` and bundled under `assets/fonts/` (Google Fonts Roboto v2.138, `https://github.com/googlefonts/roboto/releases/tag/v2.138`, Apache-2.0; license alongside the fonts). Flutter's font collection sees the Roboto manifest entry and skips its implicit download.
- **Noto Color Emoji v32**: all 12 `.woff2` shards referenced by Flutter 3.38.5's `font_fallback_data.dart`, downloaded 2026-11-22 from `https://fonts.gstatic.com/s/notocoloremoji/v32/<filename>`. SIL OFL 1.1; license under `notocoloremoji/`. They cover the emoji currently needed by the 顺时 web UI (copied from android-global for the web-cn build, 2026-11-22). Source project: https://github.com/googlefonts/noto-emoji.

2026-11-21 test: missing Roboto produced 404 and left every default-font string blank. Bundling it restored the text; browser verification then found the missing emoji shards, now bundled too. Other scripts may still need a fallback not shipped here. On a Flutter upgrade, recheck its fallback filenames and browser network log; do not silently re-enable a remote CDN.
