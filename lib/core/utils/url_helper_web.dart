import 'dart:html' as html;

String getBrowserPath() {
  try {
    return html.window.location.pathname ?? '/';
  } catch (e) {
    return '/';
  }
}
