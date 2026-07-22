import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardGreeting extends StatelessWidget {
  final GlobalKey helpButtonKey;
  final VoidCallback onHelpTap;
  final String userName;

  const DashboardGreeting({
    super.key,
    required this.helpButtonKey,
    required this.onHelpTap,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $userName! 👋',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF03045E),
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEEE, d MMMM', 'es_ES')
                    .format(DateTime.now())
                    .split(' ')
                    .map((word) {
                      if (word.isEmpty) return word;
                      return word[0].toUpperCase() +
                          word.substring(1).toLowerCase();
                    })
                    .join(' '),
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          key: helpButtonKey,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: const Color(0xFF023E8A).withOpacity(0.8),
              size: 24,
            ),
            onPressed: onHelpTap,
            tooltip: 'Ver tutorial de nuevo',
          ),
        ),
      ],
    );
  }
}
