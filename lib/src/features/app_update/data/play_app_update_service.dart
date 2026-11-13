import 'package:in_app_update/in_app_update.dart';

import '../domain/app_update_service.dart';

class PlayAppUpdateService implements AppUpdateService {
  @override
  Future<AppUpdateStatus> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateNotAvailable) {
        return const AppUpdateStatus.latest();
      }
      if (info.updateAvailability != UpdateAvailability.updateAvailable &&
          info.updateAvailability !=
              UpdateAvailability.developerTriggeredUpdateInProgress) {
        return const AppUpdateStatus.unavailable();
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
    // Play's AppUpdateInfo is single-use. Refresh even after user cancellation.
    final freshStatus = await checkForUpdate().timeout(
      const Duration(seconds: 15),
    );
    if (freshStatus.availability == AppUpdateAvailability.latest) return;
    switch (freshStatus.installMode) {
      case AppUpdateInstallMode.immediate:
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.inAppUpdateFailed) {
          throw StateError('Google Play could not start the update.');
        }
      case AppUpdateInstallMode.flexible:
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.userDeniedUpdate) return;
        if (result == AppUpdateResult.inAppUpdateFailed) {
          throw StateError('Google Play could not start the update.');
        }
        // The download has finished; only bound the install handoff, not download.
        await InAppUpdate.completeFlexibleUpdate().timeout(
          const Duration(seconds: 15),
        );
      case null:
        throw StateError('No Google Play update flow is available.');
    }
  }
}
