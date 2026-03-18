import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/repositories/connection_repository.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final ApiClient _api;
  ConnectionRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<List<Map<String, dynamic>>> listConnections({
    String? status,
    String? direction,
  }) async {
    final res = await _api.get(ApiEndpoints.connections, queryParams: {
      if (status != null) 'status': status,
      if (direction != null) 'direction': direction,
    });
    final data = res['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> sendRequest(String addresseeId) async {
    await _api.post(ApiEndpoints.connections, body: {'addressee_id': addresseeId});
  }

  @override
  Future<void> updateRequest(String connectionId, String action) async {
    await _api.patch(ApiEndpoints.connection(connectionId), body: {'action': action});
  }

  @override
  Future<void> removeConnection(String connectionId) async {
    await _api.delete(ApiEndpoints.connection(connectionId));
  }
}
