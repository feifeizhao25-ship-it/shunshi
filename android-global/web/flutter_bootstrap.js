{{flutter_js}}
{{flutter_build_config}}
// 不依赖 gstatic：canvaskit 由 --no-web-resources-cdn 随包发布；缺字时的回退字体也只从本站取，
// 国内网络或内网环境下不会因为 Google CDN 不可达而白屏。
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
    fontFallbackBaseUrl: "assets/fallback_fonts/",
  },
});
