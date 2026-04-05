import 'package:flutter/foundation.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/feed_repository.dart';

/// Gerencia o estado do feed com cache local entre navegações.
/// Substitui o setState disperso no FeedScreen — o feed não recarrega
/// ao trocar de aba nem ao voltar de uma tela de detalhe.
class FeedNotifier extends ChangeNotifier {
  final FeedRepository _repo;

  FeedNotifier(this._repo);

  List<Post> posts = [];
  bool loading = false;
  bool loadingMore = false;
  String? error;
  String? _nextCursor;
  String scope = 'local';

  bool get hasMore => _nextCursor != null;
  bool get isEmpty => !loading && error == null && posts.isEmpty;

  /// Carrega o feed do zero (pull-to-refresh ou troca de scope).
  Future<void> load() async {
    loading = true;
    error = null;
    posts = [];
    _nextCursor = null;
    notifyListeners();

    try {
      final result = await _repo.getFeed(scope: scope, limit: 20);
      posts = List.from(result.data);
      _nextCursor = result.nextCursor;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Carrega mais posts (paginação infinita).
  Future<void> loadMore() async {
    if (loadingMore || _nextCursor == null) return;
    loadingMore = true;
    notifyListeners();

    try {
      final result = await _repo.getFeed(
          scope: scope, cursor: _nextCursor, limit: 20);
      posts = [...posts, ...result.data];
      _nextCursor = result.nextCursor;
    } catch (_) {
      // Falha silenciosa — mantém posts existentes
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  /// Troca o scope e recarrega.
  Future<void> changeScope(String newScope) async {
    if (scope == newScope) return;
    scope = newScope;
    await load();
  }

  /// Toggle de reação com atualização otimista + rollback em falha.
  Future<void> toggleReaction(Post post) async {
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final wasReacted = post.userReaction != null;

    // Atualização otimista
    posts = List.from(posts)
      ..[index] = _copyPostWithReaction(post,
          reacted: !wasReacted,
          delta: wasReacted ? -1 : 1);
    notifyListeners();

    try {
      if (wasReacted) {
        await _repo.removeReaction(post.id);
      } else {
        await _repo.addReaction(post.id, 'like');
      }
    } catch (_) {
      // Rollback se a chamada falhar
      posts = List.from(posts)
        ..[index] = _copyPostWithReaction(post,
            reacted: wasReacted,
            delta: 0);
      notifyListeners();
    }
  }

  /// Remove um post da lista local após deleção confirmada.
  Future<void> deletePost(String postId) async {
    await _repo.deletePost(postId);
    posts = posts.where((p) => p.id != postId).toList();
    notifyListeners();
  }

  /// Adiciona novo post no topo após criação.
  void onPostCreated() => load();

  Post _copyPostWithReaction(Post p, {required bool reacted, required int delta}) {
    return Post(
      id: p.id,
      authorId: p.authorId,
      content: p.content,
      scope: p.scope,
      mediaUrls: p.mediaUrls,
      reactionCount: (p.reactionCount + delta).clamp(0, 999999),
      commentCount: p.commentCount,
      userReaction: reacted ? 'like' : null,
      createdAt: p.createdAt,
      authorName: p.authorName,
      authorAvatarUrl: p.authorAvatarUrl,
      authorCourse: p.authorCourse,
      authorInstitutionName: p.authorInstitutionName,
    );
  }
}
