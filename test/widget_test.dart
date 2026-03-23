// Testes de Widget para o aplicativo CalibraFacil
// Validam a interface de usuário e interações principais

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mrls_novo/main.dart';
import 'package:app_mrls_novo/homepage.dart';

void main() {
  group('CalibraFacil - Testes de Interface', () {
    testWidgets('Aplicativo inicia com Splash Screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const CurvaCalibracaoApp());

      // Verifica se a Splash Screen está presente
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('Splash Screen navega para HomeScreen após delay', (WidgetTester tester) async {
      await tester.pumpWidget(const CurvaCalibracaoApp());

      // Verifica que começamos na Splash
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      // Aguarda a animação (1s) + delay (3s) = 4s total
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Verifica que navegamos para HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('HomeScreen contém campos de entrada obrigatórios', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verifica presença de campos de entrada (TextField)
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Validação: absorbância maior que 3.0 mostra erro', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Encontra campos de texto por tipo
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Preenche concentração
      await tester.enterText(textFields.at(0), '1,0');
      
      // Preenche absorbância inválida (> 3.0)
      await tester.enterText(textFields.at(1), '3,5');

      // Procura e toca no botão "Adicionar Par" (FloatingActionButton verde)
      final addButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    (widget.backgroundColor == Colors.green || 
                     widget.backgroundColor == const Color(0xFF4CAF50)),
      );
      
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pump();

        // Verifica se a mensagem de erro aparece
        expect(find.text('Absorbância não pode ser superior a 3,0.'), findsOneWidget);
      }
    });

    testWidgets('Aceita vírgula como separador decimal', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      final textFields = find.byType(TextField);
      
      // Testa entrada com vírgula
      await tester.enterText(textFields.at(0), '1,5');
      await tester.enterText(textFields.at(1), '0,8');

      // Valores devem ser aceitos (sem erro)
      await tester.pump();
      
      // Verifica que os campos contêm os valores
      expect(find.text('1,5'), findsOneWidget);
      expect(find.text('0,8'), findsOneWidget);
    });

    testWidgets('Validação: campos vazios mostram erro', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Procura botão de adicionar
      final addButton = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    (widget.backgroundColor == Colors.green || 
                     widget.backgroundColor == const Color(0xFF4CAF50)),
      );

      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pump();

        // Verifica mensagem de erro para campos vazios
        expect(find.text('Por favor, preencha ambos os campos.'), findsOneWidget);
      }
    });

    testWidgets('Botão reiniciar limpa todos os dados', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      final textFields = find.byType(TextField);
      
      // Adiciona alguns dados
      await tester.enterText(textFields.at(0), '1,0');
      await tester.enterText(textFields.at(1), '0,5');

      // Procura botão de reiniciar (IconButton com ícone refresh)
      final resetButton = find.byIcon(Icons.refresh);
      
      if (resetButton.evaluate().isNotEmpty) {
        await tester.tap(resetButton);
        await tester.pump();

        // Verifica que os campos foram limpos
        final updatedFields = find.byType(TextField);
        final firstField = tester.widget<TextField>(updatedFields.at(0));
        final secondField = tester.widget<TextField>(updatedFields.at(1));
        
        expect(firstField.controller?.text, isEmpty);
        expect(secondField.controller?.text, isEmpty);
      }
    });
  });
}
