import 'dart:developer' as developer;

class LogUtils {
  static const String _appName = 'EcomApp';
  
  // Log levels
  static const int _verbose = 500;
  static const int _debug = 600;
  static const int _info = 800;
  static const int _warning = 900;
  static const int _error = 1000;
  
  /// Log verbose messages (most detailed)
  static void verbose(String message, {String? tag}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: _verbose,
    );
  }
  
  /// Log debug messages
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: _debug,
    );
  }
  
  /// Log info messages
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: _info,
    );
  }
  
  /// Log warning messages
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: _warning,
    );
  }
  
  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: '$_appName${tag != null ? ':$tag' : ''}',
      level: _error,
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log API calls
  static void api(String method, String url, {Map<String, String>? headers, String? body}) {
    developer.log(
      '🌐 $method Request: $url',
      name: '$_appName:API',
      level: _info,
    );
    
    if (headers != null && headers.isNotEmpty) {
      developer.log(
        '📋 Headers: $headers',
        name: '$_appName:API',
        level: _debug,
      );
    }
    
    if (body != null && body.isNotEmpty) {
      developer.log(
        '📤 Body: $body',
        name: '$_appName:API',
        level: _debug,
      );
    }
  }
  
  /// Log API responses
  static void apiResponse(int statusCode, String responseBody, {String? url}) {
    developer.log(
      '📥 Response: $statusCode${url != null ? ' - $url' : ''}',
      name: '$_appName:API',
      level: _info,
    );
    
    developer.log(
      '📥 Response Body: $responseBody',
      name: '$_appName:API',
      level: _debug,
    );
  }
  
  /// Log user actions
  static void userAction(String action, {Map<String, dynamic>? data}) {
    developer.log(
      '👤 User Action: $action',
      name: '$_appName:User',
      level: _info,
    );
    
    if (data != null && data.isNotEmpty) {
      developer.log(
        '📊 Data: $data',
        name: '$_appName:User',
        level: _debug,
      );
    }
  }
  
  /// Log navigation events
  static void navigation(String from, String to, {Map<String, dynamic>? arguments}) {
    developer.log(
      '🧭 Navigation: $from → $to',
      name: '$_appName:Navigation',
      level: _info,
    );
    
    if (arguments != null && arguments.isNotEmpty) {
      developer.log(
        '📋 Arguments: $arguments',
        name: '$_appName:Navigation',
        level: _debug,
      );
    }
  }
}
