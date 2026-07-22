import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../home/providers/spirometer_provider.dart';

class DeviceScannerScreen extends ConsumerStatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  ConsumerState<DeviceScannerScreen> createState() =>
      _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends ConsumerState<DeviceScannerScreen> {
  bool _isCheckingPermissions = true;
  bool _hasPermissions = false;
  bool _deviceFound = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    // Revisar nativamente el permiso de Bluetooth
    final status = await Permission.bluetooth.status;
    final serviceStatus = await Permission.bluetooth.serviceStatus;

    if (!mounted) return;

    if (status.isGranted) {
      if (serviceStatus == ServiceStatus.disabled) {
        // Enlazar al paquete oficial para pedir encendido nativo
        try {
          await FlutterBluePlus.turnOn();
          if (mounted) {
            setState(() {
              _isCheckingPermissions = false;
              _hasPermissions = true;
            });
            _startRadarSimulation();
          }
        } catch (e) {
          // Si el usuario da "Deny" en la pantalla nativa de encendido
          if (mounted) context.pop();
        }
      } else {
        setState(() {
          _isCheckingPermissions = false;
          _hasPermissions = true;
        });
        _startRadarSimulation();
      }
    } else {
      setState(() {
        _isCheckingPermissions = false;
        _hasPermissions = false;
      });
      // Mostrar popup elegante de los permisos
      _showPermissionModal();
    }
  }

  void _showPermissionModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bluetooth_searching,
                  color: Colors.blue.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enciende tu radar',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para poder encontrar tu espirómetro físico necesitamos acceso al Bluetooth de tu teléfono. ¿Okey?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    context.pop(); // Cerrar modal

                    print('RADAR: Solicitando permisos nativamente...');
                    // Pedir permiso nativamente
                    Map<Permission, PermissionStatus> statuses = await [
                      Permission.bluetooth,
                      Permission.bluetoothScan,
                      Permission.bluetoothConnect,
                    ].request();

                    print('RADAR: Resultados de permisos: $statuses');

                    // Mapear resultado real para Android 12+ y anteriores
                    bool granted =
                        statuses[Permission.bluetoothScan]?.isGranted == true ||
                        statuses[Permission.bluetooth]?.isGranted == true ||
                        statuses[Permission.bluetoothConnect]?.isGranted ==
                            true;

                    print(
                      'RADAR: Permiso global consolidado concedido? $granted',
                    );

                    if (granted && mounted) {
                      final serviceStatus =
                          await Permission.bluetooth.serviceStatus;
                      if (serviceStatus == ServiceStatus.disabled) {
                        try {
                          await FlutterBluePlus.turnOn();
                          setState(() {
                            _hasPermissions = true;
                          });
                          _startRadarSimulation();
                        } catch (e) {
                          if (mounted)
                            context.pop(); // Usuario rechazó encender BT
                        }
                      } else {
                        setState(() {
                          _hasPermissions = true;
                        });
                        _startRadarSimulation();
                      }
                    } else {
                      print(
                        'RADAR: Permisos denegados nativamente. Regresando al Dashboard.',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Permisos Bluetooth denegados: $statuses',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        context
                            .pop(); // Regresar al Dashboard explicándole al usuario por qué
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF023E8A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sí, Permitir',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.pop(); // Cierra el modal
                  context.pop(); // Regresa al dashboard
                },
                child: Text(
                  'Ahora no',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startRadarSimulation() {
    // Al pasar 4 segundos de radar, simular el hallazgo del espirómetro
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _deviceFound = true;
        });
      }
    });
  }

  Future<void> _linkDevice() async {
    debugPrint('🔍 SCANNER: Iniciando proceso de vinculación...');

    // 2. Ejecutar la vinculación real en el backend vía Provider
    final success = await ref.read(spirometerProvider.notifier).linkDevice();

    debugPrint('🔍 SCANNER: Resultado de vinculación: $success');

    if (!mounted) {
      debugPrint('🔍 SCANNER: El widget ya no está montado.');
      return;
    }

    if (success) {
      debugPrint(
        '🔍 SCANNER: Vinculación exitosa. Mostrando SnackBar y cerrando...',
      );
      // 3. Notificar éxito (Mensaje limpio como pidió el usuario)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Espirómetro Vinculado Exitosamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1, milliseconds: 500),
        ),
      );
      // 4. Regresar de forma natural.
      debugPrint('🔍 SCANNER: Intentando Navigator.pop(context)...');
      Navigator.of(context).pop();
    } else {
      final error = ref.read(spirometerProvider).errorMessage;
      debugPrint('🔍 SCANNER: Error detectado: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al vincular: ${error ?? "Desconocido"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Slate 900 (Tecnológico Oscuro)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: _isCheckingPermissions
            ? const CircularProgressIndicator(color: Colors.blue)
            : !_hasPermissions
            ? const SizedBox.shrink() // El modal está visible
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // RADAR ANIMATION (avatar_glow)
                  if (!_deviceFound)
                    AvatarGlow(
                      glowColor: Colors.blueAccent,
                      duration: const Duration(milliseconds: 2000),
                      repeat: true,
                      child: Material(
                        elevation: 8.0,
                        shape: const CircleBorder(),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade900,
                          radius: 50.0,
                          child: const Icon(
                            Icons.bluetooth,
                            color: Colors.blue,
                            size: 50,
                          ),
                        ),
                      ),
                    )
                  else
                    // DEVICE CARD APPEARS
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        final isLoading = ref
                            .watch(spirometerProvider)
                            .isLoading;
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: _DeviceFoundCard(
                              onTap: isLoading ? () {} : _linkDevice,
                              isLoading: isLoading,
                            ),
                          ),
                        );
                      },
                    ),

                  const Spacer(),

                  Text(
                    _deviceFound
                        ? '1 dispositivo cercano encontrado'
                        : 'Buscando dispositivos cerca de ti...',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 16,
                      color: Colors.blueGrey.shade300,
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
      ),
    );
  }
}

class _DeviceFoundCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _DeviceFoundCard({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blueAccent.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.air, color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'Vinculando...' : 'Espirómetro Inteligente PRO',
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading
                        ? 'Guardando configuración...'
                        : 'Bluetooth LE - Listo para vincular',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 13,
                      color: Colors.blueGrey.shade200,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
