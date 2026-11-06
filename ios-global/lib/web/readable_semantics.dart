import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Words from the live semantics tree, in traversal order.
///
/// CanvasKit paints glyphs into a canvas and keeps the accessibility host in
/// a shadow root, so `document.body.innerText` cannot see them. This string
/// is the same copy a screen reader gets. The web host publishes it as
/// light-DOM text.
String collectReadableSemanticsText() {
  final root = WidgetsBinding.instance.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root == null) return '';
  final lines = <String>[];
  bool walk(SemanticsNode node) {
    if (!node.isMergedIntoParent) {
      final line = _nodeLine(node);
      if (line.isNotEmpty && (lines.isEmpty || lines.last != line)) lines.add(line);
    }
    node.visitChildren(walk);
    return true;
  }

  walk(root);
  return lines.join('\n');
}

String _nodeLine(SemanticsNode node) {
  final parts = <String>[];
  void add(String raw) {
    final text = raw.trim();
    if (text.isEmpty || parts.contains(text)) return;
    parts.add(text);
  }

  add(node.label);
  add(node.value);
  add(node.hint);
  add(node.tooltip);
  return parts.join(' ');
}
