import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:intera_edu/domain/entities/post.dart';
import 'package:intera_edu/domain/repositories/feed_repository.dart';
import 'package:intera_edu/presentation/feed/notifiers/feed_notifier.dart';

import 'feed_notifier_test.mocks.dart';

@GenerateMocks([FeedRepository])
void main() {
  late MockFeedRepository repo;
  late FeedNotifier notifier;

  Post _makePost(String id, {String? reaction}) => Post(
        id: id,
        authorId: 'u1',
        content: 'Conteúdo do post $id',
        reactionCount: reaction != null ? 1 : 0,
        userReaction: reaction,
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    repo = MockFeedRepository();
    notifier = FeedNotifier(repo);
  });

  group('load()', () {
    test('popula posts e limpa erro em sucesso', () async {
      final posts = [_makePost('p1'), _makePost('p2')];
      when(repo.getFeed(scope: 'local', limit: 20))
          .thenAnswer((_) async => PaginatedResult(data: posts, nextCursor: null));

      await notifier.load();

      expect(notifier.posts, posts);
      expect(notifier.error, isNull);
      expect(notifier.loading, isFalse);
    });

    test('registra erro quando getFeed lança exceção', () async {
      when(repo.getFeed(scope: 'local', limit: 20))
          .thenThrow(Exception('sem conexão'));

      await notifier.load();

      expect(notifier.error, contains('sem conexão'));
      expect(notifier.posts, isEmpty);
      expect(notifier.loading, isFalse);
    });

    test('hasMore é true quando há next_cursor', () async {
      when(repo.getFeed(scope: 'local', limit: 20))
          .thenAnswer((_) async => PaginatedResult(
                data: [_makePost('p1')],
                nextCursor: 'cursor_abc',
              ));

      await notifier.load();

      expect(notifier.hasMore, isTrue);
    });
  });

  group('toggleReaction()', () {
    test('reação otimista: sem reação → com reação, contador +1', () async {
      final post = _makePost('p1');
      when(repo.getFeed(scope: 'local', limit: 20))
          .thenAnswer((_) async => PaginatedResult(data: [post]));
      when(repo.addReaction('p1', 'like')).thenAnswer((_) async {});

      await notifier.load();
      await notifier.toggleReaction(notifier.posts[0]);

      expect(notifier.posts[0].userReaction, 'like');
      expect(notifier.posts[0].reactionCount, 1);
      verify(repo.addReaction('p1', 'like')).called(1);
    });

    test('reação otimista: com reação → sem reação, contador -1', () async {
      final post = _makePost('p1', reaction: 'like');
      when(repo.getFeed(scope: 'local', limit: 20))
          .thenAnswer((_) async => PaginatedResult(data: [post]));
      when(repo.removeReaction('p1')).thenAnswer((_) async {});

      await notifier.load();
      await notifier.toggleReaction(notifier.posts[0]);

      expect(notifier.posts[0].userReaction, isNull);
      expect(notifier.posts[0].reactionCount, 0);
      verify(repo.removeReaction('p1')).called(1);
    });

    test('rollback quando addReaction falha', () async {
      final post = _makePost('p1');
      when(repo.getFeed(scope: 'local', limit: 20))
          .thenAnswer((_) async => PaginatedResult(data: [post]));
      when(repo.addReaction('p1', 'like')).thenThrow(Exception('erro'));

      await notifier.load();
      await notifier.toggleReaction(notifier.posts[0]);

      // Deve reverter para o estado original
      expect(notifier.posts[0].userReaction, isNull);
      expect(notifier.posts[0].reactionCount, 0);
    });
  });

  group('changeScope()', () {
    test('recarrega quando scope muda', () async {
      when(repo.getFeed(scope: anyNamed('scope'), limit: 20))
          .thenAnswer((_) async => PaginatedResult(data: []));

      await notifier.load();
      await notifier.changeScope('global');

      expect(notifier.scope, 'global');
      verify(repo.getFeed(scope: 'local', limit: 20)).called(1);
      verify(repo.getFeed(scope: 'global', limit: 20)).called(1);
    });

    test('não recarrega quando scope não muda', () async {
      when(repo.getFeed(scope: 'local', limit: 20))
          .thenAnswer((_) async => PaginatedResult(data: []));

      await notifier.load();
      await notifier.changeScope('local');

      verify(repo.getFeed(scope: 'local', limit: 20)).called(1);
    });
  });
}
