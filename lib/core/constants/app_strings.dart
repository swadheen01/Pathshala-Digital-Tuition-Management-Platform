/// Static strings not yet migrated to proper .arb localization files
/// (see lib/l10n/). Kept here as a stopgap so screens aren't littered
/// with magic strings while full Bengali/English translation (spec §1)
/// is filled in.
class AppStrings {
  AppStrings._();

  static const String appName = 'Pathshala';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noInternet = 'No internet connection';
  static const String offlineSaved = 'Saved locally — will sync when online';
}
