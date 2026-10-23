import 'package:flutter/foundation.dart';
import '../../../../data/repositories/offline_sync_repository.dart';
import '../../../../domain/models/checklist_models.dart';

class DriverHomeViewModel extends ChangeNotifier {
  final OfflineSyncRepository _repository;

  DriverHomeViewModel({required OfflineSyncRepository repository})
      : _repository = repository {
    _catalogo = _repository.obterCatalogoLocalOuPadrao();
    _garantirVeiculoSelecionadoValido();
    _atualizarEstadoDaFila();
  }

  late CatalogoOfflineModel _catalogo;
  CatalogoOfflineModel get catalogo => _catalogo;

  String? _veiculoSelecionadoId;
  String? get veiculoSelecionadoId => _veiculoSelecionadoId;

  VeiculoCatalogoModel? get veiculoSelecionado {
    if (_catalogo.veiculos.isEmpty) return null;
    for (final v in _catalogo.veiculos) {
      if (v.id == _veiculoSelecionadoId) {
        return v;
      }
    }
    return _catalogo.veiculos.first;
  }

  /// Filtra os modelos de checklist ativos exibindo apenas aqueles vinculados ao tipo do veículo selecionado.
  List<ChecklistTemplateModel> get templatesParaVeiculoSelecionado {
    final veiculo = veiculoSelecionado;
    if (veiculo == null) return const [];
    final tipoAlvo = veiculo.tipo.trim().toUpperCase();
    return _catalogo.templates
        .where((t) => t.tipoVeiculo.trim().toUpperCase() == tipoAlvo)
        .toList();
  }

  void selecionarVeiculo(String veiculoId) {
    if (_veiculoSelecionadoId == veiculoId) return;
    _veiculoSelecionadoId = veiculoId;
    notifyListeners();
  }

  void _garantirVeiculoSelecionadoValido() {
    if (_catalogo.veiculos.isEmpty) {
      _veiculoSelecionadoId = null;
      return;
    }
    final existe =
        _catalogo.veiculos.any((v) => v.id == _veiculoSelecionadoId);
    if (!existe) {
      _veiculoSelecionadoId = _catalogo.veiculos.first.id;
    }
  }

  List<ChecklistFilaItemModel> _checklistsNaFila = const [];
  OfflineSyncRepository get repository => _repository;

  List<ChecklistFilaItemModel> get checklistsNaFila => _checklistsNaFila;

  List<ChecklistFilaItemModel> get checklistsEnviados =>
      _repository.listarChecklistsEnviados();

  /// Retorna apenas os checklists enviados do veículo selecionado na tela inicial
  List<ChecklistFilaItemModel> get checklistsEnviadosDoVeiculoSelecionado {
    final veiculo = veiculoSelecionado;
    if (veiculo == null) return checklistsEnviados;
    return checklistsEnviados.where((c) {
      return c.veiculoId == veiculo.id ||
          c.veiculoPlaca.trim().toUpperCase() ==
              veiculo.placa.trim().toUpperCase();
    }).toList();
  }

  List<FotoFilaUploadModel> _fotosNaFila = const [];
  List<FotoFilaUploadModel> get fotosNaFila => _fotosNaFila;

  bool _modoOfflineSimulado = false;
  bool get modoOfflineSimulado => _modoOfflineSimulado;

  bool _sincronizando = false;
  bool get sincronizando => _sincronizando;

  String? _mensagemStatus;
  String? get mensagemStatus => _mensagemStatus;

  int get totalPendenciasNaFila =>
      _checklistsNaFila.length + _fotosNaFila.length;

  void alternarModoOfflineSimulado(bool offline) {
    _modoOfflineSimulado = offline;
    _mensagemStatus = offline
        ? 'Modo Estrada Sem Sinal ativado: todas as vistorias serão gravadas nas Boxes do Hive.'
        : 'Conexão restaurada! Você já pode sincronizar a fila em 2 etapas.';
    notifyListeners();
  }

  void _atualizarEstadoDaFila() {
    _checklistsNaFila = _repository.listarChecklistsPendentes();
    _fotosNaFila = _repository.listarFotosPendentes();
    notifyListeners();
  }

  Future<void> baixarCatalogoAtualizado() async {
    if (_modoOfflineSimulado) {
      _mensagemStatus =
          'Você está em modo Offline. Usando catálogo salvo localmente no Hive.';
      notifyListeners();
      return;
    }

    _sincronizando = true;
    _mensagemStatus = 'Baixando veículos e formulários dinâmicos...';
    notifyListeners();

    try {
      _catalogo = await _repository.sincronizarCatalogoDoServidor();
      _garantirVeiculoSelecionadoValido();
      _mensagemStatus =
          'Catálogo atualizado com sucesso (${_catalogo.veiculos.length} veículos e ${_catalogo.templates.length} formulários).';
    } catch (e) {
      _mensagemStatus =
          'Sem resposta do servidor. Mantendo cache local do Hive.';
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  Future<void> registrarNovaVistoriaOffline({
    required ChecklistFilaItemModel checklist,
    required List<FotoFilaUploadModel> fotosComprimidas,
  }) async {
    await _repository.salvarVistoriaNaFilaOffline(
      checklist: checklist,
      fotosComprimidas: fotosComprimidas,
    );
    _atualizarEstadoDaFila();

    if (!_modoOfflineSimulado) {
      await sincronizarFilaAgora();
    } else {
      _mensagemStatus =
          'Vistoria salva offline no Hive! (${_checklistsNaFila.length} JSONs e ${_fotosNaFila.length} fotos aguardando sinal).';
      notifyListeners();
    }
  }

  Future<void> sincronizarFilaAgora() async {
    if (_modoOfflineSimulado) {
      _mensagemStatus =
          'Desative o Modo Offline (Simulador de Estrada) antes de sincronizar com o Spring Boot.';
      notifyListeners();
      return;
    }

    _sincronizando = true;
    _mensagemStatus =
        'Sincronizando fila em 2 etapas (1º JSONs leves -> 2º Fotos Multipart)...';
    notifyListeners();

    try {
      final resultado = await _repository.processarFilaDeSincronizacao();
      _atualizarEstadoDaFila();
      if (resultado.pendenciasRestantes == 0 && resultado.erro == null) {
        _mensagemStatus =
            'Sincronização concluída! (${resultado.checklistsSincronizados} checklists e ${resultado.fotosSincronizadas} fotos enviadas).';
      } else {
        _mensagemStatus =
            'Sincronização pendente (${resultado.pendenciasRestantes} na fila). Detalhe: ${resultado.erro ?? "Verifique conexão com 10.0.2.2:8080"}';
      }
    } finally {
      _sincronizando = false;
      notifyListeners();
    }
  }

  Future<void> limparFilaLocal() async {
    await _repository.limparFilaSincronizacao();
    _mensagemStatus =
        'Fila local do Hive limpa com sucesso. Pronto para novos testes!';
    _atualizarEstadoDaFila();
  }
}
