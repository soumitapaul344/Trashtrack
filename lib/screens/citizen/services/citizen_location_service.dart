import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CitizenLocationService {
  CitizenLocationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  Timer? _timer;
  bool _isUpdating = false;

  Future<void> startLocationUpdates({
    required String citizenId,
    Duration interval = const Duration(seconds: 10),
  }) async {
    developer.log(
      '[CitizenLocationService] Starting location updates for citizen: $citizenId',
    );

    final canProceed = await _ensurePermission();
    if (!canProceed) {
      developer.log(
        '[CitizenLocationService] Permission denied, cannot proceed',
      );
      return;
    }

    await _updateOnce(citizenId);
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _updateOnce(citizenId));
    developer.log(
      '[CitizenLocationService] Location updates started with ${interval.inSeconds}s interval',
    );
  }

  Future<void> stopLocationUpdates() async {
    developer.log('[CitizenLocationService] Stopping location updates');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _updateOnce(String citizenId) async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      developer.log(
        '[CitizenLocationService] Got position: ${position.latitude}, ${position.longitude}',
      );

      await _firestore.collection('citizens').doc(citizenId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      developer.log('[CitizenLocationService] Successfully updated Firestore');
    } catch (e) {
      developer.log(
        '[CitizenLocationService] Error updating location: $e',
        error: e,
      );
    } finally {
      _isUpdating = false;
    }
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    developer.log(
      '[CitizenLocationService] Location service enabled: $serviceEnabled',
    );
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    developer.log('[CitizenLocationService] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      developer.log('[CitizenLocationService] Requesting location permission');
      permission = await Geolocator.requestPermission();
      developer.log(
        '[CitizenLocationService] Permission after request: $permission',
      );
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      developer.log('[CitizenLocationService] Permission denied forever');
      return false;
    }

    return true;
  }
}
