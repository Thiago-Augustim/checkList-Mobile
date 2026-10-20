import 'package:flutter/foundation.dart';
import '../../../../data/repositories/offline_sync_repository.dart';
import '../../../../domain/models/checklist_models.dart';

class AuthViewModel extends ChangeNotifier {
  final OfflineSyncRepository _repository;

  AuthViewModel({required OfflineSyncRepository repository})
      : _repository = repository {
    _sessao = _repository.obterSessaoLocal();
  }

  AuthSessionModel? _sessao;
  AuthSessionModel? get sessao => _sessao;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _erro;
  String? get erro => _erro;

  bool get estaAutenticado => _sessao != null;

  Future<bool> login(String email, String senha) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();

    try {
      _sessao = await _repository.autenticar(email.trim(), senha);
      return true;
    } catch (e) {
      _erro = 'Falha ao autenticar: verifique se o backend Spring Boot está ativo.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Permite entrar em modo de demonstração offline se o motorista estiver na estrada sem servidor local
  void entrarModoOfflineDemo() {
    _sessao = const AuthSessionModel(
      accessToken: 'offline-demo-token',
      refreshToken: 'offline-demo-refresh',
      usuario: UsuarioModel(
        id: '110e8400-e29b-41d4-a716-446655440002',
        nome: 'João Silva (Motorista Rodoviário)',
        email: 'motorista@checklist.com.br',
        perfil: 'MOTORISTA',
      ),
    );
    _erro = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _sessao = null;
    notifyListeners();
  }
}
