import 'package:flutter/material.dart';
import '../../data/services/hive_storage_service.dart';

/// Controlador reativo de Tema (Claro, Escuro e Padrão do Sistema)
/// com persistência no armazenamento local Hive.
class ThemeController extends ChangeNotifier {
  final HiveStorageService _hiveStorage;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeController({required HiveStorageService hiveStorage})
      : _hiveStorage = hiveStorage;

  ThemeMode get themeMode => _themeMode;

  /// Carrega a preferência salva no Hive.
  void init() {
    final salvo = _hiveStorage.obterTema();
    if (salvo == 'light') {
      _themeMode = ThemeMode.light;
    } else if (salvo == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Verifica se a interface está sendo renderizada no modo escuro.
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Altera o modo do tema e persiste no Hive.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _hiveStorage.salvarTema(mode.name);
  }

  /// Alterna diretamente entre Claro e Escuro.
  Future<void> toggleTheme(BuildContext context) async {
    final dark = isDarkMode(context);
    await setThemeMode(dark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Escopo de herança (InheritedWidget) para fornecer o [ThemeController]
/// para qualquer widget da árvore.
class ThemeControllerScope extends InheritedWidget {
  final ThemeController controller;

  const ThemeControllerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'Nenhum ThemeControllerScope encontrado na árvore de widgets.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(covariant ThemeControllerScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Extensão para obter o [ThemeController] facilmente a partir do [BuildContext].
extension ThemeControllerContextExtension on BuildContext {
  ThemeController get themeController => ThemeControllerScope.of(this);
}
