import 'dart:convert';
import 'dart:io';
import 'package:checklist_mobile/data/repositories/offline_sync_repository.dart';
import 'package:checklist_mobile/data/services/api_client.dart';
import 'package:checklist_mobile/data/services/camera_compression_service.dart';
import 'package:checklist_mobile/data/services/hive_storage_service.dart';
import 'package:checklist_mobile/domain/models/checklist_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory tempHiveDir;
  late HiveStorageService hiveStorage;

  setUp(() async {
    tempHiveDir = await Directory.systemTemp.createTemp('checklist_hive_test_');
    hiveStorage = HiveStorageService();
    await hiveStorage.init(customSubDir: tempHiveDir.path);
  });

  tearDown(() async {
    try {
      if (await tempHiveDir.exists()) {
        await tempHiveDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test(
    'PerguntaTemplateModel deve detectar avaria corretamente para BOOLEANO e ESCALA_1_5',
    () {
      const perguntaBooleana = PerguntaTemplateModel(
        id: 'p-1',
        enunciado: 'Pneus calibrados?',
        tipoResposta: 'BOOLEANO',
        ordem: 1,
        obrigatoria: true,
        exigeFotoSeAvaria: true,
        valorGatilhoAvaria: 'FALSE',
      );
      expect(perguntaBooleana.respostaDisparaAvaria('TRUE'), isFalse);
      expect(perguntaBooleana.respostaDisparaAvaria('FALSE'), isTrue);

      const perguntaEscala = PerguntaTemplateModel(
        id: 'p-2',
        enunciado: 'Estado da cabine (1 a 5)',
        tipoResposta: 'ESCALA_1_5',
        ordem: 2,
        obrigatoria: true,
        exigeFotoSeAvaria: true,
        valorGatilhoAvaria: '2',
      );
      expect(perguntaEscala.respostaDisparaAvaria('5'), isFalse);
      expect(perguntaEscala.respostaDisparaAvaria('3'), isFalse);
      expect(perguntaEscala.respostaDisparaAvaria('2'), isTrue);
      expect(perguntaEscala.respostaDisparaAvaria('1'), isTrue);
    },
  );

  test(
    'Fila Offline-First no Hive deve sincronizar em 2 etapas e tolerar queda de rede antes do upload da foto',
    () async {
      bool simularFalhaNoUploadFoto = true;
      int chamadasEtapa1 = 0;
      int chamadasEtapa2 = 0;

      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/sync/checklists')) {
          chamadasEtapa1++;
          return http.Response(
            jsonEncode({
              'checklistId': 'chk-uuid-1',
              'statusSincronizacao': 'AGUARDANDO_FOTOS',
              'alertaInconsistencia': false,
              'fotosPendentesIds': ['foto-uuid-1'],
            }),
            200,
          );
        }

        if (request.url.path.contains('/sync/fotos/')) {
          chamadasEtapa2++;
          if (simularFalhaNoUploadFoto) {
            return http.Response('Queda de sinal 3G na rodovia', 503);
          }
          return http.Response(
            jsonEncode({
              'fotoId': 'foto-uuid-1',
              'checklistId': 'chk-uuid-1',
              'statusUpload': 'CONCLUIDO',
              'statusChecklist': 'CONCLUIDO',
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      final repository = OfflineSyncRepository(
        apiClient: apiClient,
        hiveStorage: hiveStorage,
      );

      await hiveStorage.salvarSessao(
        const AuthSessionModel(
          accessToken: 'jwt-valido',
          refreshToken: 'refresh-valido',
          usuario: UsuarioModel(
            id: 'mot-1',
            nome: 'João Motorista',
            email: 'motorista@checklist.com.br',
            perfil: 'MOTORISTA',
          ),
        ),
      );

      final cameraService = CameraCompressionService();
      final bytesComprimidos = cameraService.gerarFotoEvidenciaSimuladaCamera();

      const checklistOffline = ChecklistFilaItemModel(
        id: 'chk-uuid-1',
        templateId: 'tpl-1',
        templateTitulo: 'Vistoria Pré-Viagem',
        veiculoId: 'veic-1',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 146500,
        realizadoEm: '2026-10-17T10:00:00Z',
        respostas: [
          RespostaFilaItemModel(
            id: 'resp-1',
            perguntaId: 'perg-1',
            valorResposta: 'FALSE',
            observacaoAvaria: 'Corte no pneu',
            avariaDetectada: true,
            fotosEsperadas: [
              FotoEsperadaMetaModel(
                id: 'foto-uuid-1',
                capturadaEm: '2026-10-17T10:00:00Z',
              ),
            ],
          ),
        ],
      );

      final fotoOffline = FotoFilaUploadModel(
        id: 'foto-uuid-1',
        checklistId: 'chk-uuid-1',
        respostaId: 'resp-1',
        capturadaEm: '2026-10-17T10:00:00Z',
        bytesJpegBase64: base64Encode(bytesComprimidos),
      );

      // 1. Motorista salva vistoria sem internet -> entra nas 2 filas do Hive
      await repository.salvarVistoriaNaFilaOffline(
        checklist: checklistOffline,
        fotosComprimidas: [fotoOffline],
      );
      expect(repository.listarChecklistsPendentes(), hasLength(1));
      expect(repository.listarFotosPendentes(), hasLength(1));

      // 2. Primeira tentativa de sync em 3G instável: Etapa 1 (JSON leve) sobe, Etapa 2 (Foto) falha
      final tentativa1 = await repository.processarFilaDeSincronizacao();
      expect(tentativa1.checklistsSincronizados, 1);
      expect(tentativa1.fotosSincronizadas, 0);
      expect(tentativa1.pendenciasRestantes, 1);
      expect(repository.listarChecklistsPendentes(), isEmpty);
      expect(repository.listarFotosPendentes(), hasLength(1));

      // 3. Sinal estabiliza: segunda tentativa envia apenas a foto restante (Etapa 2) sem reenviar o JSON!
      simularFalhaNoUploadFoto = false;
      final tentativa2 = await repository.processarFilaDeSincronizacao();
      expect(tentativa2.checklistsSincronizados, 0);
      expect(tentativa2.fotosSincronizadas, 1);
      expect(tentativa2.pendenciasRestantes, 0);
      expect(chamadasEtapa1, 1);
      expect(chamadasEtapa2, 2);
      expect(repository.listarFotosPendentes(), isEmpty);
    },
  );

  test(
    'limparFilaSincronizacao deve esvaziar as caixas de checklists e fotos do Hive',
    () async {
      final repository = OfflineSyncRepository(
        apiClient: ApiClient(),
        hiveStorage: hiveStorage,
      );

      const checklist = ChecklistFilaItemModel(
        id: 'chk-limpar-1',
        templateId: 'tpl-1',
        templateTitulo: 'Vistoria Teste',
        veiculoId: 'v-1',
        veiculoPlaca: 'ABC1D23',
        kmVistoria: 1000,
        realizadoEm: '2026-10-19T20:00:00Z',
        respostas: [],
      );

      const foto = FotoFilaUploadModel(
        id: 'foto-limpar-1',
        checklistId: 'chk-limpar-1',
        respostaId: 'resp-1',
        capturadaEm: '2026-10-19T20:00:00Z',
        bytesJpegBase64: 'dGVzdGU=',
      );

      await repository.salvarVistoriaNaFilaOffline(
        checklist: checklist,
        fotosComprimidas: [foto],
      );

      expect(repository.listarChecklistsPendentes(), hasLength(1));
      expect(repository.listarFotosPendentes(), hasLength(1));

      await repository.limparFilaSincronizacao();

      expect(repository.listarChecklistsPendentes(), isEmpty);
      expect(repository.listarFotosPendentes(), isEmpty);
    },
  );
}
