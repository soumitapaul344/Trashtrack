import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RiderLocationService {
  RiderLocationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  Timer? _timer;
  bool _isUpdating = false;

  Future<void> startLocationUpdates({
    required String riderId,
    Duration interval = const Duration(seconds: 10),
  }) async {
    developer.log(
      '[RiderLocationService] Starting location updates for rider: $riderId',
    );

    final canProceed = await _ensurePermission();
    if (!canProceed) {
      developer.log('[RiderLocationService] Permission denied, cannot proceed');
      return;
    }

    await _updateOnce(riderId);
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _updateOnce(riderId));
    developer.log(
      '[RiderLocationService] Location updates started with ${interval.inSeconds}s interval',
    );
  }

  Future<void> stopLocationUpdates() async {
    developer.log('[RiderLocationService] Stopping location updates');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _updateOnce(String riderId) async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      developer.log(
        '[RiderLocationService] Got position: ${position.latitude}, ${position.longitude}',
      );

      await _firestore.collection('riders').doc(riderId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      developer.log('[RiderLocationService] Successfully updated Firestore');
    } catch (e) {
      developer.log(
        '[RiderLocationService] Error updating location: $e',
        error: e,
      );
    } finally {
      _isUpdating = false;
    }
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    developer.log(
      '[RiderLocationService] Location service enabled: $serviceEnabled',
    );
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    developer.log('[RiderLocationService] Current permission: $permission');

    if (permission == LocationPermission.denied) {
      developer.log('[RiderLocationService] Requesting location permission');
      permission = await Geolocator.requestPermission();
      developer.log(
        '[RiderLocationService] Permission after request: $permission',
      );
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      developer.log('[RiderLocationService] Permission denied forever');
      return false;
    }

    return true;
  }
}
