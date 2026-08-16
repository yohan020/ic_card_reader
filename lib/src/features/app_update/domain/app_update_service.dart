enum AppUpdateAvailability { unknown, latest, updateAvailable, unavailable }

enum AppUpdateInstallMode { immediate, flexible }

class AppUpdateStatus {
  const AppUpdateStatus._(this.availability, {this.installMode});

  const AppUpdateStatus.unknown() : this._(AppUpdateAvailability.unknown);

  const AppUpdateStatus.latest() : this._(AppUpdateAvailability.latest);

  const AppUpdateStatus.available(AppUpdateInstallMode installMode)
    : this._(AppUpdateAvailability.updateAvailable, installMode: installMode);

  const AppUpdateStatus.unavailable()
    : this._(AppUpdateAvailability.unavailable);

  final AppUpdateAvailability availability;
  final AppUpdateInstallMode? installMode;

  bool get hasUpdate => availability == AppUpdateAvailability.updateAvailable;
}

abstract interface class AppUpdateService {
  Future<AppUpdateStatus> checkForUpdate();

  Future<void> startUpdate(AppUpdateStatus status);
}
