// This file is imported only on mobile/desktop platforms
import 'dart:io' show Platform;

String getPlatformType() {
  if (Platform.isAndroid) {
    return 'android';
  } else if (Platform.isIOS) {
    return 'ios';
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return 'desktop';
  }
  return 'unknown';
}
