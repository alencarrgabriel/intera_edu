import 'package:flutter_test/flutter_test.dart';
import 'package:intera_edu/data/models/comment_model.dart';

void main() {
  group('CommentModel.fromJson', () {
    test('parseia campos diretos', () {
      final json = {
        'id': 'c1',
        'post_id': 'p1',
        'author_id': 'u1',
        'content': 'Ótimo post!',
        'created_at': '2026-01-02T12:00:00.000Z',
        'author_name': 'Carlos',
        'author_avatar_url': null,
      };

      final comment = CommentModel.fromJson(json);

      expect(comment.id, 'c1');
      expect(comment.postId, 'p1');
      expect(comment.authorId, 'u1');
      expect(comment.content, 'Ótimo post!');
      expect(comment.authorName, 'Carlos');
      expect(comment.parentCommentId, isNull);
    });

    test('parseia author aninhado', () {
      final json = {
        'id': 'c2',
        'post_id': 'p1',
        'content': 'Concordo!',
        'created_at': '2026-01-03T09:00:00.000Z',
        'author': {
          'id': 'u3',
          'full_name': 'Maria',
          'avatar_url': 'https://cdn.example.com/m.png',
        },
      };

      final comment = CommentModel.fromJson(json);

      expect(comment.authorId, 'u3');
      expect(comment.authorName, 'Maria');
      expect(comment.authorAvatarUrl, 'https://cdn.example.com/m.png');
    });

    test('parentCommentId é preservado', () {
      final json = {
        'id': 'c3',
        'post_id': 'p1',
        'author_id': 'u1',
        'content': 'Resposta',
        'parent_comment_id': 'c1',
        'created_at': '2026-01-04T10:00:00.000Z',
      };

      final comment = CommentModel.fromJson(json);
      expect(comment.parentCommentId, 'c1');
    });
  });
}
