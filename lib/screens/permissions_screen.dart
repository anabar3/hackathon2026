import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ble_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const PermissionsScreen({super.key, required this.onGranted});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isRequesting = false;
  bool _error = false;

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
      _error = false;
    });

    final ok = await BleService.instance.requestPermissions();

    if (!mounted) return;

    if (ok) {
      widget.onGranted();
    } else {
      setState(() {
        _isRequesting = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.border.withAlpha(50),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 56,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'We Need Your Permission',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Collect uses Bluetooth and Location to discover nearby people and their public boards while you walk on the Street.',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.destruct.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.destruct),
                  ),
                  child: const Text(
                    'Permissions are required to continue. Please open app settings to permit.',
                    style: TextStyle(
                      color: AppColors.destruct,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting
                      ? null
                      : (_error
                            ? () => openAppSettings()
                            : _requestPermissions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isRequesting
                      ? const CircularProgressIndicator(
                          color: AppColors.primaryForeground,
                        )
                      : Text(
                          _error ? 'Open App Settings' : 'Grant Permissions',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
