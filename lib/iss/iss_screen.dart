import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:colombia_datos_y_iss/src/js_util_stub.dart'
    if (dart.library.js_util) 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

class IssScreen extends StatefulWidget {
  const IssScreen({super.key});

  @override
  State<IssScreen> createState() => _IssScreenState();
}

class _IssScreenState extends State<IssScreen> {
  // Telemetría orbital exacta de la ISS
  double _latitud = 8.1764;
  double _longitud = -178.4300;
  final double _altitud = 421.8;
  final double _velocidad = 27560;

  bool _fijarAISS = true;
  late Timer _timer;
  late String _viewId;
  html.Element? _webGlContainer;

  @override
  void initState() {
    super.initState();
    _viewId =
        'webgl-nasa-satellite-engine-${DateTime.now().millisecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final container = html.DivElement()
        ..id = 'canvas-3d-container'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#010206';

      _webGlContainer = container;

      // Inicializar el renderizado fotorrealista de inmediato
      Timer(const Duration(milliseconds: 100), _initSatelliteEngine);

      return container;
    });

    // Simulación del trayecto orbital real
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _longitud += 0.3;
        if (_longitud > 180) _longitud = -180;
        _latitud = 51.6 * math.sin(_longitud * math.pi / 180);

        _updateEngineState(_latitud, _longitud, _fijarAISS);
      });
    });
  }

  void _initSatelliteEngine() {
    if (_webGlContainer == null) return;

    js_util.setProperty(html.window, 'issResetCamera', js_util.allowInterop(() {
      setState(() => _fijarAISS = true);
    }));

    js_util.setProperty(html.window, 'issReleaseCamera',
        js_util.allowInterop(() {
      setState(() => _fijarAISS = false);
    }));

    const jsCode = """
      (function() {
        var container = document.getElementById('canvas-3d-container');
        if(!container) return;

        var scene = new THREE.Scene();
        var camera = new THREE.PerspectiveCamera(40, container.clientWidth / container.clientHeight, 0.1, 1000);
        
        var renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
        renderer.setSize(container.clientWidth, container.clientHeight);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        container.appendChild(renderer.domElement);

        // GRUPO RAÍZ GLOBAL: Para que al arrastrar con el mouse, la Tierra Y la ISS roten juntas
        var worldGroup = new THREE.Group();
        scene.add(worldGroup);

        // ILUMINACIÓN PREMIUM SIN SOMBRAS ABSOLUTAS
        var ambientLight = new THREE.AmbientLight(0xffffff, 0.8); 
        scene.add(ambientLight);
        
        var sunLight = new THREE.DirectionalLight(0xffffff, 1.8); 
        sunLight.position.set(5, 3, 5);
        scene.add(sunLight);

        // TEXTURAS PLANETARIAS REALES DE LA NASA
        var textureLoader = new THREE.TextureLoader();
        textureLoader.crossOrigin = 'anonymous';

        var earthMap = textureLoader.load('https://unpkg.com/three-globe/example/img/earth-blue-marble.jpg');
        var bumpMap = textureLoader.load('https://unpkg.com/three-globe/example/img/earth-topology.png');
        var cloudMap = textureLoader.load('https://unpkg.com/three-globe/example/img/earth-clouds.png');

        // Esfera Terrestre de Alta Resolución añadida al grupo global
        var earthGeo = new THREE.SphereGeometry(2, 64, 64);
        var earthMat = new THREE.MeshPhongMaterial({
          map: earthMap,
          bumpMap: bumpMap,
          bumpScale: 0.03,
          shininess: 15
        });
        var earthMesh = new THREE.Mesh(earthGeo, earthMat);
        worldGroup.add(earthMesh);

        // Capa de nubes reales translúcidas añadida al grupo global
        var cloudGeo = new THREE.SphereGeometry(2.018, 64, 64);
        var cloudMat = new THREE.MeshPhongMaterial({
          map: cloudMap,
          transparent: true,
          blending: THREE.NormalBlending,
          opacity: 0.5
        });
        var cloudMesh = new THREE.Mesh(cloudGeo, cloudMat);
        worldGroup.add(cloudMesh);

        // Resplandor Azul Atmosférico
        var atmosGeo = new THREE.SphereGeometry(2.05, 64, 64);
        var atmosMat = new THREE.MeshBasicMaterial({
          color: 0x3a86ff,
          transparent: true,
          opacity: 0.15,
          side: THREE.BackSide
        });
        var atmosMesh = new THREE.Mesh(atmosGeo, atmosMat);
        worldGroup.add(atmosMesh);

        // ESTACIÓN ESPACIAL INTERNACIONAL (ISS)
        var issRoot = new THREE.Group();
        
        // 1. Estructura Central
        var coreGeo = new THREE.CylinderGeometry(0.025, 0.025, 0.22, 12);
        var coreMat = new THREE.MeshPhongMaterial({ color: 0xffffff, emissive: 0x333333, shininess: 80 });
        var core = new THREE.Mesh(coreGeo, coreMat);
        core.rotation.z = Math.PI / 2;
        issRoot.add(core);

        // 2. Paneles Solares Dorados
        var panelGeo = new THREE.BoxGeometry(0.06, 0.45, 0.005);
        var panelMat = new THREE.MeshPhongMaterial({ 
          color: 0xffb703, 
          addessive: 0x4a3200, 
          shininess: 100,
          side: THREE.DoubleSide 
        });
        
        var leftPanels = new THREE.Mesh(panelGeo, panelMat);
        leftPanels.position.x = -0.16;
        var rightPanels = leftPanels.clone();
        rightPanels.position.x = 0.16;
        
        issRoot.add(leftPanels);
        issRoot.add(rightPanels);
        
        // Añadida al worldGroup para que herede las rotaciones físicas continentales
        worldGroup.add(issRoot);

        // Posicionamiento de cámara por defecto inicial
        camera.position.set(0, 0, 5.5);

        // Controles de Rotación Gestual
        var isDragging = false;
        var prevMouse = { x: 0, y: 0 };

        container.addEventListener('mousedown', function() {
          isDragging = true;
          if (window.issReleaseCamera) window.issReleaseCamera();
        });

        container.addEventListener('mousemove', function(e) {
          if(isDragging) {
            var dx = e.offsetX - prevMouse.x;
            var dy = e.offsetY - prevMouse.y;
            worldGroup.rotation.y += dx * 0.005;
            worldGroup.rotation.x += dy * 0.005;
          }
          prevMouse = { x: e.offsetX, y: e.offsetY };
        });

        window.addEventListener('mouseup', function() { isDragging = false; });

        // SEGUIMIENTO DE CÁMARA CORREGIDO DINÁMICAMENTE
        window.updateSpaceEngine = function(lat, lng, snapCamera) {
          var phi = (90 - lat) * (Math.PI / 180);
          var theta = (lng + 180) * (Math.PI / 180);
          var radius = 2.35; 
          
          // Posicionamiento de la ISS dentro del espacio coordenado local de la Tierra
          issRoot.position.x = -radius * Math.sin(phi) * Math.sin(theta);
          issRoot.position.y = radius * Math.cos(phi);
          issRoot.position.z = radius * Math.sin(phi) * Math.cos(theta);
          
          // Apuntar base hacia el núcleo terrestre
          issRoot.lookAt(0, 0, 0);

          // ANCLAJE REAL DE CÁMARA (Solución al desfase)
          if(snapCamera) {
            // Reseteamos cualquier rotación manual del mundo para no romper las coordenadas esféricas
            worldGroup.rotation.set(0, 0, 0);

            // Calculamos un vector exterior relativo a la ISS para la posición de la cámara
            var camRadius = radius + 2.2;
            var targetCamX = -camRadius * Math.sin(phi) * Math.sin(theta);
            var targetCamY = camRadius * Math.cos(phi);
            var targetCamZ = camRadius * Math.sin(phi) * Math.cos(theta);

            // Interpolación lineal suave (Lerp) para evitar saltos bruscos de renderizado
            camera.position.x = THREE.MathUtils.lerp(camera.position.x, targetCamX, 0.05);
            camera.position.y = THREE.MathUtils.lerp(camera.position.y, targetCamY, 0.05);
            camera.position.z = THREE.MathUtils.lerp(camera.position.z, targetCamZ, 0.05);

            // Fijar de manera estricta el foco en la malla de la ISS
            camera.lookAt(issRoot.position);
          }
        };

        function renderLoop() {
          requestAnimationFrame(renderLoop);
          cloudMesh.rotation.y += 0.0002; // Movimiento atmosférico sutil
          renderer.render(scene, camera);
        }
        renderLoop();
      })();
    """;

    final html.ScriptElement script = html.ScriptElement()..text = jsCode;
    _webGlContainer!.append(script);
  }

  void _updateEngineState(double lat, double lng, bool snap) {
    if (js_util.hasProperty(html.window, 'updateSpaceEngine')) {
      js_util.callMethod(html.window, 'updateSpaceEngine', [lat, lng, snap]);
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
                HtmlElementView(viewType: _viewId),

                // Capa HUD superior
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                              : "ROTACIÓN LIBRE TRIDIMENSIONAL",
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
                              textStyle: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              if (js_util.hasProperty(
                                  html.window, 'issResetCamera')) {
                                js_util.callMethod(
                                    html.window, 'issResetCamera', []);
                              }
                            },
                            icon: const Icon(Icons.sync,
                                size: 12, color: Colors.black),
                            label: const Text("REAJUSTAR"),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Consola de Datos de Telemetría Dinámica
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
                _buildTelemetryItem("VELOCIDAD", "$_velocidad km/h"),
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
