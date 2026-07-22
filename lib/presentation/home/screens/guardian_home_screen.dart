import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

import '../../auth/providers/auth_provider.dart';
import '../widgets/guardian/guardian_view.dart';
import '../../profile/screens/guardian_profile_screen.dart';

class GuardianHomeScreen extends ConsumerStatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  ConsumerState<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends ConsumerState<GuardianHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    GuardianView(),
    GuardianProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final title = _currentIndex == 0 ? 'Pacientes' : 'Mi Perfil';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              centerTitle: false,
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontFamily: 'Satoshi',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                // Mini Avatar decorativo
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = 1),
                    borderRadius: BorderRadius.circular(18),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(
                        int.parse(
                          'FF${user?.avatarBackground ?? '023e8a'}',
                          radix: 16,
                        ),
                      ),
                      child: ClipOval(
                        child: SvgPicture.network(
                          'https://api.dicebear.com/9.x/initials/svg?seed=${user?.avatarSeed ?? 'Guardián'}&backgroundColor=${user?.avatarBackground ?? '023e8a'}',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF023E8A),
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 0,
        iconSize: 22,
        items: [
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.family_restroom_rounded, false),
            activeIcon: _buildTabIcon(Icons.family_restroom_rounded, true),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: _buildTabIcon(Icons.person_outline, false),
            activeIcon: _buildTabIcon(Icons.person_outline, true),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF023E8A) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon),
      ],
    );
  }
}
