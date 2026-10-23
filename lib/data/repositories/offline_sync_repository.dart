import '../../domain/models/checklist_models.dart';
import '../services/api_client.dart';
import '../services/hive_storage_service.dart';

class ResultadoSincronizacao {
  final int checklistsSincronizados;
  final int fotosSincronizadas;
  final int pendenciasRestantes;
  final String? erro;

  const ResultadoSincronizacao({
    required this.checklistsSincronizados,
    required this.fotosSincronizadas,
    required this.pendenciasRestantes,
    this.erro,
  });
}

class OfflineSyncRepository {
  final ApiClient _apiClient;
  final HiveStorageService _hiveStorage;

  OfflineSyncRepository({
    required ApiClient apiClient,
    required HiveStorageService hiveStorage,
  })  : _apiClient = apiClient,
        _hiveStorage = hiveStorage;

  HiveStorageService get hiveStorage => _hiveStorage;

  AuthSessionModel? obterSessaoLocal() => _hiveStorage.obterSessao();

  Future<AuthSessionModel> autenticar(String email, String senha) async {
    final sessao = await _apiClient.login(email, senha);
    await _hiveStorage.salvarSessao(sessao);
    return sessao;
  }

  Future<void> logout() async {
    await _hiveStorage.limparSessao();
  }

  CatalogoOfflineModel obterCatalogoLocalOuPadrao() {
    final cache = _hiveStorage.obterCatalogo();
    if (cache != null) {
      return cache;
    }
    // Catálogo embarcado de contingência caso o motorista abra o app pela 1ª vez sem internet
    return const CatalogoOfflineModel(
      sincronizadoEm: 'Cache Inicial Embarcado',
      veiculos: [
        VeiculoCatalogoModel(
          id: '550e8400-e29b-41d4-a716-446655440001',
          placa: 'ABC1D23',
          modelo: 'Scania R450 6x2',
          tipo: 'CAVALO',
          kmAtual: 145200,
        ),
        VeiculoCatalogoModel(
          id: '550e8400-e29b-41d4-a716-446655440002',
          placa: 'XYZ9F87',
          modelo: 'Volvo FH 540 6x4',
          tipo: 'CAVALO',
          kmAtual: 89300,
        ),
        VeiculoCatalogoModel(
          id: '550e8400-e29b-41d4-a716-446655440003',
          placa: 'QWE4R56',
          modelo: 'Mercedes-Benz Actros 2651',
          tipo: 'TRUCK',
          kmAtual: 210450,
        ),
        VeiculoCatalogoModel(
          id: '550e8400-e29b-41d4-a716-446655440004',
          placa: 'BRA2E19',
          modelo: 'Fiat Strada Endurance 1.3',
          tipo: 'CARRO',
          kmAtual: 34500,
        ),
      ],
      templates: [
        ChecklistTemplateModel(
          id: '770e8400-e29b-41d4-a716-446655440001',
          titulo: 'Vistoria Pré-Viagem (Saída de Pátio)',
          descricao:
              'Inspeção obrigatória de segurança antes do início de qualquer viagem rodoviária.',
          tipoVeiculo: 'CAVALO',
          perguntas: [
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440001',
              enunciado:
                  'Os pneus dianteiros e traseiros estão calibrados e sem cortes ou bolhas?',
              tipoResposta: 'BOOLEANO',
              ordem: 1,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: 'FALSE',
            ),
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440002',
              enunciado:
                  'O sistema de freios e mangueiras de ar estão sem vazamentos?',
              tipoResposta: 'BOOLEANO',
              ordem: 2,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: 'FALSE',
            ),
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440004',
              enunciado:
                  'Avalie o estado geral da lataria e para-choques (1 = Crítico, 5 = Excelente)',
              tipoResposta: 'ESCALA_1_5',
              ordem: 3,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: '2',
            ),
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440005',
              enunciado:
                  'Informe o destino da viagem ou observação adicional do painel:',
              tipoResposta: 'TEXTO',
              ordem: 4,
              obrigatoria: false,
              exigeFotoSeAvaria: false,
            ),
          ],
        ),
        ChecklistTemplateModel(
          id: '770e8400-e29b-41d4-a716-446655440003',
          titulo: 'Vistoria de Carro Leve / Passeio',
          descricao:
              'Inspeção de segurança diária para carros leves da frota.',
          tipoVeiculo: 'CARRO',
          perguntas: [
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440009',
              enunciado:
                  'Pneus, estepe, macaco e chave de roda estão em perfeitas condições?',
              tipoResposta: 'BOOLEANO',
              ordem: 1,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: 'FALSE',
            ),
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440010',
              enunciado:
                  'Nível de óleo do motor e líquido de arrefecimento estão adequados?',
              tipoResposta: 'BOOLEANO',
              ordem: 2,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: 'FALSE',
            ),
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440011',
              enunciado:
                  'Avalie o estado de conservação da pintura, vidros e retrovisores (1 a 5)',
              tipoResposta: 'ESCALA_1_5',
              ordem: 3,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: '2',
            ),
          ],
        ),
        ChecklistTemplateModel(
          id: '770e8400-e29b-41d4-a716-446655440004',
          titulo: 'Vistoria Caminhão Truck (6x2)',
          descricao:
              'Inspeção específica de saída para caminhões rígidos tipo Truck.',
          tipoVeiculo: 'TRUCK',
          perguntas: [
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440012',
              enunciado:
                  'Suspensor do 3º eixo (Truck) e balanças estão funcionando sem folgas?',
              tipoResposta: 'BOOLEANO',
              ordem: 1,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: 'FALSE',
            ),
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440013',
              enunciado:
                  'Carroceria/baú e travas de segurança da carga estão íntegros?',
              tipoResposta: 'BOOLEANO',
              ordem: 2,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: 'FALSE',
            ),
            PerguntaTemplateModel(
              id: '990e8400-e29b-41d4-a716-446655440014',
              enunciado:
                  'Avalie o estado geral dos pneus do eixo duplo traseiro (1 a 5)',
              tipoResposta: 'ESCALA_1_5',
              ordem: 3,
              obrigatoria: true,
              exigeFotoSeAvaria: true,
              valorGatilhoAvaria: '2',
            ),
          ],
        ),
      ],
    );
  }

  /// Faz o downsync de veículos e formulários dinâmicos ativos do Spring Boot para o Hive.
  Future<CatalogoOfflineModel> sincronizarCatalogoDoServidor() async {
    final token = await _obterTokenValido();
    try {
      final catalogo = await _apiClient.baixarCatalogos(token);
      await _hiveStorage.salvarCatalogo(catalogo);
      return catalogo;
    } on ApiUnauthorizedException {
      final novoToken = await _renovarSessaoAutomaticamente();
      final catalogo = await _apiClient.baixarCatalogos(novoToken);
      await _hiveStorage.salvarCatalogo(catalogo);
      return catalogo;
    }
  }

  /// Salva o checklist preenchido na estrada e suas fotos comprimidas nas filas locais do Hive.
  Future<void> salvarVistoriaNaFilaOffline({
    required ChecklistFilaItemModel checklist,
    required List<FotoFilaUploadModel> fotosComprimidas,
  }) async {
    await _hiveStorage.enfileirarChecklist(checklist);
    for (final foto in fotosComprimidas) {
      await _hiveStorage.enfileirarFoto(foto);
    }
  }

  List<ChecklistFilaItemModel> listarChecklistsPendentes() =>
      _hiveStorage.listarChecklistsNaFila();

  List<ChecklistFilaItemModel> listarChecklistsEnviados() =>
      _hiveStorage.listarChecklistsEnviados();

  Future<void> salvarChecklistEnviado(ChecklistFilaItemModel item) =>
      _hiveStorage.salvarChecklistEnviado(item);

  List<FotoFilaUploadModel> listarFotosPendentes() =>
      _hiveStorage.listarFotosNaFila();

  /// Limpa todas as pendências das caixas do Hive para permitir reiniciar testes do zero
  Future<void> limparFilaSincronizacao() async {
    await _hiveStorage.limparFilasDeSincronizacao();
  }

  /// Drena a fila offline em 2 etapas:
  /// 1) Envia todos os JSONs leves (Etapa 1) garantindo visibilidade imediata no servidor.
  /// 2) Envia cada foto comprimida individualmente (Etapa 2).
  Future<ResultadoSincronizacao> processarFilaDeSincronizacao() async {
    int checklistsEnviados = 0;
    int fotosEnviadas = 0;
    String? ultimoErro;

    try {
      String token = await _obterTokenValido();

      // ETAPA 1: Sincronizar JSONs leves de Checklists
      final checklistsNaFila = _hiveStorage.listarChecklistsNaFila();
      for (final item in checklistsNaFila) {
        try {
          await _apiClient.enviarChecklistEtapa1(token, item);
          await _hiveStorage.salvarChecklistEnviado(item);
          await _hiveStorage.removerChecklistDaFila(item.id);
          checklistsEnviados++;
        } on ApiUnauthorizedException {
          token = await _renovarSessaoAutomaticamente();
          await _apiClient.enviarChecklistEtapa1(token, item);
          await _hiveStorage.salvarChecklistEnviado(item);
          await _hiveStorage.removerChecklistDaFila(item.id);
          checklistsEnviados++;
        } catch (e) {
          ultimoErro = e.toString();
        }
      }

      // ETAPA 2: Upload individual das Fotos de Avarias cujos checklists já subiram na Etapa 1
      final idsAindaPendentesEtapa1 = _hiveStorage
          .listarChecklistsNaFila()
          .map((c) => c.id)
          .toSet();

      final fotosNaFila = _hiveStorage.listarFotosNaFila();
      for (final foto in fotosNaFila) {
        if (idsAindaPendentesEtapa1.contains(foto.checklistId)) {
          // Aguarda a Etapa 1 do checklist correspondente concluir primeiro
          continue;
        }
        try {
          await _apiClient.enviarFotoEtapa2(
            token,
            foto.id,
            foto.bytesComprimidos,
          );
          await _hiveStorage.removerFotoDaFila(foto.id);
          fotosEnviadas++;
        } catch (e) {
          ultimoErro = e.toString();
        }
      }
    } catch (e) {
      ultimoErro = e.toString();
    }

    final restantes = _hiveStorage.listarChecklistsNaFila().length +
        _hiveStorage.listarFotosNaFila().length;

    return ResultadoSincronizacao(
      checklistsSincronizados: checklistsEnviados,
      fotosSincronizadas: fotosEnviadas,
      pendenciasRestantes: restantes,
      erro: ultimoErro,
    );
  }

  Future<String> _obterTokenValido() async {
    final sessao = _hiveStorage.obterSessao();
    if (sessao == null || sessao.accessToken == 'offline-demo-token') {
      // Se o motorista entrou em modo offline demo antes de ter rede, autentica automaticamente ao sincronizar
      final novaSessao = await autenticar(
        'motorista',
        'senha123',
      );
      return novaSessao.accessToken;
    }
    return sessao.accessToken;
  }

  Future<String> _renovarSessaoAutomaticamente() async {
    final sessaoAtual = _hiveStorage.obterSessao();
    if (sessaoAtual == null ||
        sessaoAtual.refreshToken == 'offline-demo-refresh') {
      final novaSessao = await autenticar(
        'motorista',
        'senha123',
      );
      return novaSessao.accessToken;
    }
    try {
      final novaSessao =
          await _apiClient.renovarToken(sessaoAtual.refreshToken);
      await _hiveStorage.salvarSessao(novaSessao);
      return novaSessao.accessToken;
    } catch (_) {
      final novaSessao = await autenticar(
        'motorista',
        'senha123',
      );
      return novaSessao.accessToken;
    }
  }
}
