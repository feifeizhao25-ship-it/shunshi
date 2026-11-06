import 'dart:js_interop';

@JS('document')
external _JSDocument get _document;

extension type _JSDocument(JSObject _) implements JSObject {
  external _JSElement? querySelector(String selectors);
  external _JSElement createElement(String localName);
  external _JSElement? get body;
}

extension type _JSElement(JSObject _) implements JSObject {
  external set textContent(String? value);
  external _JSStyle get style;
  external void setAttribute(String qualifiedName, String value);
  external void appendChild(_JSElement node);
}

extension type _JSStyle(JSObject _) implements JSObject {
  external set cssText(String value);
}

const _hostId = 'app-readable-copy';
_JSElement? _host;
String? _last;

/// Light-DOM mirror of the semantics tree.
///
/// `opacity: 0` keeps the canvas as the only thing a person sees, and it
/// still contributes to `innerText` (unlike `visibility: hidden`).
/// `aria-hidden` keeps screen readers on Flutter's own semantics tree so the
/// words are not announced twice.
void attachReadableCopyHost() {
  if (_host != null) return;
  final body = _document.body;
  if (body == null) return;
  final existing = _document.querySelector('#$_hostId');
  final el = existing ?? _document.createElement('div');
  el.setAttribute('id', _hostId);
  el.setAttribute('aria-hidden', 'true');
  el.setAttribute('data-readable-copy', 'true');
  el.style.cssText = [
    'position:fixed',
    'left:0',
    'top:0',
    'width:100%',
    'margin:0',
    'padding:0',
    'border:0',
    'opacity:0',
    'pointer-events:none',
    'z-index:0',
    'white-space:pre-wrap',
    'overflow:visible',
    'user-select:none',
  ].join(';');
  if (existing == null) body.appendChild(el);
  _host = el;
}

void publishReadableCopy(String text) {
  attachReadableCopyHost();
  if (_host == null || text == _last) return;
  _last = text;
  _host!.textContent = text;
}
