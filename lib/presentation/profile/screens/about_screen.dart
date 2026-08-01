import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Acerca de',
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF023E8A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'AsthmaApp',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Center(
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 48),

            _buildInfoTile(
              title: 'Términos y Condiciones',
              icon: Icons.description_outlined,
              onTap: () => context.push('/terms'),
            ),
            _buildInfoTile(
              title: 'Política de Privacidad',
              icon: Icons.privacy_tip_outlined,
              onTap: () => context.push('/privacy'),
            ),
            _buildInfoTile(
              title: 'Licencias de Software',
              icon: Icons.code_outlined,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'AsthmaApp',
                applicationVersion: '1.0.0',
              ),
            ),

            const SizedBox(height: 60),
            const Center(
              child: Text(
                'Desarrollado con  para tu salud pulmonar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            const Center(
              child: Text(
                '© 2026 AsthmaApp Inc.',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF023E8A)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}
