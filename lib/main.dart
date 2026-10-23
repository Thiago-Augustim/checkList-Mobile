import 'package:flutter/material.dart';
import 'data/repositories/offline_sync_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/camera_compression_service.dart';
import 'data/services/hive_storage_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/login_view.dart';
import 'ui/features/checklist/view_models/driver_home_view_model.dart';
import 'ui/features/navigation/views/main_navigation_view.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveStorage = HiveStorageService();
  await hiveStorage.init();

  final themeController = ThemeController(hiveStorage: hiveStorage)..init();

  final apiClient = ApiClient();
  final repository = OfflineSyncRepository(
    apiClient: apiClient,
    hiveStorage: hiveStorage,
  );
  final cameraService = CameraCompressionService();

  runApp(
    CheckListMobileApp(
      repository: repository,
      cameraService: cameraService,
      themeController: themeController,
    ),
  );
}

class CheckListMobileApp extends StatefulWidget {
  final OfflineSyncRepository repository;
  final CameraCompressionService cameraService;
  final ThemeController? themeController;

  const CheckListMobileApp({
    super.key,
    required this.repository,
    required this.cameraService,
    this.themeController,
  });

  @override
  State<CheckListMobileApp> createState() => _CheckListMobileAppState();
}

class _CheckListMobileAppState extends State<CheckListMobileApp> {
  late final AuthViewModel _authViewModel;
  late final DriverHomeViewModel _homeViewModel;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = widget.themeController ??
        (ThemeController(hiveStorage: widget.repository.hiveStorage)..init());
    _authViewModel = AuthViewModel(repository: widget.repository);
    _homeViewModel = DriverHomeViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _homeViewModel.dispose();
    if (widget.themeController == null) {
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'CheckList Motorista',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeController.themeMode,
            home: ListenableBuilder(
              listenable: _authViewModel,
              builder: (context, _) {
                if (!_authViewModel.estaAutenticado) {
                  return LoginView(viewModel: _authViewModel);
                }
                return MainNavigationView(
                  authViewModel: _authViewModel,
                  homeViewModel: _homeViewModel,
                  cameraService: widget.cameraService,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
