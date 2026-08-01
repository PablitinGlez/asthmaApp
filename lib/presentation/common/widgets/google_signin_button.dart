import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_notifier.dart';

import 'package:flutter_svg/flutter_svg.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return OutlinedButton(
      onPressed: authState.isLoading
          ? null
          : () async {
              final sw = Stopwatch()..start();
              print(' INICIANDO GOOGLE SIGN-IN...');
              await ref.read(authNotifierProvider.notifier).signInWithGoogle();
              sw.stop();
              print(
                ' TIEMPO TOTAL GOOGLE SIGN-IN: ${sw.elapsedMilliseconds}ms',
              );
            },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/images/google.svg', width: 24, height: 24),
          const SizedBox(width: 12),
          const Text(
            'Continuar con Google',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
