// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../space_engine_stub.dart'
    if (dart.library.html) '../space_engine_web.dart';

class IssScreen extends StatefulWidget {
  const IssScreen({super.key});

  @override
  State<IssScreen> createState() => _IssScreenState();
}

class _IssScreenState extends State<IssScreen> {
  double _latitud = 0.0;
  double _longitud = 0.0;
  double _altitud = 0.0;
  double _velocidad = 0.0;

  bool _fijarAISS = true;
  bool _isWebViewLoaded = false;
  late Timer _timer;

  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _isWebViewLoaded = true;
    } else {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF010206))
        // 🚀 NUEVO: Canal para escuchar toques en el modelo 3D
        ..addJavaScriptChannel(
          'FlutterSpaceChannel',
          onMessageReceived: (JavaScriptMessage message) {
            if (message.message == 'modo_libre_activado' && _fijarAISS) {
              if (mounted) {
                setState(() {
                  _fijarAISS =
                      false; // Desancla la cámara si el usuario toca la pantalla
                });
              }
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isWebViewLoaded = true;
                });
              }
            },
          ),
        )
        ..loadFlutterAsset('assets/html/space_engine.html');
    }

    _obtenerDatosISS();

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _obtenerDatosISS();
      }
    });
  }

  Future<void> _obtenerDatosISS() async {
    try {
      final url = Uri.parse('https://api.wheretheiss.at/v1/satellites/25544');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            _latitud = data['latitude'];
            _longitud = data['longitude'];
            _altitud = data['altitude'];
            _velocidad = data['velocity'];

            _enviarDatosAMotorMovil(_latitud, _longitud, _fijarAISS);
          });
        }
      }
    } catch (e) {
      debugPrint("Error de red: $e");
    }
  }

  void _enviarDatosAMotorMovil(double lat, double lng, bool snap) {
    if (!kIsWeb) {
      if (_webViewController != null && _isWebViewLoaded) {
        _webViewController!
            .runJavaScript('window.updateSpaceEngine($lat, $lng, $snap);')
            .catchError((error) => debugPrint("Error inyectando: $error"));
      }
    }
  }

  // 📡 ACTUALIZADO: Reajusta la cámara forzando el comando directo
  void _reajustarCamara() {
    setState(() => _fijarAISS = true);
    if (!kIsWeb) {
      if (_webViewController != null && _isWebViewLoaded) {
        // Ejecutamos el centrado manual en JS y luego enviamos las coordenadas actualizadas
        _webViewController!.runJavaScript('''
          window.issResetCamera();
          window.updateSpaceEngine($_latitud, $_longitud, true);
        ''');
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010206),
      appBar: AppBar(
        title: const Text(
          'SEGUIMIENTO ESPACIAL EN VIVO ISS',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1),
        ),
        backgroundColor: const Color(0xFF090D16),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                kIsWeb
                    ? SpaceEngineWeb(
                        latitude: _latitud,
                        longitude: _longitud,
                        isAnclado: _fijarAISS,
                      )
                    : WebViewWidget(controller: _webViewController!),

                // Capa HUD superior de control de cámara
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      // Permite alternar manualmente tocando el botón
                      if (_fijarAISS) {
                        setState(() => _fijarAISS = false);
                      } else {
                        _reajustarCamara();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xE5090D16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _fijarAISS
                              ? const Color(0xFFFCD116)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _fijarAISS
                                ? Icons.gps_fixed
                                : Icons.pan_tool_outlined,
                            color: _fijarAISS
                                ? const Color(0xFFFCD116)
                                : Colors.white60,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fijarAISS
                                ? "CÁMARA: ANCLADA A ISS"
                                : "ROTACIÓN LIBRE ACTIVA",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                          if (!_fijarAISS) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFCD116),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              onPressed: _reajustarCamara,
                              icon: const Icon(Icons.sync,
                                  size: 12, color: Colors.black),
                              label: const Text("REAJUSTAR",
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Consola inferior
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF090D16),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTelemetryItem("LATITUD",
                    "${_latitud.abs().toStringAsFixed(4)}° ${_latitud >= 0 ? 'N' : 'S'}"),
                _buildTelemetryItem("LONGITUD",
                    "${_longitud.abs().toStringAsFixed(4)}° ${_longitud >= 0 ? 'E' : 'O'}"),
                _buildTelemetryItem(
                    "ALTITUD", "${_altitud.toStringAsFixed(1)} km"),
                _buildTelemetryItem(
                    "VELOCIDAD", "${_velocidad.toStringAsFixed(0)} km/h"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(String title, String data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(data,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
      ],
    );
  }
}
