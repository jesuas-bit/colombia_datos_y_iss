import 'package:flutter_test/flutter_test.dart';
import 'package:colombia_datos_y_iss/main.dart';

void main() {
  testWidgets('App principal smoke test', (WidgetTester tester) async {
    // Construye nuestra aplicación y genera un fotograma.
    await tester.pumpWidget(const TerritorioColombiaApp());

    // Verifica que el título principal se renderice correctamente.
    expect(find.text('PORTAL TERRITORIAL COLOMBIA'), findsOneWidget);
  });
}
