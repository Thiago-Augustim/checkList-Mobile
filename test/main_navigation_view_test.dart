import 'dart:io';
import 'package:checklist_mobile/data/repositories/offline_sync_repository.dart';
import 'package:checklist_mobile/data/services/api_client.dart';
import 'package:checklist_mobile/data/services/camera_compression_service.dart';
import 'package:checklist_mobile/data/services/hive_storage_service.dart';
import 'package:checklist_mobile/ui/features/auth/view_models/auth_view_model.dart';
import 'package:checklist_mobile/ui/features/checklist/view_models/driver_home_view_model.dart';
import 'package:checklist_mobile/ui/features/navigation/views/main_navigation_view.dart';
import 'package:checklist_mobile/ui/theme/app_theme.dart';
import 'package:checklist_mobile/ui/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempHiveDir;
  late HiveStorageService hiveStorage;
  late OfflineSyncRepository repository;
  late AuthViewModel authViewModel;
  late DriverHomeViewModel homeViewModel;
  late CameraCompressionService cameraService;
  late ThemeController themeController;

  setUp(() async {
    tempHiveDir = await Directory.systemTemp.createTemp('checklist_nav_test_');
    hiveStorage = HiveStorageService();
    await hiveStorage.init(customSubDir: tempHiveDir.path);
    repository = OfflineSyncRepository(
      apiClient: ApiClient(),
      hiveStorage: hiveStorage,
    );
    authViewModel = AuthViewModel(repository: repository);
    authViewModel.entrarModoOfflineDemo();
    homeViewModel = DriverHomeViewModel(repository: repository);
    cameraService = CameraCompressionService();
    themeController = ThemeController(hiveStorage: hiveStorage)..init();
  });

  tearDown(() async {
    authViewModel.dispose();
    homeViewModel.dispose();
    themeController.dispose();
    try {
      if (await tempHiveDir.exists()) {
        await tempHiveDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets(
    'MainNavigationView deve renderizar a barra de navegação e alternar entre Home, Checklists e Perfil',
    (tester) async {
      await tester.pumpWidget(
        ThemeControllerScope(
          controller: themeController,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MainNavigationView(
              authViewModel: authViewModel,
              homeViewModel: homeViewModel,
              cameraService: cameraService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica presença da barra de navegação
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Checklists'), findsWidgets);
      expect(find.text('Perfil'), findsWidgets);

      // Na Home (Aba 0)
      expect(find.text('CheckList Motorista'), findsOneWidget);

      // Clica na aba Checklists (Aba 1)
      await tester.tap(find.text('Checklists'));
      await tester.pumpAndSettle();
      expect(find.text('Central de Checklists'), findsOneWidget);

      // Clica na aba Perfil (Aba 2)
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Minha Conta e Configurações'), findsOneWidget);

      // Volta para a aba Home (Aba 0)
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('CheckList Motorista'), findsOneWidget);
    },
  );
}
