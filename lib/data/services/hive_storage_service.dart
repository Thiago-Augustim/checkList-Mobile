import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/checklist_models.dart';

class HiveStorageService {
  static const String authBoxName = 'auth_box';
  static const String catalogBoxName = 'catalog_box';
  static const String syncChecklistsBoxName = 'sync_checklists_box';
  static const String syncPhotosBoxName = 'sync_photos_box';
  static const String settingsBoxName = 'settings_box';
  static const String sentChecklistsBoxName = 'sent_checklists_box';

  late final Box<String> _authBox;
  late final Box<String> _catalogBox;
  late final Box<String> _syncChecklistsBox;
  late final Box<String> _syncPhotosBox;
  late final Box<String> _settingsBox;
  late final Box<String> _sentChecklistsBox;

  Future<void> init({String? customSubDir}) async {
    if (customSubDir != null) {
      Hive.init(customSubDir);
    } else {
      await Hive.initFlutter();
    }
    _authBox = await Hive.openBox<String>(authBoxName);
    _catalogBox = await Hive.openBox<String>(catalogBoxName);
    _syncChecklistsBox = await Hive.openBox<String>(syncChecklistsBoxName);
    _syncPhotosBox = await Hive.openBox<String>(syncPhotosBoxName);
    _settingsBox = await Hive.openBox<String>(settingsBoxName);
    _sentChecklistsBox = await Hive.openBox<String>(sentChecklistsBoxName);

    if (_sentChecklistsBox.isEmpty) {
      await _semearHistoricoInicial();
    }
  }

  // ===========================================================================
  // Autenticação Local (JWT + Refresh Token)
  // ===========================================================================
  Future<void> salvarSessao(AuthSessionModel session) async {
    await _authBox.put('session', jsonEncode(session.toJson()));
  }

  AuthSessionModel? obterSessao() {
    final raw = _authBox.get('session');
    if (raw == null) return null;
    return AuthSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> limparSessao() async {
    await _authBox.delete('session');
  }

  // ===========================================================================
  // Cache do Catálogo Offline (Veículos + Templates Dinâmicos)
  // ===========================================================================
  Future<void> salvarCatalogo(CatalogoOfflineModel catalogo) async {
    await _catalogBox.put('catalogo', jsonEncode(catalogo.toJson()));
  }

  CatalogoOfflineModel? obterCatalogo() {
    final raw = _catalogBox.get('catalogo');
    if (raw == null) return null;
    return CatalogoOfflineModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  // ===========================================================================
  // Fila Offline Etapa 1: Checklists JSON Leves
  // ===========================================================================
  Future<void> enfileirarChecklist(ChecklistFilaItemModel item) async {
    await _syncChecklistsBox.put(
      item.id,
      jsonEncode(item.toStorageJson()),
    );
  }

  List<ChecklistFilaItemModel> listarChecklistsNaFila() {
    return _syncChecklistsBox.values
        .map(
          (raw) => ChecklistFilaItemModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> removerChecklistDaFila(String checklistId) async {
    await _syncChecklistsBox.delete(checklistId);
  }

  // ===========================================================================
  // Fila Offline Etapa 2: Fotos de Avarias Comprimidas
  // ===========================================================================
  Future<void> enfileirarFoto(FotoFilaUploadModel foto) async {
    await _syncPhotosBox.put(foto.id, jsonEncode(foto.toJson()));
  }

  List<FotoFilaUploadModel> listarFotosNaFila() {
    return _syncPhotosBox.values
        .map(
          (raw) => FotoFilaUploadModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> removerFotoDaFila(String fotoId) async {
    await _syncPhotosBox.delete(fotoId);
  }

  // ===========================================================================
  // Limpeza de Filas para Reset de Testes / Descarte de Itens Inválidos
  // ===========================================================================
  Future<void> limparFilasDeSincronizacao() async {
    await _syncChecklistsBox.clear();
    await _syncPhotosBox.clear();
  }

  // ===========================================================================
  // Histórico de Checklists Enviados (Imutáveis / Somente Leitura)
  // ===========================================================================
  Future<void> salvarChecklistEnviado(ChecklistFilaItemModel item) async {
    await _sentChecklistsBox.put(item.id, jsonEncode(item.toStorageJson()));
  }

  List<ChecklistFilaItemModel> listarChecklistsEnviados() {
    final list = _sentChecklistsBox.values
        .map(
          (raw) => ChecklistFilaItemModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        )
        .toList();
    list.sort((a, b) => b.realizadoEm.compareTo(a.realizadoEm));
    return list;
  }

  Future<void> _semearHistoricoInicial() async {
    final agora = DateTime.now();
    final seeds = [
      ChecklistFilaItemModel(
        id: 'hist-1',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440001',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 145250,
        observacoesGerais: 'Veículo liberado para viagem com tanque cheio.',
        realizadoEm: agora
            .subtract(const Duration(hours: 2, minutes: 15))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-1-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
          RespostaFilaItemModel(
            id: 'r-1-2',
            perguntaId: '990e8400-e29b-41d4-a716-446655440002',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
          RespostaFilaItemModel(
            id: 'r-1-3',
            perguntaId: '990e8400-e29b-41d4-a716-446655440004',
            valorResposta: '5',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-2',
        templateId: '770e8400-e29b-41d4-a716-446655440003',
        templateTitulo: 'Vistoria de Carro Leve / Passeio',
        veiculoId: '550e8400-e29b-41d4-a716-446655440004',
        veiculoPlaca: 'BRA2E19',
        kmVistoria: 34520,
        observacoesGerais: 'Inspeção de rotina sem problemas.',
        realizadoEm: agora
            .subtract(const Duration(hours: 6, minutes: 40))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-2-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440009',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-3',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440002',
        veiculoPlaca: 'XYZ9F87',
        kmVistoria: 89310,
        observacoesGerais: 'Pequeno corte no pneu traseiro observado.',
        realizadoEm: agora
            .subtract(const Duration(days: 1, hours: 3))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-3-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'FALSE',
            observacaoAvaria:
                'Pneu traseiro direito com pequeno desgaste na banda lateral.',
            avariaDetectada: true,
            fotosEsperadas: [],
          ),
          RespostaFilaItemModel(
            id: 'r-3-2',
            perguntaId: '990e8400-e29b-41d4-a716-446655440002',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-4',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440003',
        veiculoPlaca: 'QWE4R56',
        kmVistoria: 210460,
        observacoesGerais: 'Carga conferida e amarrada.',
        realizadoEm: agora
            .subtract(const Duration(days: 1, hours: 10))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-4-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-5',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440001',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 144980,
        observacoesGerais: 'Checklist matinal OK.',
        realizadoEm: agora
            .subtract(const Duration(days: 2, hours: 5))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-5-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-6',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440002',
        veiculoPlaca: 'XYZ9F87',
        kmVistoria: 89120,
        observacoesGerais: 'Retorno de rota sem ocorrências.',
        realizadoEm: agora
            .subtract(const Duration(days: 3, hours: 4))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-6-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-7',
        templateId: '770e8400-e29b-41d4-a716-446655440003',
        templateTitulo: 'Vistoria de Carro Leve / Passeio',
        veiculoId: '550e8400-e29b-41d4-a716-446655440004',
        veiculoPlaca: 'BRA2E19',
        kmVistoria: 34100,
        observacoesGerais: 'Vistoria semanal da frota leve.',
        realizadoEm: agora
            .subtract(const Duration(days: 4, hours: 2))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-7-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440009',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-8',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440001',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 144500,
        observacoesGerais: 'Checagem de lâmpadas e fluidos.',
        realizadoEm: agora
            .subtract(const Duration(days: 5, hours: 3))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-8-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-9',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440001',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 144100,
        observacoesGerais: 'Revisão pós-manutenção periódica.',
        realizadoEm: agora
            .subtract(const Duration(days: 6, hours: 1))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-9-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-10',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440001',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 143800,
        observacoesGerais: 'Viagem interestadual concluída.',
        realizadoEm: agora
            .subtract(const Duration(days: 7, hours: 4))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-10-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
      ChecklistFilaItemModel(
        id: 'hist-11',
        templateId: '770e8400-e29b-41d4-a716-446655440001',
        templateTitulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
        veiculoId: '550e8400-e29b-41d4-a716-446655440001',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 143200,
        observacoesGerais: 'Inspeção de saída padrão.',
        realizadoEm: agora
            .subtract(const Duration(days: 8, hours: 2))
            .toIso8601String(),
        etapa1Concluida: true,
        respostas: const [
          RespostaFilaItemModel(
            id: 'r-11-1',
            perguntaId: '990e8400-e29b-41d4-a716-446655440001',
            valorResposta: 'TRUE',
            avariaDetectada: false,
            fotosEsperadas: [],
          ),
        ],
      ),
    ];

    for (final item in seeds) {
      await _sentChecklistsBox.put(item.id, jsonEncode(item.toStorageJson()));
    }
  }

  // ===========================================================================
  // Preferências do Aplicativo (Tema Claro / Escuro / Sistema)
  // ===========================================================================
  Future<void> salvarTema(String tema) async {
    await _settingsBox.put('tema', tema);
  }

  String? obterTema() {
    return _settingsBox.get('tema');
  }
}

