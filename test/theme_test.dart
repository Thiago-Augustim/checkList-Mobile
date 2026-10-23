import 'dart:io';
import 'package:checklist_mobile/data/services/hive_storage_service.dart';
import 'package:checklist_mobile/ui/theme/app_colors.dart';
import 'package:checklist_mobile/ui/theme/app_theme.dart';
import 'package:checklist_mobile/ui/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Paleta de Cores e Temas (AppColorsExtension & AppTheme)', () {
    test('Paleta do Tema Claro deve conter exatamente as cores especificadas', () {
      const light = AppColorsExtension.light;
      expect(light.primary, const Color(0xFF4CAF50));
      expect(light.primaryBg, const Color(0xFFE8F5E9));
      expect(light.gridHoverBg, const Color(0xFFF1F8E9));
      expect(light.border, const Color(0xFFE2E8F0));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.sidebarBg, const Color(0xFFF8FAFC));
      expect(light.sidebarTextMuted, const Color(0xFF64748B));
      expect(light.primaryPressed, const Color(0xFF388E3C));
      expect(light.textPrimary, const Color(0xFF0F172A));
      expect(light.textSecondary, const Color(0xFF475569));
      expect(light.cardBg, const Color(0xB3FFFFFF)); // rgba(255, 255, 255, 0.7)
      expect(light.cardBlur, 4.0);
    });

    test('Paleta do Tema Escuro deve conter exatamente as cores especificadas', () {
      const dark = AppColorsExtension.dark;
      expect(dark.primary, const Color(0xFF4CAF50));
      expect(dark.primaryBg, const Color(0xFF0D2010));
      expect(dark.gridHoverBg, const Color(0xFF0D2215));
      expect(dark.border, const Color(0xFF1F2937));
      expect(dark.surface, const Color(0xFF161B27));
      expect(dark.sidebarBg, const Color(0xFF131A24));
      expect(dark.sidebarTextMuted, const Color(0xFF64748B));
      expect(dark.primaryPressed, const Color(0xFF388E3C));
      expect(dark.textPrimary, const Color(0xFFE2E8F0));
      expect(dark.textSecondary, const Color(0xFF94A3B8));
      expect(dark.cardBg, const Color(0x33161B27)); // rgba(22, 27, 39, 0.2)
      expect(dark.cardBlur, 4.0);
    });

    test('AppTheme.lightTheme deve ter brightness light e conter AppColorsExtension.light', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(theme.colorScheme.primary, const Color(0xFF4CAF50));
      final extension = theme.extension<AppColorsExtension>();
      expect(extension, isNotNull);
      expect(extension?.textPrimary, const Color(0xFF0F172A));
    });

    test('AppTheme.darkTheme deve ter brightness dark e conter AppColorsExtension.dark', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF131A24));
      expect(theme.colorScheme.primary, const Color(0xFF4CAF50));
      final extension = theme.extension<AppColorsExtension>();
      expect(extension, isNotNull);
      expect(extension?.textPrimary, const Color(0xFFE2E8F0));
    });
  });

  group('ThemeController e Persistência no Hive', () {
    late Directory tempDir;
    late HiveStorageService hiveStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('checklist_theme_test_');
      hiveStorage = HiveStorageService();
      await hiveStorage.init(customSubDir: tempDir.path);
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('Deve iniciar com ThemeMode.system por padrão quando não houver registro', () {
      final controller = ThemeController(hiveStorage: hiveStorage)..init();
      expect(controller.themeMode, ThemeMode.system);
    });

    test('Deve alternar e persistir ThemeMode.dark e ThemeMode.light no Hive', () async {
      final controller = ThemeController(hiveStorage: hiveStorage)..init();

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(hiveStorage.obterTema(), 'dark');

      final controller2 = ThemeController(hiveStorage: hiveStorage)..init();
      expect(controller2.themeMode, ThemeMode.dark);

      await controller2.setThemeMode(ThemeMode.light);
      expect(controller2.themeMode, ThemeMode.light);
      expect(hiveStorage.obterTema(), 'light');
    });

    testWidgets('Deve alternar tema com toggleTheme respeitando contexto', (tester) async {
      final controller = ThemeController(hiveStorage: hiveStorage)..init();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () => controller.toggleTheme(ctx),
                child: const Text('Alternar'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Alternar'));
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.dark);
      expect(hiveStorage.obterTema(), 'dark');
    });
  });
}
