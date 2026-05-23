import 'package:connectivity_plus/connectivity_plus.dart';

import 'network_status_service.dart';

class ConnectivityNetworkStatusService implements NetworkStatusService {
  ConnectivityNetworkStatusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get hasConnection async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get connectionChanges {
    return _connectivity.onConnectivityChanged.map(_hasConnection).distinct();
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
