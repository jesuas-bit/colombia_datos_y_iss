import 'package:flutter/material.dart';

// Este archivo es un "falso" SpaceEngineWeb para que Android compile sin buscar dart:html
class SpaceEngineWeb extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isAnclado;

  const SpaceEngineWeb({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isAnclado,
  });

  @override
  Widget build(BuildContext context) {
    // Esto nunca se mostrará en Android porque iss_screen.dart usa WebViewWidget en su lugar,
    // pero necesitamos que la clase exista para que el compilador no se queje.
    return const SizedBox.shrink();
  }
}
