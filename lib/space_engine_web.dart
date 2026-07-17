// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web'
    as ui_web; // 👈 CORREGIDO: Esta es la librería web oficial en Flutter moderno

class SpaceEngineWeb extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool isAnclado;

  // 👈 CORREGIDO: Ahora usa 'super.key' para cumplir con las reglas actuales de Dart
  const SpaceEngineWeb({
    super.key,
    required this.latitude,
    required this.longitude,
    this.isAnclado = true,
  });

  @override
  State<SpaceEngineWeb> createState() => _SpaceEngineWebState();
}

class _SpaceEngineWebState extends State<SpaceEngineWeb> {
  late html.IFrameElement _iframeElement;
  final String _viewId = 'iframe-space-engine';

  @override
  void initState() {
    super.initState();

    // Creamos el elemento IFrame apuntando al archivo HTML de tus assets
    _iframeElement = html.IFrameElement()
      ..src = 'assets/assets/html/space_engine.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Registramos la vista usando la librería oficial de Flutter Web
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframeElement,
    );
  }

  @override
  void didUpdateWidget(covariant SpaceEngineWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Cada vez que cambie la latitud o longitud desde Flutter, se la enviamos al HTML por postMessage
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.isAnclado != widget.isAnclado) {
      _enviarDatosAlHtml();
    }
  }

  void _enviarDatosAlHtml() {
    final datos = {
      'type': 'DATA_ISS',
      'lat': widget.latitude,
      'lng': widget.longitude,
      'snap': widget.isAnclado,
    };

    // Disparar mensaje de forma segura al interior del mapa 3D
    _iframeElement.contentWindow?.postMessage(datos, '*');
  }

  @override
  Widget build(BuildContext context) {
    // Retornamos la vista HTML dentro del layout de Flutter
    return HtmlElementView(viewType: _viewId);
  }
}
