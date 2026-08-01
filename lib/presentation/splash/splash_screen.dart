import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    print(" SPLASH SCREEN STARTED");
    initializeDateFormatting('es_ES', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopwatch.stop();
      print(" SPLASH LOAD TIME: ${_stopwatch.elapsedMilliseconds} ms ");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/fondo.svg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: const Text(
              'AsmaApp',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF023E8A),
                letterSpacing: -1,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: LoadingAnimationWidget.progressiveDots(
                color: const Color(0xFF023E8A),
                size: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
