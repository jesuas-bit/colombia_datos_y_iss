// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

html.WindowBase? _iframeWindow;
String? _iframeBlobUrl; // Almacena la URL para evitar duplicados

String registerWebGlFactory(
    void Function() onReset, void Function() onRelease) {
  final viewId =
      'webgl-nasa-satellite-engine-${DateTime.now().millisecondsSinceEpoch}';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final iframe = html.IFrameElement()
      ..id = id.toString()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.backgroundColor = '#02040a';

    iframe.onLoad.listen((_) {
      _iframeWindow = iframe.contentWindow;
    });

    // ✅ Solución para Chrome: Cargamos el HTML y lo convertimos en un Blob URL seguro
    rootBundle.loadString('assets/html/space_engine.html').then((htmlContent) {
      final blob = html.Blob([htmlContent], 'text/html');
      _iframeBlobUrl = html.Url.createObjectUrlFromBlob(blob);
      iframe.src = _iframeBlobUrl!;
    }).catchError((error) {
      debugPrint("Error cargando el motor espacial: $error");
    });

    return iframe;
  });

  return viewId;
}

void updateWebGlEngine(double lat, double lng, bool snap) {
  // Enviamos los datos mediante postMessage seguro
  _iframeWindow?.postMessage({
    'action': 'updateSpaceEngine',
    'lat': lat,
    'lng': lng,
    'snap': snap,
  }, '*');
}

void triggerWebGlReset() {
  _iframeWindow?.postMessage({
    'action': 'issResetCamera',
  }, '*');
}
