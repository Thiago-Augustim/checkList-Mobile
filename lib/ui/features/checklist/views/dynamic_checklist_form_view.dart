import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/services/camera_compression_service.dart';
import '../../../../domain/models/checklist_models.dart';

class DynamicChecklistFormView extends StatefulWidget {
  final ChecklistTemplateModel template;
  final List<VeiculoCatalogoModel> veiculos;
  final CameraCompressionService cameraService;
  final Future<void> Function(
    ChecklistFilaItemModel checklist,
    List<FotoFilaUploadModel> fotosComprimidas,
  ) onSalvarOffline;

  const DynamicChecklistFormView({
    super.key,
    required this.template,
    required this.veiculos,
    required this.cameraService,
    required this.onSalvarOffline,
  });

  @override
  State<DynamicChecklistFormView> createState() =>
      _DynamicChecklistFormViewState();
}

class _DynamicChecklistFormViewState extends State<DynamicChecklistFormView> {
  static const _uuid = Uuid();

  late String _veiculoSelecionadoId;
  late TextEditingController _kmController;
  final _obsGeraisController = TextEditingController();

  final Map<String, String> _valoresRespostas = {};
  final Map<String, TextEditingController> _obsAvariaControllers = {};
  final Map<String, List<Uint8List>> _fotosPorPergunta = {};

  bool _salvando = false;
  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    final primeiroVeiculo = widget.veiculos.first;
    _veiculoSelecionadoId = primeiroVeiculo.id;
    _kmController =
        TextEditingController(text: primeiroVeiculo.kmAtual.toString());

    for (final p in widget.template.perguntas) {
      _obsAvariaControllers[p.id] = TextEditingController();
      _fotosPorPergunta[p.id] = [];
      if (p.tipoResposta == 'BOOLEANO') {
        _valoresRespostas[p.id] = 'TRUE';
      } else if (p.tipoResposta == 'ESCALA_1_5') {
        _valoresRespostas[p.id] = '5';
      } else {
        _valoresRespostas[p.id] = '';
      }
    }
  }

  @override
  void dispose() {
    _kmController.dispose();
    _obsGeraisController.dispose();
    for (final c in _obsAvariaControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _capturarFotoDeAvaria(String perguntaId) async {
    final bytesComprimidos =
        await widget.cameraService.capturarEComprimirFotoCamera();
    if (bytesComprimidos == null) return;

    setState(() {
      _fotosPorPergunta[perguntaId] = [
        ...(_fotosPorPergunta[perguntaId] ?? []),
        bytesComprimidos,
      ];
    });
  }

  Future<void> _concluirESalvarOffline() async {
    setState(() {
      _erroValidacao = null;
    });

    final km = int.tryParse(_kmController.text.trim());
    if (km == null || km < 0) {
      setState(() {
        _erroValidacao = 'Informe um hodômetro (KM) válido.';
      });
      return;
    }

    // Validação das perguntas dinâmicas e fotos obrigatórias em caso de avaria
    for (final pergunta in widget.template.perguntas) {
      final valor = (_valoresRespostas[pergunta.id] ?? '').trim();
      if (pergunta.obrigatoria && valor.isEmpty) {
        setState(() {
          _erroValidacao =
              'Responda a pergunta obrigatória: "${pergunta.enunciado}"';
        });
        return;
      }

      final avaria = pergunta.respostaDisparaAvaria(valor);
      final fotos = _fotosPorPergunta[pergunta.id] ?? [];
      if (avaria && pergunta.exigeFotoSeAvaria && fotos.isEmpty) {
        setState(() {
          _erroValidacao =
              'A pergunta "${pergunta.enunciado}" aponta avaria e exige pelo menos 1 foto capturada pela câmera.';
        });
        return;
      }
    }

    setState(() {
      _salvando = true;
    });

    try {
      final checklistId = _uuid.v4();
      final realizadoEmIso = DateTime.now().toUtc().toIso8601String();
      final veiculo = widget.veiculos
          .firstWhere((v) => v.id == _veiculoSelecionadoId);

      final List<RespostaFilaItemModel> respostasFila = [];
      final List<FotoFilaUploadModel> fotosFilaUpload = [];

      for (final pergunta in widget.template.perguntas) {
        final respostaId = _uuid.v4();
        final rawValor = (_valoresRespostas[pergunta.id] ?? '').trim();
        // Se a pergunta era opcional e não foi preenchida, usamos 'N/A' para evitar erro de validação @NotBlank no Spring Boot
        final valor = rawValor.isEmpty ? 'N/A' : rawValor;
        final avaria = pergunta.respostaDisparaAvaria(valor);
        final obsAvaria = _obsAvariaControllers[pergunta.id]?.text.trim();
        final bytesFotos = _fotosPorPergunta[pergunta.id] ?? [];

        final List<FotoEsperadaMetaModel> metasFotos = [];
        for (final bytesJpeg in bytesFotos) {
          final fotoId = _uuid.v4();
          final capturadaEm = DateTime.now().toUtc().toIso8601String();
          metasFotos.add(
            FotoEsperadaMetaModel(
              id: fotoId,
              capturadaEm: capturadaEm,
              latitude: -23.55052,
              longitude: -46.633308,
            ),
          );
          fotosFilaUpload.add(
            FotoFilaUploadModel(
              id: fotoId,
              checklistId: checklistId,
              respostaId: respostaId,
              capturadaEm: capturadaEm,
              latitude: -23.55052,
              longitude: -46.633308,
              bytesJpegBase64: base64Encode(bytesJpeg),
            ),
          );
        }

        respostasFila.add(
          RespostaFilaItemModel(
            id: respostaId,
            perguntaId: pergunta.id,
            valorResposta: valor,
            observacaoAvaria:
                obsAvaria != null && obsAvaria.isNotEmpty ? obsAvaria : null,
            avariaDetectada: avaria,
            fotosEsperadas: metasFotos,
          ),
        );
      }

      final checklistFila = ChecklistFilaItemModel(
        id: checklistId,
        templateId: widget.template.id,
        templateTitulo: widget.template.titulo,
        veiculoId: veiculo.id,
        veiculoPlaca: veiculo.placa,
        kmVistoria: km,
        observacoesGerais: _obsGeraisController.text.trim().isEmpty
            ? null
            : _obsGeraisController.text.trim(),
        latitude: -23.55052,
        longitude: -46.633308,
        realizadoEm: realizadoEmIso,
        respostas: respostasFila,
      );

      await widget.onSalvarOffline(checklistFila, fotosFilaUpload);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  Widget _construirCampoDinamico(PerguntaTemplateModel pergunta) {
    final valorAtual = _valoresRespostas[pergunta.id] ?? '';

    if (pergunta.tipoResposta == 'BOOLEANO') {
      return Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('SIM (Conforme)'),
              selected: valorAtual == 'TRUE',
              selectedColor: Colors.green.shade100,
              onSelected: (_) {
                setState(() {
                  _valoresRespostas[pergunta.id] = 'TRUE';
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ChoiceChip(
              label: const Text('NÃO (Com Avaria)'),
              selected: valorAtual == 'FALSE',
              selectedColor: Colors.red.shade100,
              onSelected: (_) {
                setState(() {
                  _valoresRespostas[pergunta.id] = 'FALSE';
                });
              },
            ),
          ),
        ],
      );
    }

    if (pergunta.tipoResposta == 'ESCALA_1_5') {
      return Wrap(
        spacing: 8,
        children: List.generate(5, (index) {
          final nota = (index + 1).toString();
          final selecionado = valorAtual == nota;
          return ChoiceChip(
            label: Text('Nota $nota'),
            selected: selecionado,
            selectedColor: index <= 1
                ? Colors.red.shade100
                : Colors.blue.shade100,
            onSelected: (_) {
              setState(() {
                _valoresRespostas[pergunta.id] = nota;
              });
            },
          );
        }),
      );
    }

    return TextField(
      onChanged: (v) {
        _valoresRespostas[pergunta.id] = v;
      },
      decoration: const InputDecoration(
        hintText: 'Digite sua resposta...',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text(
          widget.template.titulo,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_erroValidacao != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                _erroValidacao!,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],

          // Seleção de Veículo e Hodômetro
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Identificação do Caminhão',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _veiculoSelecionadoId,
                    decoration: const InputDecoration(
                      labelText: 'Placa / Modelo',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.veiculos
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v.id,
                            child: Text('${v.placa} — ${v.modelo}'),
                          ),
                        )
                        .toList(),
                    onChanged: (novoId) {
                      if (novoId == null) return;
                      final v =
                          widget.veiculos.firstWhere((e) => e.id == novoId);
                      setState(() {
                        _veiculoSelecionadoId = novoId;
                        _kmController.text = v.kmAtual.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _kmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hodômetro no Momento da Vistoria (KM)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Perguntas Dinâmicas
          ...widget.template.perguntas.map((pergunta) {
            final valor = _valoresRespostas[pergunta.id] ?? '';
            final emAvaria = pergunta.respostaDisparaAvaria(valor);
            final fotos = _fotosPorPergunta[pergunta.id] ?? [];

            return Card(
              key: ValueKey(pergunta.id),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: emAvaria
                      ? Colors.red.shade400
                      : Colors.grey.shade300,
                  width: emAvaria ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${pergunta.ordem}. ${pergunta.enunciado}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _construirCampoDinamico(pergunta),

                    if (emAvaria) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              pergunta.exigeFotoSeAvaria
                                  ? 'Avaria detectada! Foto da câmera obrigatória (${fotos.length} anexada).'
                                  : 'Avaria detectada (Foto opcional).',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _obsAvariaControllers[pergunta.id],
                              decoration: const InputDecoration(
                                labelText: 'Descreva o problema / avaria',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _capturarFotoDeAvaria(pergunta.id),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text(
                                'Fotografar Avaria com a Câmera (Comprimir JPEG)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _salvando ? null : _concluirESalvarOffline,
            icon: const Icon(Icons.save_alt),
            label: Text(
              _salvando
                  ? 'Salvando na Fila Offline (Hive)...'
                  : 'Concluir Vistoria (Salvar Offline-First)',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
