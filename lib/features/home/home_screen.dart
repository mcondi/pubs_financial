import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const background = Color.fromRGBO(7, 32, 64, 1);
  static const cardBlue = Color.fromRGBO(19, 52, 98, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Duxton Pubs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Pubs Financial',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 18),

                  // Latest Notification card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBlue.withOpacity(0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Notification',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.65,
                    children: [
                      _HomeCard(
                        title: 'Snapshot',
                        icon: Icons.pie_chart,
                        tint: Colors.purple,
                        onTap: () => context.go('/snapshot'),
                      ),
                     _HomeCard(
  title: 'Financial',
  icon: Icons.bar_chart,
  tint: const Color.fromRGBO(92, 188, 125, 1),
  onTap: () => context.go('/financial'),
),

                      _HomeCard(
                        title: 'Trends',
                        icon: Icons.show_chart,
                        tint: const Color.fromRGBO(244, 195, 64, 1),
                        onTap: () => context.go('/trends'),
                      ),
                     _HomeCard(
  title: 'Gaming',
  icon: Icons.casino,
  tint: Colors.orange,
  onTap: () => context.go('/gaming'),
),

                     _HomeCard(title: 'Food', icon: Icons.restaurant, tint: Colors.cyan, onTap: () => context.go('/food')),
_HomeCard(title: 'Beverage', icon: Icons.wine_bar, tint: Colors.cyan, onTap: () => context.go('/beverage')),
_HomeCard(title: 'Retail', icon: Icons.shopping_bag, tint: Colors.cyan, onTap: () => context.go('/retail')),
_HomeCard(title: 'Accommodation', icon: Icons.bed, tint: Colors.cyan, onTap: () => context.go('/accommodation')),

                  _HomeCard(
  title: 'State of Play',
  icon: Icons.speed,
  tint: Colors.purple,
  onTap: () => context.go('/state-of-play'),
),

                      const _HomeCard(
                        title: 'After Action',
                        icon: Icons.checklist,
                        tint: Colors.tealAccent,
                      ),
                      const _HomeCard(
                        title: 'Alerts',
                        icon: Icons.notifications_active,
                        tint: Colors.pink,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Settings cog (still TODO)
            Positioned(
              top: 16,
              right: 20,
              child: Material(
                color: cardBlue.withOpacity(0.95),
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    // TODO: settings screen
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.settings, color: Colors.white.withOpacity(0.9), size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  const _HomeCard({
    required this.title,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tint.withOpacity(0.7), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: tint),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
