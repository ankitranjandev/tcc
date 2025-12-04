import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../utils/responsive.dart';
import 'sidebar.dart';
import 'topbar.dart';

/// Main Layout with Sidebar and Topbar
class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgSecondary,
      // Drawer for mobile/tablet
      drawer: (isMobile || isTablet)
          ? Drawer(
              child: Sidebar(
                currentRoute: widget.currentRoute,
                onItemTap: () {
                  // Close drawer when item is tapped on mobile
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar (only on desktop)
          if (!isMobile && !isTablet)
            Sidebar(currentRoute: widget.currentRoute),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Topbar
                Topbar(
                  onMenuPressed: (isMobile || isTablet)
                      ? () {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      : null,
                ),

                // Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
