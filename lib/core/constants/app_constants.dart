import '../config/app_config.dart';

/// Kept for existing imports; the values live in [AppConfig]. New code should
/// use [AppConfig] directly.
abstract final class AppConstants {
  static const String appName = AppConfig.appName;
  static const String remoteAssetOrigin = AppConfig.remoteAssetOrigin;
}
