abstract class ConnectionRepository {
  Future<List<Map<String, dynamic>>> listConnections({String? status, String? direction});
  Future<void> sendRequest(String addresseeId);
  Future<void> updateRequest(String connectionId, String action); // 'accept' | 'reject'
  Future<void> removeConnection(String connectionId);
}
