import 'package:in_app_update/in_app_update.dart';

import '../domain/app_update_service.dart';

class PlayAppUpdateService implements AppUpdateService {
  @override
  Future<AppUpdateStatus> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return const AppUpdateStatus.latest();
      }
      if (info.immediateUpdateAllowed) {
        return const AppUpdateStatus.available(AppUpdateInstallMode.immediate);
      }
      if (info.flexibleUpdateAllowed) {
        return const AppUpdateStatus.available(AppUpdateInstallMode.flexible);
      }
      return const AppUpdateStatus.unavailable();
    } catch (_) {
      // In-app updates are only provided by a compatible Google Play install.
      // An offline device or a development build must remain fully usable.
      return const AppUpdateStatus.unavailable();
    }
  }

  @override
  Future<void> startUpdate(AppUpdateStatus status) async {
    switch (status.installMode) {
      case AppUpdateInstallMode.immediate:
        await InAppUpdate.performImmediateUpdate();
      case AppUpdateInstallMode.flexible:
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      case null:
        throw StateError('No Google Play update flow is available.');
    }
  }
}
