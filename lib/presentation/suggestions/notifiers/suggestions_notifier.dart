import 'package:flutter/foundation.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/connection_suggestion.dart';

class SuggestionsNotifier extends ChangeNotifier {
  List<ConnectionSuggestion> items = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await sl.suggestionsRepo.list();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  void dismiss(String userId) {
    items = items.where((s) => s.userId != userId).toList();
    notifyListeners();
  }
}
