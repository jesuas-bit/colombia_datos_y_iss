import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class ColombiaScreen extends StatefulWidget {
  const ColombiaScreen({super.key});

  @override
  State<ColombiaScreen> createState() => _ColombiaScreenState();
}

class _ColombiaScreenState extends State<ColombiaScreen> {
  List<dynamic> _regiones = [];
  List<dynamic> _distritos = [];
  List<dynamic> _departamentos = [];
  List<dynamic> _atracciones = [];
  List<dynamic> _filtrados = [];

  bool _isLoading = true;
  String _selectedCat = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/colombia_data.json');
      final data = json.decode(response);
      setState(() {
        _regiones = data['regiones'] ?? [];
        _distritos = data['distritos_especiales'] ?? [];
        _departamentos = data['departamentos'] ?? [];
        _atracciones = data['atracciones'] ?? [];
        _filtrados = _atracciones;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR CARGANDO JSON: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filter(String cat) {
    setState(() {
      _selectedCat = cat;
      _filtrados = cat == 'Todos'
          ? _atracciones
          : _atracciones.where((a) => a['categoria'] == cat).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        appBar: AppBar(
          title: const Text('PORTAL TERRITORIAL COLOMBIA',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          backgroundColor: const Color(0xFF1A1A2E),
          // Ocultamos el botón del menú viejo porque ahora usamos el panel lateral del main.dart
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFFCD116),
            labelColor: Color(0xFFFCD116),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: '6 REGIONES'),
              Tab(text: '12 DISTRITOS'),
              Tab(text: '32 DEPTOS / CAPITALES'),
              Tab(text: 'GUÍA TURÍSTICA'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFCD116)))
            : TabBarView(
                children: [
                  _buildList(_regiones, "Region"),
                  _buildList(_distritos, "Distrito"),
                  _buildList(_departamentos, "Depto"),
                  _buildTurismo(),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<dynamic> data, String type) {
    if (data.isEmpty) {
      return const Center(
          child: Text("Sin datos locales encontrados",
              style: TextStyle(color: Colors.white)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final item = data[i];
        return Card(
          color: const Color(0xFF1A1A2E),
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            iconColor: const Color(0xFFFCD116),
            collapsedIconColor: Colors.white,
            title: Text(item['nombre'] ?? '',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
                type == "Depto"
                    ? "Capital: ${item['capital'] ?? ''}"
                    : (item['tipo'] ?? ""),
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildDetails(item, type),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDetails(dynamic item, String type) {
    if (type == "Region") {
      return [
        _row("Superficie", item['superficie'] ?? ''),
        _row("Población", item['poblacion'] ?? ''),
        _row("Clima", item['clima'] ?? ''),
        _row("Economía", item['economia'] ?? ''),
        const SizedBox(height: 10),
        Text(item['desc'] ?? '', style: const TextStyle(color: Colors.white70)),
      ];
    } else if (type == "Distrito") {
      return [
        _row("Código DANE", item['codigo_dane'] ?? ''),
        _row("Base Legal", item['base_legal'] ?? ''),
        _row("Funciones", item['funciones'] ?? ''),
      ];
    } else {
      return [
        _row("Código DANE", item['codigo_dane'] ?? ''),
        _row("Gentilicio", item['gentilicio'] ?? ''),
        const SizedBox(height: 10),
        const Text("Municipios Indexados:",
            style: TextStyle(
                color: Color(0xFFFCD116), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ((item['municipios'] ?? []) as List)
              .map((m) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(m.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  ))
              .toList(),
        )
      ];
    }
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(
                  color: Color(0xFFFCD116),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Expanded(
              child: Text(val,
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTurismo() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              'Todos',
              'Turismo de Naturaleza',
              'Turismo Cultural',
              'Sol y Playa'
            ]
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c,
                            style: TextStyle(
                                color: _selectedCat == c
                                    ? Colors.black
                                    : Colors.white)),
                        selected: _selectedCat == c,
                        selectedColor: const Color(0xFFFCD116),
                        onSelected: (_) => _filter(c),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: _filtrados.isEmpty
              ? const Center(
                  child: Text("No hay atractivos en esta categoría",
                      style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtrados.length,
                  itemBuilder: (context, i) {
                    final a = _filtrados[i];
                    return Card(
                      color: const Color(0xFF1A1A2E),
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(
                            a['imagen'] ?? '',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                                height: 200,
                                color: Colors.white10,
                                child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.white24, size: 40))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a['nombre'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text(a['lugar'] ?? '',
                                    style: const TextStyle(
                                        color: Color(0xFFFCD116),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text("Clasificación: ${a['tipologia'] ?? ''}",
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12)),
                                const SizedBox(height: 10),
                                Text(a['desc'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.4)),
                                const Divider(
                                    color: Colors.white10, height: 20),
                                _row("Cómo llegar", a['como_llegar'] ?? ''),
                                _row("Infraestructura",
                                    a['infraestructura'] ?? ''),
                                _row("Alertas/Seguridad", a['alertas'] ?? ''),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }
}
