import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:intera_edu/core/di/service_locator.dart';
import 'package:intera_edu/domain/repositories/feed_repository.dart';
import 'package:intera_edu/presentation/feed/screens/create_post_screen.dart';

import 'create_post_screen_test.mocks.dart';

@GenerateMocks([FeedRepository])
void main() {
  late MockFeedRepository feedRepo;

  setUp(() {
    feedRepo = MockFeedRepository();
    sl.registerOverrides(feedRepo: feedRepo);
  });

  tearDown(() => sl.reset());

  Widget buildSubject() {
    return MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const CreatePostScreen(),
          ),
        ],
      ),
    );
  }

  group('CreatePostScreen', () {
    testWidgets('botão Publicar desabilitado quando campo vazio', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('botão Publicar habilitado com texto preenchido', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Minha primeira publicação!');
      await tester.pump();

      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('chama feedRepo.createPost ao publicar', (tester) async {
      when(feedRepo.createPost(content: anyNamed('content'), scope: anyNamed('scope')))
          .thenAnswer((_) async => 'new-post-id');

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Teste de publicação');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      verify(feedRepo.createPost(
        content: 'Teste de publicação',
        scope: 'local',
      )).called(1);
    });

    testWidgets('exibe SnackBar quando createPost falha', (tester) async {
      when(feedRepo.createPost(content: anyNamed('content'), scope: anyNamed('scope')))
          .thenThrow(Exception('Erro de rede'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Texto qualquer');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
