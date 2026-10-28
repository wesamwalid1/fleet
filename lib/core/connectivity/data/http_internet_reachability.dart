import 'package:http/http.dart' as http;

import '../domain/internet_reachability.dart';

/// Lightweight on-demand Internet probe via a well-known generate_204 URL.
///
/// This only confirms general Internet access, not Driver Portal backend
/// health. Swap for a backend `/health` call when the API exists.
///
/// Owns its [http.Client] and closes it from [dispose]. Callers must not
/// dispose the client while a [check] is still in flight — [ConnectivityBloc]
/// awaits in-flight probes before disposing reachability.
class HttpInternetReachability implements InternetReachability {
  /// Android-style connectivity check endpoint (expects HTTP 204).
  static final Uri defaultProbeUri = Uri.parse(
    'https://connectivitycheck.gstatic.com/generate_204',
  );

  final http.Client _client;
  final Uri _uri;
  final bool _ownsClient;
  bool _disposed = false;

  HttpInternetReachability({http.Client? client, Uri? uri})
    : _client = client ?? http.Client(),
      _uri = uri ?? defaultProbeUri,
      _ownsClient = client == null;

  @override
  Future<bool> check({Duration timeout = const Duration(seconds: 3)}) async {
    if (_disposed) return false;
    try {
      final response = await _client.get(_uri).timeout(timeout);
      // 204 is ideal; accept other 2xx/3xx as "reachable enough".
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_ownsClient) {
      _client.close();
    }
  }
}
