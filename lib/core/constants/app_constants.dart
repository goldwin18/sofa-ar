/// Values used in more than one place.
class AppConstants {
  AppConstants._();

  static const appName = 'Sofa AR';
  static const tagline = 'See how it looks in your room';

  /// Used when the user does not tell us how wide their sofa is.
  static const defaultSofaWidthMeters = 2.0;
  static const minSofaWidthMeters = 1.0;
  static const maxSofaWidthMeters = 3.5;

  /// Large photos are shrunk to this before processing, to keep things fast.
  static const maxImageSide = 1024;

  /// Public https folder holding the sample .glb files. Google's AR viewer can only load
  /// models from an https link. This serves the repo's assets/models folder via jsDelivr,
  /// so the GitHub repo must be PUBLIC. Change this if you host the models elsewhere.
  static const hostedModelsBaseUrl =
      'https://cdn.jsdelivr.net/gh/goldwin18/sofa-ar@main/assets/models';

  // SharedPreferences keys
  static const prefsUserSofas = 'user_sofas_v1';
  static const prefsMeshyApiKey = 'meshy_api_key';
}
