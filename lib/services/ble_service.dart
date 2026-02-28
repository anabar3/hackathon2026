// lib/services/ble_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'supabase_service.dart';

/// Custom Service UUID for Collect app BLE discovery.
const String _collectServiceUuid = '0000FACE-0000-1000-8000-00805F9B34FB';

/// Manufacturer ID — 0xFFFF (reserved for testing / development).
const int _manufacturerId = 0xFFFF;

/// Minimum seconds between recording the same encounter.
const int _encounterCooldownSeconds = 300; // 5 min

class BleService {
  BleService._();
  static final BleService instance = BleService._();

  final _supabase = SupabaseService();
  final _peripheral = FlutterBlePeripheral();
  String? _userId;
  StreamSubscription<List<ScanResult>>? _scanSub;
  final Map<String, DateTime> _recentEncounters = {};

  /// Callback fired when a new encounter is detected.
  void Function(String encounteredUserId)? onEncounterDetected;

  // ─── PERMISSIONS ───────────────────────────────────

  Future<bool> requestPermissions() async {
    print('[BLE] Requesting permissions...');

    // In Android 11+, you cannot request foreground and background location at the same time.
    final basicStatuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    print('[BLE] Basic permissions status: $basicStatuses');

    final bool basicGranted =
        basicStatuses[Permission.bluetoothScan]!.isGranted &&
        basicStatuses[Permission.bluetoothAdvertise]!.isGranted &&
        basicStatuses[Permission.locationWhenInUse]!.isGranted;

    if (basicGranted) {
      // Now request background location separately
      final bgStatus = await Permission.locationAlways.request();
      print('[BLE] Background location status: $bgStatus');
    }

    return basicGranted;
  }

  Future<bool> checkPermissionsSilently() async {
    final scan = await Permission.bluetoothScan.status;
    final advertise = await Permission.bluetoothAdvertise.status;
    final loc = await Permission.locationWhenInUse.status;

    return scan.isGranted && advertise.isGranted && loc.isGranted;
  }

  /// Real-time list of currently nearby user IDs
  final ValueNotifier<List<String>> nearbyUsers = ValueNotifier([]);

  Timer? _cleanupTimer;

  // ─── INIT ──────────────────────────────────────────

  Future<void> init(String userId) async {
    print('[BLE] init() called for user: $userId');
    _userId = userId;
    final ok = await requestPermissions();
    if (!ok) {
      print('[BLE] Permissions denied, cannot start.');
      return;
    }

    // Start a timer to remove devices we haven't seen in 4 seconds
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _cleanupStaleDevices(),
    );

    // Wait for Bluetooth adapter to be on
    print('[BLE] Waiting for Bluetooth to be ON...');
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.adapterState
          .firstWhere((s) => s == BluetoothAdapterState.on)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('[BLE] Timeout waiting for BT ON.');
              return BluetoothAdapterState.off;
            },
          );
    }

    print('[BLE] Bluetooth is ON. Starting Advertising & Scanning.');
    await startAdvertising();
    startScanning();
  }

  // ─── UUID / HEX CONVERSION HELPER ───────────────

  List<int> _uuidToBytes(String uuid) {
    final hex = uuid.replaceAll('-', '');
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  String _bytesToUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    if (hex.length == 32) {
      return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    }
    return '';
  }

  // ─── ADVERTISE (peripheral role via flutter_ble_peripheral) ────

  Uint8List _buildManufacturerData(String userId) {
    // BLE manufacturer data size limits are strictly ~24 bytes.
    // A 36-char string UUID doesn't fit in UTF-8. We must pack it as 16 binary bytes.
    final bytes = _uuidToBytes(userId);
    return Uint8List.fromList(bytes);
  }

  Future<void> startAdvertising() async {
    if (_userId == null) return;
    print('[BLE] startAdvertising() called.');

    try {
      final supported = await _peripheral.isSupported;
      print('[BLE] Peripheral supported: $supported');
      if (!supported) return;

      final advertiseData = AdvertiseData(
        serviceUuid: _collectServiceUuid,
        manufacturerId: _manufacturerId,
        manufacturerData: _buildManufacturerData(_userId!),
      );

      final advertiseSettings = AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeBalanced,
        txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
        connectable: false,
        timeout: 0,
      );

      await _peripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings,
      );
      print('[BLE] Advertising STARTED successfully.');
    } catch (e) {
      print('[BLE] Error starting advertising: $e');
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _peripheral.stop();
      print('[BLE] Advertising STOPPED.');
    } catch (e) {
      print('[BLE] Error stopping advertising: $e');
    }
  }

  // ─── SCAN (central role via flutter_blue_plus) ─────

  void startScanning() {
    if (_userId == null) return;
    print('[BLE] startScanning() called.');

    _scanSub?.cancel();

    // Removing 'withServices' filter to see ALL devices around, then we filter manually.
    // Sometimes the peripheral doesn't pack the service UUID correctly if manufacturer data is too large.
    FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
      continuousUpdates: true,
    );
    print('[BLE] Scan started.');

    _scanSub = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (final r in results) {
          _processScanResult(r);
        }
      },
      onError: (e) {
        print('[BLE] Scan error: $e');
      },
    );
  }

  void stopScanning() {
    _scanSub?.cancel();
    _scanSub = null;
    FlutterBluePlus.stopScan();
    print('[BLE] Scan STOPPED.');
  }

  void _cleanupStaleDevices() {
    if (_recentEncounters.isEmpty) return;
    final now = DateTime.now();
    bool changed = false;

    // Remove users not seen in the last 4 seconds from the live UI
    final currentList = nearbyUsers.value.toList();
    currentList.removeWhere((id) {
      final lastSeen = _recentEncounters[id];
      if (lastSeen == null) return true;
      if (now.difference(lastSeen).inSeconds > 4) {
        changed = true;
        return true;
      }
      return false;
    });

    if (changed) {
      nearbyUsers.value = currentList;
    }
  }

  /// Forces the UI list to clear so it repopulates freshly with devices currently in range
  void forceRefreshUI() {
    nearbyUsers.value = [];
  }

  void _processScanResult(ScanResult result) {
    // flutter_blue_plus stream accumulates all devices seen since startScan.
    // We must ignore cached results that haven't been updated recently.
    if (DateTime.now().difference(result.timeStamp).inSeconds > 5) {
      return;
    }

    final msd = result.advertisementData.manufacturerData;
    if (msd.isEmpty) return;

    // We used _manufacturerId = 0xFFFF
    final data = msd[_manufacturerId];
    if (data == null || data.isEmpty) return;

    String? encounteredId;
    try {
      // Decode the 16 bytes back to a UUID string
      List<int> uuidBytes = data;
      // If Android accidentally left the 0xFFFF at the start of the payload, strip it.
      if (data.length == 18 && data[0] == 255 && data[1] == 255) {
        uuidBytes = data.sublist(2);
      }

      if (uuidBytes.length == 16) {
        encounteredId = _bytesToUuid(uuidBytes);
      } else {
        return; // Not our expected payload size
      }
    } catch (e) {
      print('[BLE] Failed to decode user ID bytes: $e, Bytes: $data');
      return;
    }

    if (encounteredId.isEmpty) return;

    if (encounteredId == _userId) {
      return;
    }

    final now = DateTime.now();
    final last = _recentEncounters[encounteredId];

    // Update last seen for the live UI
    _recentEncounters[encounteredId] = now;

    if (!nearbyUsers.value.contains(encounteredId)) {
      print('[BLE] LIVE DEVICE DISCOVERED: $encounteredId');
      nearbyUsers.value = [...nearbyUsers.value, encounteredId];

      // Also record it to DB silently if it's been more than 5 minutes since we logged it
      if (last == null ||
          now.difference(last).inSeconds > _encounterCooldownSeconds) {
        _recordEncounter(encounteredId);
      }
    }
  }

  Future<void> _recordEncounter(String encounteredUserId) async {
    try {
      print('[BLE] Saving encounter to DB: $_userId -> $encounteredUserId');
      await _supabase.registrarEncuentro(encounteredUserId);
      onEncounterDetected?.call(encounteredUserId);
    } catch (e) {
      print('[BLE] ERROR saving encounter: $e');
    }
  }

  // ─── CLEANUP ───────────────────────────────────────

  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    stopScanning();
    await stopAdvertising();
    _recentEncounters.clear();
    nearbyUsers.value = [];
    _userId = null;
    print('[BLE] Service disposed.');
  }
}
