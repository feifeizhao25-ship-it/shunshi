{{flutter_js}}
{{flutter_build_config}}
// 不依赖 gstatic：canvaskit 由 --no-web-resources-cdn 随包发布；缺字时的回退字体也只从本站取，
// 国内网络或内网环境下不会因为 Google CDN 不可达而白屏。
// 注意：默认字体 Roboto 已在 pubspec.yaml 里打包，
// 引擎看到清单里有 Roboto 就不会再去这里下载（2026-11-21 测试：这里 404 导致网页文字全空白）。
// Noto Color Emoji v32 的 12 个回退分片随 web/assets/fallback_fonts/ 发布；其它缺字仍可能回退。
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
    fontFallbackBaseUrl: "assets/fallback_fonts/",
  },
});
