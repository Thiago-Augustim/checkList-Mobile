import 'package:flutter/material.dart';
import 'data/repositories/offline_sync_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/camera_compression_service.dart';
import 'data/services/hive_storage_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/login_view.dart';
import 'ui/features/checklist/view_models/driver_home_view_model.dart';
import 'ui/features/checklist/views/driver_home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveStorage = HiveStorageService();
  await hiveStorage.init();

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
    ),
  );
}

class CheckListMobileApp extends StatefulWidget {
  final OfflineSyncRepository repository;
  final CameraCompressionService cameraService;

  const CheckListMobileApp({
    super.key,
    required this.repository,
    required this.cameraService,
  });

  @override
  State<CheckListMobileApp> createState() => _CheckListMobileAppState();
}

class _CheckListMobileAppState extends State<CheckListMobileApp> {
  late final AuthViewModel _authViewModel;
  late final DriverHomeViewModel _homeViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel(repository: widget.repository);
    _homeViewModel = DriverHomeViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    _homeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckList Motorista',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: _authViewModel,
        builder: (context, _) {
          if (!_authViewModel.estaAutenticado) {
            return LoginView(viewModel: _authViewModel);
          }
          return DriverHomeView(
            authViewModel: _authViewModel,
            homeViewModel: _homeViewModel,
            cameraService: widget.cameraService,
          );
        },
      ),
    );
  }
}
