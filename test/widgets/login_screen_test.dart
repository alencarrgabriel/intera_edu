import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:intera_edu/core/auth/auth_notifier.dart';
import 'package:intera_edu/presentation/auth/screens/login_screen.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthNotifier])
void main() {
  late MockAuthNotifier authNotifier;

  setUp(() {
    authNotifier = MockAuthNotifier();
    when(authNotifier.status).thenReturn(AuthStatus.unauthenticated);
    // addListener/removeListener são chamados pelo Provider internamente
    when(authNotifier.addListener(any)).thenReturn(null);
    when(authNotifier.removeListener(any)).thenReturn(null);
    when(authNotifier.hasListeners).thenReturn(false);
  });

  Widget buildSubject() {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthNotifier>.value(
        value: authNotifier,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renderiza campos de email e senha', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('E-mail Institucional'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('exibe erro de validação com email inválido', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail Institucional'),
          'nao-é-email');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Informe um email válido'), findsOneWidget);
    });

    testWidgets('chama AuthNotifier.login com credenciais corretas',
        (tester) async {
      when(authNotifier.login(any, any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail Institucional'),
          'aluno@ufmg.edu.br');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha'), 'Senha@123');

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      verify(authNotifier.login('aluno@ufmg.edu.br', 'Senha@123')).called(1);
    });

    testWidgets('exibe SnackBar quando login falha', (tester) async {
      when(authNotifier.login(any, any))
          .thenThrow(Exception('Credenciais inválidas'));

      await tester.pumpWidget(buildSubject());

      await tester.enterText(
          find.widgetWithText(TextFormField, 'E-mail Institucional'),
          'aluno@ufmg.edu.br');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha'), 'Senha@123');

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
