import 'package:flutter/material.dart';

// 1. IMPORTACIONES ORIGINALES DE TUS CARPETAS
import 'package:colombia_datos_y_iss/colombia/colombia_screen.dart';
import 'package:colombia_datos_y_iss/iss/iss_screen.dart';
import 'package:colombia_datos_y_iss/weather/weather_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TerritorioColombiaApp());
}

class TerritorioColombiaApp extends StatelessWidget {
  const TerritorioColombiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal Territorial Colombia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF090D16),
        scaffoldBackgroundColor: const Color(0xFF010206),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Controla cuál de los 3 módulos se renderiza
  int _moduloSeleccionado = 0;

  // Lista de tus pantallas principales
  final List<Widget> _modulos = [
    const ColombiaScreen(),
    const WeatherScreen(),
    const IssScreen(),
  ];

  // Títulos dinámicos para saber en qué pantalla estamos parados
  final List<String> _titulos = [
    "INICIO / COLOMBIA",
    "MÓDULO DE CLIMA",
    "RASTREADOR ISS",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CORRECCIÓN NATIVA 1: Creamos el AppBar superior que contiene el botón "hamburguesa"
      appBar: AppBar(
        title: Text(
          _titulos[_moduloSeleccionado],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: const Color(0xFF090D16),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // CORRECCIÓN NATIVA 2: El menú pasa de ser un Row invasivo a un Drawer flotante
      drawer: Drawer(
        backgroundColor: const Color(0xFF151125),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera superior interna del menú
            Padding(
              padding:
                  const EdgeInsets.only(top: 60.0, left: 24.0, bottom: 30.0),
              child: Row(
                children: [
                  Icon(Icons.layers_outlined,
                      color: Colors.amber[400], size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    "Portal de Módulos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),

            // ÍTEM 0: Dashboard Colombia
            _buildMenuButton(
              index: 0,
              icon: Icons.map_outlined,
              label: "Inicio / Colombia",
              activeColor: Colors.blueAccent,
            ),

            // ÍTEM 1: Módulo de Clima
            _buildMenuButton(
              index: 1,
              icon: Icons.cloud_queue,
              label: "Módulo de Clima",
              activeColor: Colors.amber,
            ),

            // ÍTEM 2: Rastreador ISS
            _buildMenuButton(
              index: 2,
              icon: Icons.rocket_launch_outlined,
              label: "Rastreador ISS",
              activeColor: Colors.tealAccent,
            ),

            const Spacer(),

            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Sistema de Monitoreo v1.0",
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        ),
      ),

      // CORRECCIÓN NATIVA 3: El cuerpo de las regiones ahora ocupa el 100% de la pantalla limpiamente
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey<int>(_moduloSeleccionado),
          child: _modulos[_moduloSeleccionado],
        ),
      ),
    );
  }

  // Generador de los botones interactivos del menú
  Widget _buildMenuButton({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final bool esActivo = _moduloSeleccionado == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _moduloSeleccionado = index;
          });
          // 💡 IMPORTANTE: Esto cierra automáticamente el menú lateral deslizándolo
          // hacia la izquierda inmediatamente después de presionar la opción.
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: esActivo ? const Color(0xFF1B1632) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: esActivo ? activeColor : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: esActivo ? Colors.white : Colors.white70,
                  fontWeight: esActivo ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
