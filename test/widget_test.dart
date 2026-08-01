// Prueba básica de widget en Flutter.


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asthmaapp/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construir la app y renderizar frame.
    await tester.pumpWidget(const MainApp());

    // Verificar que el contador inicie en 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tocar el icono '+' y actualizar.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verificar que el contador se haya incrementado.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
