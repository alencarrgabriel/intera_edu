import '../../data/models/connection_model.dart';

abstract class ConnectionRepository {
  Future<List<Connection>> listConnections({String? status, String? direction});
  Future<void> sendRequest(String addresseeId);
  Future<void> updateRequest(String connectionId, String action); // 'accept' | 'reject'
  Future<void> removeConnection(String connectionId);
}
