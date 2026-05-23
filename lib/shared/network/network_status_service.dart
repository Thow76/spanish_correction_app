abstract interface class NetworkStatusService {
  Future<bool> get hasConnection;

  Stream<bool> get connectionChanges;
}
