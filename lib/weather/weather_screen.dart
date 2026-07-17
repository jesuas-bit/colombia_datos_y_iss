import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 📦 IMPORTANTE: Nueva importación

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // ⚠️ REEMPLAZA ESTO CON TU API KEY REAL DE OPENWEATHERMAP
  final String _apiKey = "bcd064cdc6c291606d590d356c1773e5";

  // Variables de ubicación dinámicas
  String _pais = "Colombia";
  String _ciudad = "Barrancabermeja";
  double _latitudActiva = 7.0653;
  double _longitudActiva = -73.8547;

  // Valores de Temperatura y Presión dinámicos
  double _tempActual = 26.4;
  double _tempMin = 23.1;
  double _tempMax = 34.8;
  double _presion = 996.2;

  // Resto de mediciones activas dinámicas
  double _velviento = 10.4;
  double _dirviento = 270.0;
  double _precipitacion = 0.0;
  double _nubes = 99.0;

  // Controladores de tiempo y búsqueda
  Timer? _timerActualizacion;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  // Historial de la sesión (¡Ahora persistirá en el dispositivo!)
  List<Map<String, dynamic>> _historialRegistros = [];

  final List<Map<String, String>> _tablaFrec = [
    {"rango": "Calma (0-10)", "abs": "0", "porcentaje": "0.0"},
    {"rango": "Brisa (10-25)", "abs": "0", "porcentaje": "0.0"},
    {"rango": "Moderado (25-50)", "abs": "0", "porcentaje": "0.0"},
    {"rango": "Vendaval (>50)", "abs": "0", "porcentaje": "0.0"},
  ];

  @override
  void initState() {
    super.initState();
    // 1. Cargar el historial guardado en SharedPreferences antes de iniciar las consultas
    _cargarHistorialPersistente();
    // 2. Intentar geolocalizar de inmediato al entrar a la pantalla
    _obtenerUbicacionActualGPS();
    // 3. Iniciar el loop repetitivo de actualizaciones cada 5 segundos
    _iniciarCicloClima();
  }

  @override
  void dispose() {
    // Cancelar el Timer al salir de la pantalla para evitar fugas de memoria
    _timerActualizacion?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================================
  // LÓGICA DE PERSISTENCIA (MÉTODOS NUEVOS)
  // =========================================================================

  // Carga el historial desde el almacenamiento local al iniciar la app
  Future<void> _cargarHistorialPersistente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historialString = prefs.getString('historial_clima');

      if (historialString != null) {
        final List<dynamic> decodedList = json.decode(historialString);
        setState(() {
          _historialRegistros = decodedList
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _actualizarTablaFrecuencias();
        });
      }
    } catch (e) {
      debugPrint("Error cargando el historial persistente: $e");
    }
  }

  // Guarda la lista del historial codificada en formato JSON string
  Future<void> _guardarHistorialPersistente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(_historialRegistros);
      await prefs.setString('historial_clima', encodedData);
    } catch (e) {
      debugPrint("Error guardando el historial persistente: $e");
    }
  }

  // Opcional: Si deseas agregar un botón en el futuro para vaciar el historial
  Future<void> _limpiarHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('historial_clima');
    setState(() {
      _historialRegistros.clear();
      _actualizarTablaFrecuencias();
    });
  }

  // =========================================================================
  // LÓGICA CORE: GEOLOCALIZACIÓN, CONSULTA HTTP Y REFRESH DE 5 SEG
  // =========================================================================

  // Obtener las coordenadas GPS del dispositivo (Nativo o Navegador)
  Future<void> _obtenerUbicacionActualGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ));

      _latitudActiva = position.latitude;
      _longitudActiva = position.longitude;

      // Actualización inmediata con las coordenadas obtenidas
      _consultarClimaPorCoordenadas(_latitudActiva, _longitudActiva);
    } catch (e) {
      debugPrint("Error obteniendo GPS: $e");
    }
  }

  // Inicia el cronómetro de actualización de 5 segundos
  void _iniciarCicloClima() {
    _timerActualizacion?.cancel();
    _timerActualizacion = Timer.periodic(const Duration(seconds: 5), (timer) {
      _consultarClimaPorCoordenadas(_latitudActiva, _longitudActiva);
    });
  }

  // Petición HTTP a la API Meteorológica mediante Coordenadas (Lat, Lon)
  Future<void> _consultarClimaPorCoordenadas(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _ciudad = data['name'] ?? "Desconocido";
          _pais = data['sys']['country'] ?? "";
          _tempActual = (data['main']['temp'] as num).toDouble();
          _tempMin = (data['main']['temp_min'] as num).toDouble();
          _tempMax = (data['main']['temp_max'] as num).toDouble();
          _presion = (data['main']['pressure'] as num).toDouble();
          _velviento = ((data['wind']['speed'] as num).toDouble() *
              3.6); // De m/s a km/h
          _dirviento = (data['wind']['deg'] as num).toDouble();
          _nubes = (data['clouds']['all'] as num).toDouble();
          _precipitacion = data['rain'] != null
              ? (data['rain']['1h'] ?? 0.0 as num).toDouble()
              : 0.0;

          // Añadir registro automático al historial de la sesión
          final String horaActual =
              "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";

          _historialRegistros.insert(0, {
            "hora": horaActual,
            "ciudad": _ciudad,
            "temp": _tempActual,
            "presion": _presion,
            "viento_vel": double.parse(_velviento.toStringAsFixed(1)),
            "precip": _precipitacion,
            "nubes": _nubes.toInt()
          });

          // Limitar tamaño del historial visual para optimizar rendimiento
          if (_historialRegistros.length > 10) {
            _historialRegistros.removeLast();
          }

          _actualizarTablaFrecuencias();
        });

        // 🔥 ¡CORRECCIÓN AQUÍ!: Guardamos en disco justo después de mutar el estado
        _guardarHistorialPersistente();
      }
    } catch (e) {
      debugPrint("Error de conexión climática: $e");
    }
  }

  // Buscador Mundial: Transforma texto de ciudad a coordenadas válidas (Geocoding)
  Future<void> _buscarCiudadMundial(String textoCiudad) async {
    if (textoCiudad.isEmpty) return;

    setState(() => _isLoading = true);
    final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/direct?q=$textoCiudad&limit=1&appid=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          _latitudActiva = (data[0]['lat'] as num).toDouble();
          _longitudActiva = (data[0]['lon'] as num).toDouble();

          // Forzar refresco inmediato al cambiar de locación mundial
          await _consultarClimaPorCoordenadas(_latitudActiva, _longitudActiva);
          if (!mounted) return;
          _searchController.clear();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Ubicación no encontrada a nivel mundial.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error en Geocoding: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lógica matemática para actualizar las frecuencias acumuladas en caliente
  void _actualizarTablaFrecuencias() {
    int calma = 0, brisa = 0, moderado = 0, vendaval = 0;
    for (var reg in _historialRegistros) {
      double v = reg['viento_vel'];
      if (v <= 10) {
        calma++;
      } else if (v <= 25) {
        brisa++;
      } else if (v <= 50) {
        moderado++;
      } else {
        vendaval++;
      }
    }
    int total = _historialRegistros.length;

    // Si la lista está vacía tras reiniciar, ponemos la tabla de frecuencias en ceros de forma limpia
    if (total == 0) {
      setState(() {
        for (var i = 0; i < _tablaFrec.length; i++) {
          _tablaFrec[i]["abs"] = "0";
          _tablaFrec[i]["porcentaje"] = "0.0";
        }
      });
      return;
    }

    setState(() {
      _tablaFrec[0] = {
        "rango": "Calma (0-10)",
        "abs": "$calma",
        "porcentaje": (calma / total * 100).toStringAsFixed(1)
      };
      _tablaFrec[1] = {
        "rango": "Brisa (10-25)",
        "abs": "$brisa",
        "porcentaje": (brisa / total * 100).toStringAsFixed(1)
      };
      _tablaFrec[2] = {
        "rango": "Moderado (25-50)",
        "abs": "$moderado",
        "porcentaje": (moderado / total * 100).toStringAsFixed(1)
      };
      _tablaFrec[3] = {
        "rango": "Vendaval (>50)",
        "abs": "$vendaval",
        "porcentaje": (vendaval / total * 100).toStringAsFixed(1)
      };
    });
  }

  // =========================================================================
  // CAPA VISUAL (UI)
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151125),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver al Menú Principal',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isLoading
            ? const LinearProgressIndicator(color: Colors.amber)
            : const Text(
                "ESTACIÓN CLIMÁTICA INDEPENDIENTE",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
        actions: [
          // Botón de papelera para limpiar el historial persistente si lo deseas
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Borrar todo el historial guardado',
            onPressed: () {
              if (_historialRegistros.isNotEmpty) {
                _limpiarHistorial();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.tealAccent),
            onPressed: _obtenerUbicacionActualGPS,
            tooltip: 'Usar Mi Ubicación Actual (GPS)',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARRA DE BÚSQUEDA MUNDIAL INTEGRADA
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF161226),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Buscar cualquier ciudad del mundo...",
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.amber),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.orangeAccent),
                    onPressed: () =>
                        _buscarCiudadMundial(_searchController.text),
                  ),
                ),
                onSubmitted: _buscarCiudadMundial,
              ),
            ),

            // Banner Principal de Monitoreo
            _buildMainWeatherHeader(),

            const SizedBox(height: 20),

            // Sección de Instrumentos (Gauges)
            LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth = (constraints.maxWidth - 48) / 4;
                if (itemWidth < 260) itemWidth = constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                        width: itemWidth,
                        child: _buildInstrumentCard(
                            "Velocidad del Viento",
                            "${_velviento.toStringAsFixed(1)} km/h",
                            _buildRadialGauge(_velviento,
                                const Color(0xFFFF00FF), " km/h", 100))),
                    SizedBox(
                        width: itemWidth,
                        child: _buildInstrumentCard(
                            "Dirección del Viento",
                            "${_dirviento.toStringAsFixed(0)}°",
                            _buildRadialGauge(
                                _dirviento, Colors.blueAccent, "°", 360))),
                    SizedBox(
                        width: itemWidth,
                        child: _buildInstrumentCard(
                            "Precipitación",
                            "${_precipitacion.toStringAsFixed(1)} mm",
                            _buildRadialGauge(
                                _precipitacion, Colors.cyan, " mm", 100))),
                    SizedBox(
                        width: itemWidth,
                        child: _buildInstrumentCard(
                            "Cobertura de Nubes",
                            "${_nubes.toStringAsFixed(0)}%",
                            _buildRadialGauge(
                                _nubes, Colors.blueGrey, "%", 100))),
                  ],
                );
              },
            ),

            const SizedBox(height: 35),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "HISTORIAL DE CONSULTAS DE LA SESIÓN (AUTO-UPDATE 5S)",
                  style: TextStyle(
                      color: Color(0xFFFFCD16),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                Text(
                  "Guardado Permanente",
                  style: TextStyle(
                      color: Colors.greenAccent.withAlpha(150), fontSize: 10),
                )
              ],
            ),
            const SizedBox(height: 12),
            _buildGlobalTable(),
          ],
        ),
      ),
    );
  }

  // [Tus widgets secundarios se mantienen exactamente igual...]
  Widget _buildMainWeatherHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161226),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Wrap(
        spacing: 30,
        runSpacing: 20,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$_ciudad ($_pais)",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("${_tempActual.toStringAsFixed(1)}°C",
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 32,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(width: 10),
                      const Icon(Icons.wb_sunny, color: Colors.amber, size: 24),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RANGOS DIARIOS",
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward,
                          color: Colors.red, size: 16),
                      Text(" Máx: ${_tempMax.toStringAsFixed(1)}°C",
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          color: Colors.blue, size: 16),
                      Text(" Mín: ${_tempMin.toStringAsFixed(1)}°C",
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0B1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.compress, color: Colors.tealAccent, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PRESIÓN ATMOSFÉRICA",
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("${_presion.toStringAsFixed(1)} hPa",
                        style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialGauge(
      double value, Color colorPointer, String unit, double maxScale) {
    double valorFormateado = value > maxScale ? maxScale : value;
    if (valorFormateado < 0) valorFormateado = 0;

    return SizedBox(
      height: 140,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: maxScale,
            showLabels: false,
            showTicks: true,
            tickOffset: 2,
            axisLineStyle:
                const AxisLineStyle(thickness: 3, color: Colors.white10),
            pointers: <GaugePointer>[
              NeedlePointer(
                  value: valorFormateado,
                  needleColor: colorPointer,
                  needleLength: 0.75,
                  needleStartWidth: 1,
                  needleEndWidth: 4,
                  knobStyle: KnobStyle(color: colorPointer, knobRadius: 0.09))
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                  widget: Text("${value.toStringAsFixed(1)}$unit",
                      style: TextStyle(
                          color: colorPointer,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  angle: 90,
                  positionFactor: 0.85)
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGlobalTable() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
          color: const Color(0xFF151125),
          borderRadius: BorderRadius.circular(8)),
      child: _historialRegistros.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text("Esperando primer ciclo de datos...",
                    style: TextStyle(color: Colors.white54)),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFF0C0917)),
                  columns: const [
                    DataColumn(
                        label: Text('Hora',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 11))),
                    DataColumn(
                        label: Text('Ciudad',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 11))),
                    DataColumn(
                        label: Text('Temp',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 11))),
                    DataColumn(
                        label: Text('Presión',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 11))),
                    DataColumn(
                        label: Text('Viento',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 11))),
                    DataColumn(
                        label: Text('Precip.',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 11))),
                    DataColumn(
                        label: Text('Nubes',
                            style:
                                TextStyle(color: Colors.amber, fontSize: 11))),
                  ],
                  rows: _historialRegistros
                      .map((reg) => DataRow(cells: [
                            DataCell(Text("${reg['hora']}",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11))),
                            DataCell(Text("${reg['ciudad']}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11))),
                            DataCell(Text("${reg['temp']}°C",
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text("${reg['presion']} hPa",
                                style: const TextStyle(
                                    color: Colors.tealAccent, fontSize: 11))),
                            DataCell(Text("${reg['viento_vel']} km/h",
                                style: const TextStyle(
                                    color: Colors.purpleAccent, fontSize: 11))),
                            DataCell(Text("${reg['precip']} mm",
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent,
                                    fontSize: 11))),
                            DataCell(Text("${reg['nubes']}%",
                                style: const TextStyle(
                                    color: Colors.blueGrey, fontSize: 11))),
                          ]))
                      .toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildInstrumentCard(String title, String valActual, Widget gauge) {
    return Card(
      color: const Color(0xFF161226),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(valActual,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            gauge,
            const Text("TABLA DE FRECUENCIAS ACUMULADA",
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.8),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2)
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFF0F0B1E)),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Rango',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 9))),
                    Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('F. Abs',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 9),
                            textAlign: TextAlign.center)),
                    Padding(
                        padding: EdgeInsets.all(6),
                        child: Text('Porc.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 9),
                            textAlign: TextAlign.center)),
                  ],
                ),
                ..._tablaFrec.map((f) => TableRow(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.white.withAlpha(13),
                                  width: 0.5))),
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(f['rango']!,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 9))),
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text("${f['abs']}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9),
                                textAlign: TextAlign.center)),
                        Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text("${f['porcentaje']}%",
                                style: const TextStyle(
                                    color: Color(0xFFFFCD16),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
