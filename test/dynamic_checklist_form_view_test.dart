import 'package:checklist_mobile/data/services/camera_compression_service.dart';
import 'package:checklist_mobile/domain/models/checklist_models.dart';
import 'package:checklist_mobile/ui/features/checklist/views/dynamic_checklist_form_view.dart';
import 'package:checklist_mobile/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const template = ChecklistTemplateModel(
    id: 'tpl-test',
    titulo: 'Vistoria Passo a Passo',
    descricao: 'Teste de Wizard',
    tipoVeiculo: 'CAVALO',
    perguntas: [
      PerguntaTemplateModel(
        id: 'p-1',
        enunciado: 'Freios funcionando corretamente?',
        tipoResposta: 'BOOLEANO',
        ordem: 1,
        obrigatoria: true,
        exigeFotoSeAvaria: true,
        valorGatilhoAvaria: 'FALSE',
      ),
      PerguntaTemplateModel(
        id: 'p-2',
        enunciado: 'Estado geral da lataria (1 a 5)',
        tipoResposta: 'ESCALA_1_5',
        ordem: 2,
        obrigatoria: true,
        exigeFotoSeAvaria: false,
        valorGatilhoAvaria: '2',
      ),
    ],
  );

  const veiculos = [
    VeiculoCatalogoModel(
      id: 'v-1',
      placa: 'ABC1D23',
      modelo: 'Scania R450',
      tipo: 'CAVALO',
      kmAtual: 100000,
    ),
  ];

  testWidgets(
    'DynamicChecklistFormView deve apresentar uma pergunta por vez com navegação Anterior e Próxima',
    (tester) async {
      ChecklistFilaItemModel? checklistSalvo;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DynamicChecklistFormView(
            template: template,
            veiculos: veiculos,
            cameraService: CameraCompressionService(),
            onSalvarOffline: (checklist, fotos) async {
              checklistSalvo = checklist;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Etapa 0: Veículo e Hodômetro
      expect(find.text('Identificação do Veículo'), findsOneWidget);
      expect(find.text('Hodômetro Atual (KM)'), findsOneWidget);

      // Avança para Pergunta 1
      await tester.tap(find.text('Próxima Pergunta'));
      await tester.pumpAndSettle();

      // Pergunta 1/2
      expect(find.text('Pergunta 1 de 2'), findsWidgets);
      expect(find.text('Freios funcionando corretamente?'), findsOneWidget);
      expect(find.text('SIM (Conforme / Tudo Certo)'), findsOneWidget);
      expect(find.text('NÃO (Com Avaria / Não Conforme)'), findsOneWidget);

      // Clica em 'Próxima Pergunta' -> Avança para Pergunta 2
      await tester.tap(find.text('Próxima Pergunta'));
      await tester.pumpAndSettle();

      // Pergunta 2/2
      expect(find.text('Pergunta 2 de 2'), findsWidgets);
      expect(find.text('Estado geral da lataria (1 a 5)'), findsOneWidget);

      // Testa botão 'Anterior' -> Volta para Pergunta 1
      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Freios funcionando corretamente?'), findsOneWidget);

      // Avança novamente para Pergunta 2
      await tester.tap(find.text('Próxima Pergunta'));
      await tester.pumpAndSettle();

      // Avança para a tela final de Revisão
      await tester.tap(find.text('Próxima Pergunta'));
      await tester.pumpAndSettle();

      // Tela de Revisão
      expect(find.text('Resumo da Vistoria'), findsOneWidget);
      expect(find.text('Concluir Vistoria'), findsOneWidget);

      // Conclui vistoria
      await tester.tap(find.text('Concluir Vistoria'));
      await tester.pumpAndSettle();

      expect(checklistSalvo, isNotNull);
      expect(checklistSalvo?.templateId, 'tpl-test');
      expect(checklistSalvo?.veiculoPlaca, 'ABC1D23');
    },
  );
}
