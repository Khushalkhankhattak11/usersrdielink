import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<void> requestStartupPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      permission = await Geolocator.checkPermission();
      final canUseLocation =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (canUseLocation && !await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      }
    } on Object {
      // Permission prompts should never block app startup.
    }
  }

  Future<String?> currentLocationLabel() async {
    final snapshot = await currentLocationSnapshot();
    return snapshot?['label'] as String?;
  }

  Future<Map<String, Object?>?> currentLocationSnapshot() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await _currentPosition();
      if (position == null) {
        return null;
      }

      final fallbackLabel = _coordinateLabel(
        position.latitude,
        position.longitude,
      );
      var label = fallbackLabel;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placeLabel = _placeLabel(placemarks.first);
          if (placeLabel.isNotEmpty) {
            label = placeLabel;
          }
        }
      } on Object {
        label = fallbackLabel;
      }

      return {
        'label': label,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } on Object {
      return null;
    }
  }

  Future<Position?> _currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on Object {
      return Geolocator.getLastKnownPosition();
    }
  }

  String _placeLabel(Placemark place) {
    final street = _clean(place.street);
    final subLocality = _clean(place.subLocality);
    final locality = _clean(place.locality);
    final subAdministrativeArea = _clean(place.subAdministrativeArea);
    final administrativeArea = _clean(place.administrativeArea);
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (subLocality.isNotEmpty && !_containsPart(street, subLocality))
        subLocality,
      if (locality.isNotEmpty &&
          !_containsPart(street, locality) &&
          !_containsPart(subLocality, locality))
        locality,
      if (locality.isEmpty && subAdministrativeArea.isNotEmpty)
        subAdministrativeArea,
      if (locality.isEmpty &&
          subAdministrativeArea.isEmpty &&
          administrativeArea.isNotEmpty)
        administrativeArea,
    ];
    return parts.take(3).join(' ').trim();
  }

  String _clean(String? value) {
    return (value ?? '')
        .replaceAll('+', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsPart(String value, String part) {
    return value.toLowerCase().contains(part.toLowerCase());
  }

  String _coordinateLabel(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }
}
