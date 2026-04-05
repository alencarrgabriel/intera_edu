import 'package:flutter/foundation.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/profile_repository.dart';

/// Gerencia o estado do perfil do usuário logado com cache local.
/// Compartilhado entre MyProfileScreen e EditProfileScreen —
/// ao editar e salvar, o perfil atualizado é refletido automaticamente.
class ProfileNotifier extends ChangeNotifier {
  final ProfileRepository _repo;

  ProfileNotifier(this._repo);

  User? profile;
  bool loading = false;
  String? error;

  /// Carrega o perfil. Ignora se já há dados em cache.
  Future<void> load({bool force = false}) async {
    if (!force && profile != null) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await _repo.getMyProfile();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Atualiza o perfil e invalida o cache.
  Future<void> update(Map<String, dynamic> data) async {
    await _repo.updateProfile(data);
    // Recarrega do servidor para garantir dados frescos
    await load(force: true);
  }
}
