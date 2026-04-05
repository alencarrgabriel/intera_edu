import 'package:flutter_test/flutter_test.dart';
import 'package:intera_edu/data/models/post_model.dart';

void main() {
  group('PostModel.fromJson', () {
    test('parseia campos diretos (sem nested author)', () {
      final json = {
        'id': 'p1',
        'author_id': 'u1',
        'content': 'Olá mundo',
        'scope': 'local',
        'media_urls': ['https://cdn.example.com/img.png'],
        'reaction_count': 5,
        'comment_count': 2,
        'user_reaction': 'like',
        'created_at': '2026-01-01T10:00:00.000Z',
      };

      final post = PostModel.fromJson(json);

      expect(post.id, 'p1');
      expect(post.authorId, 'u1');
      expect(post.content, 'Olá mundo');
      expect(post.scope, 'local');
      expect(post.mediaUrls, ['https://cdn.example.com/img.png']);
      expect(post.reactionCount, 5);
      expect(post.commentCount, 2);
      expect(post.userReaction, 'like');
      expect(post.createdAt, DateTime.utc(2026, 1, 1, 10));
    });

    test('parseia objeto author aninhado', () {
      final json = {
        'id': 'p2',
        'content': 'Texto',
        'scope': 'global',
        'created_at': '2026-02-15T08:30:00.000Z',
        'author': {
          'id': 'u2',
          'full_name': 'Ana Lima',
          'avatar_url': 'https://cdn.example.com/avatar.png',
          'course': 'Engenharia',
          'institution': {'id': 'i1', 'name': 'UFMG'},
        },
      };

      final post = PostModel.fromJson(json);

      expect(post.authorId, 'u2');
      expect(post.authorName, 'Ana Lima');
      expect(post.authorAvatarUrl, 'https://cdn.example.com/avatar.png');
      expect(post.authorCourse, 'Engenharia');
      expect(post.authorInstitutionName, 'UFMG');
    });

    test('usa defaults quando campos opcionais ausentes', () {
      final json = {
        'id': 'p3',
        'content': 'Mínimo',
        'created_at': '2026-03-01T00:00:00.000Z',
      };

      final post = PostModel.fromJson(json);

      expect(post.scope, 'global');
      expect(post.mediaUrls, isEmpty);
      expect(post.reactionCount, 0);
      expect(post.commentCount, 0);
      expect(post.userReaction, isNull);
      expect(post.authorName, isNull);
    });
  });
}
