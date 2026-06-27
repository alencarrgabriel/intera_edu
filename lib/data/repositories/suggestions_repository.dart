import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/connection_suggestion.dart';

class SuggestionsRepository {
  final ApiClient _api;
  SuggestionsRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<ConnectionSuggestion>> list() async {
    final res = await _api.get(ApiEndpoints.suggestions);
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => ConnectionSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
