import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'home_screen.dart';
import 'portfolio_screen.dart';
import '../notifications/notification_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with tabs
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tabs
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _tabController.animateTo(0),
                        child: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            final isSelected = _tabController.index == 0;
                            return Text(
                              'Explore',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => _tabController.animateTo(1),
                        child: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            final isSelected = _tabController.index == 1;
                            return Text(
                              'Portfolio',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // Icons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  HomeScreen(),
                  PortfolioScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
