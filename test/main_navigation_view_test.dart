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
      expect(find.text('Histórico de Checklists'), findsOneWidget);
      expect(find.text('5 por página'), findsOneWidget);
      expect(find.text('Imutável'), findsWidgets);
      expect(find.text('Anterior'), findsOneWidget);
      expect(find.text('Próxima'), findsOneWidget);

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

  testWidgets(
    'Aba Checklists deve paginar o histórico em 5 itens por página e exibir detalhes imutáveis com data e hora',
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

      // Navega para aba Checklists
      await tester.tap(find.text('Checklists'));
      await tester.pumpAndSettle();

      // Verifica exibição da página 1 do caminhão selecionado (ABC1D23 com 6 itens)
      expect(find.text('Exibindo 1–5 de 6 vistorias'), findsOneWidget);
      expect(find.text('5 por página'), findsOneWidget);
      expect(find.textContaining('ABC1D23'), findsWidgets);

      // Clica em 'Próxima' para navegar para a página 2
      await tester.tap(find.text('Próxima'));
      await tester.pumpAndSettle();

      // Verifica exibição da página 2 (6–6 de 6)
      expect(find.text('Exibindo 6–6 de 6 vistorias'), findsOneWidget);

      // Volta para a página 1
      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Exibindo 1–5 de 6 vistorias'), findsOneWidget);

      // Abre o modal de detalhes somente leitura do primeiro item
      final botaoVisualizar =
          find.text('Visualizar Vistoria (Somente Leitura)').first;
      await tester.tap(botaoVisualizar);
      await tester.pumpAndSettle();

      // Verifica aviso explícito de imutabilidade e data/hora no modal
      expect(
        find.text(
          'Registro finalizado e sincronizado. Os dados, data e respostas não podem ser alterados.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Data e Horário Realizado:'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Switch), findsNothing);

      // Fecha modal
      await tester.tap(find.text('Fechar Visualização'));
      await tester.pumpAndSettle();
      expect(find.text('Histórico de Checklists'), findsOneWidget);

      // Alterna o veículo na Home e verifica que a aba Checklists reflete apenas o novo veículo
      homeViewModel.selecionarVeiculo('550e8400-e29b-41d4-a716-446655440002'); // XYZ9F87
      await tester.pumpAndSettle();
      expect(find.textContaining('XYZ9F87'), findsWidgets);
      expect(find.text('Exibindo 1–2 de 2 vistorias'), findsOneWidget);
    },
  );
}

