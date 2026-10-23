import 'package:flutter/material.dart';
import '../../../../data/services/camera_compression_service.dart';
import '../../../theme/app_colors.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../checklist/view_models/driver_home_view_model.dart';
import '../../checklist/views/driver_home_view.dart';
import 'checklists_placeholder_view.dart';
import 'perfil_placeholder_view.dart';

/// Tela principal com barra de navegação inferior (BottomNavigationBar / NavigationBar).
///
/// Gerencia a transição entre as abas:
/// - 0: Home (DriverHomeView mantida intacta)
/// - 1: Checklists (ChecklistsPlaceholderView)
/// - 2: Perfil (PerfilPlaceholderView)
class MainNavigationView extends StatefulWidget {
  final AuthViewModel authViewModel;
  final DriverHomeViewModel homeViewModel;
  final CameraCompressionService cameraService;

  const MainNavigationView({
    super.key,
    required this.authViewModel,
    required this.homeViewModel,
    required this.cameraService,
  });

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.sidebarBg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Aba 0: Home (Mantida exatamente como está)
          DriverHomeView(
            authViewModel: widget.authViewModel,
            homeViewModel: widget.homeViewModel,
            cameraService: widget.cameraService,
          ),

          // Aba 1: Checklists (Placeholder pronto para desenvolvimento posterior)
          ChecklistsPlaceholderView(
            homeViewModel: widget.homeViewModel,
          ),

          // Aba 2: Perfil (Placeholder pronto para desenvolvimento posterior)
          PerfilPlaceholderView(
            authViewModel: widget.authViewModel,
            homeViewModel: widget.homeViewModel,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: colors.primaryBg,
          elevation: 0,
          height: 65,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: colors.sidebarTextMuted),
              selectedIcon: Icon(Icons.home, color: colors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined, color: colors.sidebarTextMuted),
              selectedIcon: Icon(Icons.fact_check, color: colors.primary),
              label: 'Checklists',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: colors.sidebarTextMuted),
              selectedIcon: Icon(Icons.person, color: colors.primary),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
