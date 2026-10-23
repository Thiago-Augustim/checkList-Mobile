import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/services/camera_compression_service.dart';
import '../../../../domain/models/checklist_models.dart';
import '../../../theme/app_colors.dart';

/// Formulário Dinâmico em modelo Wizard (Pergunta por Pergunta).
///
/// Apresenta uma pergunta por vez com validação antecipada, barra de progresso
/// e navegação entre "Anterior" e "Próxima", eliminando o risco de pular itens
/// ou deixar de fotografar avarias obrigatórias.
class DynamicChecklistFormView extends StatefulWidget {
  final ChecklistTemplateModel template;
  final List<VeiculoCatalogoModel> veiculos;
  final String? veiculoInicialId;
  final CameraCompressionService cameraService;
  final Future<void> Function(
    ChecklistFilaItemModel checklist,
    List<FotoFilaUploadModel> fotosComprimidas,
  ) onSalvarOffline;

  const DynamicChecklistFormView({
    super.key,
    required this.template,
    required this.veiculos,
    this.veiculoInicialId,
    required this.cameraService,
    required this.onSalvarOffline,
  });

  @override
  State<DynamicChecklistFormView> createState() =>
      _DynamicChecklistFormViewState();
}

class _DynamicChecklistFormViewState extends State<DynamicChecklistFormView> {
  static const _uuid = Uuid();

  late final PageController _pageController;
  int _paginaAtual = 0;

  late String _veiculoSelecionadoId;
  late TextEditingController _kmController;
  final _obsGeraisController = TextEditingController();

  final Map<String, String> _valoresRespostas = {};
  final Map<String, TextEditingController> _obsAvariaControllers = {};
  final Map<String, List<Uint8List>> _fotosPorPergunta = {};

  bool _salvando = false;

  List<VeiculoCatalogoModel> get _veiculosMesmoTipo {
    final tipoTemplate = widget.template.tipoVeiculo.trim().toUpperCase();
    final filtrados = widget.veiculos
        .where((v) => v.tipo.trim().toUpperCase() == tipoTemplate)
        .toList();
    return filtrados.isNotEmpty ? filtrados : widget.veiculos;
  }

  /// Total de etapas: 1 (Veículo/KM) + Total Perguntas + 1 (Revisão/Finalização)
  int get _totalEtapas => widget.template.perguntas.length + 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    final listaCompativel = _veiculosMesmoTipo;
    final veiculoInicial = listaCompativel.firstWhere(
      (v) => v.id == widget.veiculoInicialId,
      orElse: () => listaCompativel.first,
    );
    _veiculoSelecionadoId = veiculoInicial.id;
    _kmController =
        TextEditingController(text: veiculoInicial.kmAtual.toString());

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
    _pageController.dispose();
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

  void _removerFotoDeAvaria(String perguntaId, int index) {
    setState(() {
      final list = _fotosPorPergunta[perguntaId];
      if (list != null && index >= 0 && index < list.length) {
        list.removeAt(index);
      }
    });
  }

  bool _validarEtapaAtualEAvancar() {
    // Etapa 0: Validação de Veículo e KM
    if (_paginaAtual == 0) {
      final km = int.tryParse(_kmController.text.trim());
      if (km == null || km < 0) {
        _exibirAviso('Informe um hodômetro (KM) válido para continuar.');
        return false;
      }
      _avancarPagina();
      return true;
    }

    // Etapas 1 a N: Validação da pergunta atual
    final indicePergunta = _paginaAtual - 1;
    if (indicePergunta >= 0 &&
        indicePergunta < widget.template.perguntas.length) {
      final pergunta = widget.template.perguntas[indicePergunta];
      final valor = (_valoresRespostas[pergunta.id] ?? '').trim();

      if (pergunta.obrigatoria && valor.isEmpty) {
        _exibirAviso('Responda a esta pergunta obrigatória para continuar.');
        return false;
      }

      final avaria = pergunta.respostaDisparaAvaria(valor);
      final fotos = _fotosPorPergunta[pergunta.id] ?? [];
      if (avaria && pergunta.exigeFotoSeAvaria && fotos.isEmpty) {
        _exibirAviso(
          'Avaria detectada! Fotografe a avaria com a câmera para continuar.',
        );
        return false;
      }

      _avancarPagina();
      return true;
    }

    // Se estiver na última etapa (Revisão), chama a conclusão
    _concluirESalvarOffline();
    return true;
  }

  void _avancarPagina() {
    if (_paginaAtual < _totalEtapas - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _voltarPagina() {
    if (_paginaAtual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _exibirAviso(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _concluirESalvarOffline() async {
    setState(() {
      _salvando = true;
    });

    try {
      final km = int.parse(_kmController.text.trim());
      final checklistId = _uuid.v4();
      final realizadoEmIso = DateTime.now().toUtc().toIso8601String();
      final veiculo = widget.veiculos
          .firstWhere((v) => v.id == _veiculoSelecionadoId);

      final List<RespostaFilaItemModel> respostasFila = [];
      final List<FotoFilaUploadModel> fotosFilaUpload = [];

      for (final pergunta in widget.template.perguntas) {
        final respostaId = _uuid.v4();
        final rawValor = (_valoresRespostas[pergunta.id] ?? '').trim();
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

  Future<bool> _confirmarSair() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Vistoria?'),
        content: const Text(
          'Se você sair agora, as respostas desta vistoria não serão salvas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar Vistoria'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair sem Salvar'),
          ),
        ],
      ),
    );
    return sair ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totalPerguntas = widget.template.perguntas.length;

    // Subtítulo do cabeçalho
    String subtitulo;
    if (_paginaAtual == 0) {
      subtitulo = 'Passo 1 de $_totalEtapas • Veículo e Hodômetro';
    } else if (_paginaAtual <= totalPerguntas) {
      subtitulo = 'Pergunta $_paginaAtual de $totalPerguntas';
    } else {
      subtitulo = 'Passo $_totalEtapas de $_totalEtapas • Revisão e Envio';
    }

    final progresso = (_paginaAtual + 1) / _totalEtapas;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final podeSair = await _confirmarSair();
        if (podeSair && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.sidebarBg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Sair da Vistoria',
            onPressed: () async {
              final podeSair = await _confirmarSair();
              if (podeSair && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.template.titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progresso,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              minHeight: 4,
            ),
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) {
            setState(() {
              _paginaAtual = page;
            });
          },
          itemCount: _totalEtapas,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _construirEtapaVeiculo(colors);
            } else if (index <= totalPerguntas) {
              final pergunta = widget.template.perguntas[index - 1];
              return _construirEtapaPergunta(
                pergunta: pergunta,
                numeroPergunta: index,
                totalPerguntas: totalPerguntas,
                colors: colors,
              );
            } else {
              return _construirEtapaRevisao(colors);
            }
          },
        ),
        bottomNavigationBar: _construirBarraNavegacaoInferior(colors),
      ),
    );
  }

  // ===========================================================================
  // ETAPA 0: VEÍCULO E HODÔMETRO
  // ===========================================================================
  Widget _construirEtapaVeiculo(AppColorsExtension colors) {
    final veiculosDisponiveis = _veiculosMesmoTipo;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car_filled,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identificação do Veículo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tipo: ${widget.template.tipoVeiculoFormatado}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Selecione o Veículo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _veiculoSelecionadoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                items: veiculosDisponiveis
                    .map(
                      (v) => DropdownMenuItem<String>(
                        value: v.id,
                        child: Text(
                          '${v.placa} — ${v.modelo}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (novoId) {
                  if (novoId == null) return;
                  final v = widget.veiculos.firstWhere((e) => e.id == novoId);
                  setState(() {
                    _veiculoSelecionadoId = novoId;
                    _kmController.text = v.kmAtual.toString();
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Hodômetro Atual (KM)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.speed_outlined),
                  hintText: 'Ex: 145000',
                  suffixText: 'km',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primaryBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Você responderá as ${widget.template.perguntas.length} perguntas uma a uma no próximo passo.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ETAPA 1 A N: PERGUNTA INDIVIDUAL (UMA POR VEZ)
  // ===========================================================================
  Widget _construirEtapaPergunta({
    required PerguntaTemplateModel pergunta,
    required int numeroPergunta,
    required int totalPerguntas,
    required AppColorsExtension colors,
  }) {
    final isDark = context.isDarkMode;
    final valorAtual = _valoresRespostas[pergunta.id] ?? '';
    final emAvaria = pergunta.respostaDisparaAvaria(valorAtual);
    final fotos = _fotosPorPergunta[pergunta.id] ?? [];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Card Principal da Pergunta
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: emAvaria
                  ? (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626))
                  : colors.border,
              width: emAvaria ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge de Pergunta e Obrigatoriedade
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pergunta $numeroPergunta de $totalPerguntas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: pergunta.obrigatoria
                          ? (isDark
                              ? const Color(0xFF381518)
                              : Colors.red.shade50)
                          : colors.sidebarBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pergunta.obrigatoria
                            ? Colors.red.shade300
                            : colors.border,
                      ),
                    ),
                    child: Text(
                      pergunta.obrigatoria ? 'OBRIGATÓRIA' : 'OPCIONAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: pergunta.obrigatoria
                            ? Colors.red
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Enunciado da pergunta
              Text(
                pergunta.enunciado,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Campo de Resposta Dinâmico (Grande e Ergonômico)
              _construirOpcoesDeResposta(pergunta, valorAtual, colors, isDark),
            ],
          ),
        ),

        // Bloco de Avaria e Foto Obrigatória (caso a resposta aponte avaria)
        if (emAvaria) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E1518) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF7F1D1D)
                    : Colors.red.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pergunta.exigeFotoSeAvaria
                            ? 'Avaria Detectada • Foto Obrigatória'
                            : 'Avaria Detectada',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  pergunta.exigeFotoSeAvaria
                      ? 'Você deve fotografar a avaria antes de avançar para a próxima pergunta.'
                      : 'Tire uma foto se desejar registrar a avaria.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFFCA5A5)
                        : Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 14),

                // Botão de Captura de Foto
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _capturarFotoDeAvaria(pergunta.id),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    fotos.isEmpty
                        ? 'Tirar Foto da Avaria com a Câmera'
                        : 'Adicionar Outra Foto (${fotos.length} anexada)',
                  ),
                ),

                // Lista de Miniaturas das Fotos Anexadas
                if (fotos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: fotos.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final bytes = entry.value;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              bytes,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () =>
                                  _removerFotoDeAvaria(pergunta.id, idx),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                TextField(
                  controller: _obsAvariaControllers[pergunta.id],
                  decoration: InputDecoration(
                    labelText: 'Descrição da Avaria (Opcional)',
                    fillColor: colors.surface,
                    filled: true,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _construirOpcoesDeResposta(
    PerguntaTemplateModel pergunta,
    String valorAtual,
    AppColorsExtension colors,
    bool isDark,
  ) {
    if (pergunta.tipoResposta == 'BOOLEANO') {
      final simSelecionado = valorAtual == 'TRUE';
      final naoSelecionado = valorAtual == 'FALSE';

      return Column(
        children: [
          // Opção SIM (Conforme)
          InkWell(
            onTap: () {
              setState(() {
                _valoresRespostas[pergunta.id] = 'TRUE';
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: simSelecionado ? colors.primaryBg : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: simSelecionado ? colors.primary : colors.border,
                  width: simSelecionado ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    simSelecionado
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: simSelecionado ? colors.primary : colors.sidebarTextMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SIM (Conforme / Tudo Certo)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: simSelecionado
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Opção NÃO (Com Avaria)
          InkWell(
            onTap: () {
              setState(() {
                _valoresRespostas[pergunta.id] = 'FALSE';
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: naoSelecionado
                    ? (isDark ? const Color(0xFF381518) : Colors.red.shade50)
                    : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: naoSelecionado
                      ? const Color(0xFFDC2626)
                      : colors.border,
                  width: naoSelecionado ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    naoSelecionado
                        ? Icons.cancel
                        : Icons.radio_button_unchecked,
                    color: naoSelecionado
                        ? const Color(0xFFDC2626)
                        : colors.sidebarTextMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NÃO (Com Avaria / Não Conforme)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: naoSelecionado
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: naoSelecionado
                            ? const Color(0xFFDC2626)
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (pergunta.tipoResposta == 'ESCALA_1_5') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final nota = (index + 1).toString();
              final selecionado = valorAtual == nota;
              final isCritico = index <= 1;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _valoresRespostas[pergunta.id] = nota;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? (isCritico
                                ? const Color(0xFFDC2626)
                                : colors.primary)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selecionado
                              ? (isCritico
                                  ? const Color(0xFFDC2626)
                                  : colors.primary)
                              : colors.border,
                          width: selecionado ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        nota,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: selecionado
                              ? Colors.white
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 = Crítico (Avaria)',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
              Text(
                '5 = Excelente',
                style: TextStyle(fontSize: 11, color: colors.primary),
              ),
            ],
          ),
        ],
      );
    }

    // Tipo TEXTO
    return TextField(
      onChanged: (v) {
        _valoresRespostas[pergunta.id] = v;
      },
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Digite suas observações ou respostas...',
      ),
    );
  }

  // ===========================================================================
  // ETAPA FINAL: REVISÃO E CONCLUSÃO
  // ===========================================================================
  Widget _construirEtapaRevisao(AppColorsExtension colors) {
    final veiculo =
        widget.veiculos.firstWhere((v) => v.id == _veiculoSelecionadoId);
    final totalPerguntas = widget.template.perguntas.length;

    int conformes = 0;
    int avarias = 0;
    int totalFotos = 0;

    for (final p in widget.template.perguntas) {
      final val = _valoresRespostas[p.id] ?? '';
      if (p.respostaDisparaAvaria(val)) {
        avarias++;
      } else {
        conformes++;
      }
      totalFotos += (_fotosPorPergunta[p.id] ?? []).length;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fact_check,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo da Vistoria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${veiculo.placa} • ${_kmController.text} km',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Indicadores rápidos
              Row(
                children: [
                  Expanded(
                    child: _buildItemResumo(
                      label: 'Total Itens',
                      valor: '$totalPerguntas',
                      cor: colors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _buildItemResumo(
                      label: 'Conformes',
                      valor: '$conformes',
                      cor: colors.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildItemResumo(
                      label: 'Avarias',
                      valor: '$avarias',
                      cor: avarias > 0
                          ? const Color(0xFFDC2626)
                          : colors.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildItemResumo(
                      label: 'Fotos',
                      valor: '$totalFotos',
                      cor: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Observações Gerais
              Text(
                'Observações Gerais da Vistoria (Opcional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _obsGeraisController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Adicione observações finais se necessário...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemResumo({
    required String label,
    required String valor,
    required Color cor,
  }) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BARRA DE NAVEGAÇÃO INFERIOR FIXA (ANTERIOR / PRÓXIMA / CONCLUIR)
  // ===========================================================================
  Widget _construirBarraNavegacaoInferior(AppColorsExtension colors) {
    final ePrimeiraEtapa = _paginaAtual == 0;
    final eUltimaEtapa = _paginaAtual == _totalEtapas - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Botão Anterior
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: ePrimeiraEtapa ? null : _voltarPagina,
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              label: const Text('Anterior'),
            ),
          ),
          const SizedBox(width: 14),

          // Botão Próxima / Concluir
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _salvando ? null : _validarEtapaAtualEAvancar,
              icon: _salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      eUltimaEtapa
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_ios,
                      size: 16,
                    ),
              label: Text(
                _salvando
                    ? 'Salvando...'
                    : (eUltimaEtapa ? 'Concluir Vistoria' : 'Próxima Pergunta'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
