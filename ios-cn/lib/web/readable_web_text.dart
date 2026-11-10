import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import 'readable_semantics.dart';
import 'readable_web_host_stub.dart'
    if (dart.library.ui_web) 'readable_web_host_web.dart' as host;

/// Enables the web semantics tree and mirrors it into `#app-readable-copy`.
///
/// No-op off the web. CanvasKit stays the painter; this does not switch to
/// the HTML renderer.
void enableReadableWebText() {
  if (!kIsWeb) return;
  SemanticsBinding.instance.ensureSemantics();
  host.attachReadableCopyHost();
  SchedulerBinding.instance.addPersistentFrameCallback((_) {
    try {
      host.publishReadableCopy(collectReadableSemanticsText());
    } catch (_) {
      // One frame without a semantics tree should not take down the page.
    }
  });
}
