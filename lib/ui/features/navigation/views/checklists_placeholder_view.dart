import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/models/checklist_models.dart';
import '../../../theme/app_colors.dart';
import '../../checklist/view_models/driver_home_view_model.dart';

/// Tela da aba Checklists com histórico de vistorias enviadas (5 por página),
/// exibindo data e horário de realização como registro imutável (sem possibilidade de alteração).
class ChecklistsPlaceholderView extends StatefulWidget {
  final DriverHomeViewModel? homeViewModel;

  const ChecklistsPlaceholderView({
    super.key,
    this.homeViewModel,
  });

  @override
  State<ChecklistsPlaceholderView> createState() =>
      _ChecklistsPlaceholderViewState();
}

class _ChecklistsPlaceholderViewState extends State<ChecklistsPlaceholderView> {
  static const int _itensPorPagina = 5;
  int _paginaAtual = 1;
  String? _ultimoVeiculoId;

  String _formatarDataHora(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final ano = dt.year.toString();
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final seg = dt.second.toString().padLeft(2, '0');
      return '$dia/$mes/$ano às $hora:$min:$seg';
    } catch (_) {
      return isoString;
    }
  }

  void _abrirModalDetalhesImutavel(
    BuildContext context,
    ChecklistFilaItemModel item,
  ) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Barra de arraste
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabeçalho do Modal
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_clock_outlined,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.templateTitulo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Veículo: ${item.veiculoPlaca} • KM: ${item.kmVistoria}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Alerta de Imutabilidade (Não possibilitando alterar)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2638)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 20,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Registro finalizado e sincronizado. Os dados, data e respostas não podem ser alterados.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Lista de perguntas e respostas gravadas (Somente Leitura)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Container com Data e Horário em destaque
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.gridHoverBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data e Horário Realizado: ${_formatarDataHora(item.realizadoEm)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (item.observacoesGerais != null &&
                        item.observacoesGerais!.trim().isNotEmpty) ...[
                      Text(
                        'Observações Gerais da Vistoria:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          item.observacoesGerais!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'Itens Inspecionados (${item.respostas.length}):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...item.respostas.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final resp = entry.value;
                      final isAvaria = resp.avariaDetectada;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAvaria
                              ? (isDark
                                  ? const Color(0xFF2A1B14)
                                  : const Color(0xFFFFF7ED))
                              : colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAvaria
                                ? const Color(0xFFF97316)
                                : colors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Item #$idx',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAvaria
                                        ? const Color(0xFFF97316)
                                        : colors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isAvaria
                                        ? 'AVARIA IDENTIFICADA'
                                        : 'CONFORME',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Valor Registrado: ${resp.valorResposta}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (resp.observacaoAvaria != null &&
                                resp.observacaoAvaria!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Avaria: ${resp.observacaoAvaria}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFEA580C),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Botão inferior Fechar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fechar Visualização'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    if (widget.homeViewModel == null) {
      return Scaffold(
        backgroundColor: colors.sidebarBg,
        appBar: AppBar(
          title: const Text('Histórico de Checklists'),
        ),
        body: const Center(
          child: Text('Nenhum dado disponível.'),
        ),
      );
    }

    return ListenableBuilder(
      listenable: widget.homeViewModel!,
      builder: (context, _) {
        final vm = widget.homeViewModel!;
        final veiculoAtual = vm.veiculoSelecionado;

        // Se o caminhão/veículo selecionado mudar na Home, reinicia na página 1
        if (_ultimoVeiculoId != veiculoAtual?.id) {
          _ultimoVeiculoId = veiculoAtual?.id;
          _paginaAtual = 1;
        }

        // Filtra apenas os checklists do caminhão selecionado na tela principal
        final todosEnviados = vm.checklistsEnviadosDoVeiculoSelecionado;
        final totalItens = todosEnviados.length;
        final totalPaginas = max(1, (totalItens / _itensPorPagina).ceil());

        // Ajusta página atual se ultrapassar o total após exclusões/recargas
        if (_paginaAtual > totalPaginas) {
          _paginaAtual = totalPaginas;
        }

        final inicioIndice = (_paginaAtual - 1) * _itensPorPagina;
        final fimIndice = min(inicioIndice + _itensPorPagina, totalItens);
        final itensPaginaAtual = totalItens == 0
            ? <ChecklistFilaItemModel>[]
            : todosEnviados.sublist(inicioIndice, fimIndice);

        return Scaffold(
          backgroundColor: colors.sidebarBg,
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico de Checklists',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  veiculoAtual != null
                      ? 'Caminhão: ${veiculoAtual.placa} (${veiculoAtual.tipoFormatado}) • $totalItens registro(s)'
                      : 'Checklists Enviados • $totalItens registro(s)',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          body: totalItens == 0
              ? _buildEstadoVazio(colors, veiculoAtual)
              : Column(
                  children: [
                    // Barra de Resumo no Topo com o Caminhão Selecionado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: colors.surface,
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  veiculoAtual != null
                                      ? 'Caminhão: ${veiculoAtual.placa} - ${veiculoAtual.modelo}'
                                      : 'Todos os Veículos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Exibindo ${inicioIndice + 1}–$fimIndice de $totalItens vistorias',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '5 por página',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.border),

                    // Lista dos 5 itens da página atual
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: itensPaginaAtual.length,
                        itemBuilder: (context, index) {
                          final item = itensPaginaAtual[index];
                          return _buildCardChecklistEnviado(
                            context: context,
                            item: item,
                            colors: colors,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),

                    // Barra de Paginação Inferior
                    _buildBarraPaginacao(
                      colors: colors,
                      paginaAtual: _paginaAtual,
                      totalPaginas: totalPaginas,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCardChecklistEnviado({
    required BuildContext context,
    required ChecklistFilaItemModel item,
    required AppColorsExtension colors,
    required bool isDark,
  }) {
    final totalAvarias =
        item.respostas.where((r) => r.avariaDetectada).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha do Título e Badge Enviado
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.templateTitulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primaryBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'ENVIADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Container em Destaque: Data e Horário Imutável
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.gridHoverBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Realizado em: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: _formatarDataHora(item.realizadoEm),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: colors.sidebarTextMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Imutável',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.sidebarTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Metadados do Checklist (Veículo, KM, Avarias)
            Row(
              children: [
                _buildInfoTag(
                  colors: colors,
                  icon: Icons.directions_car_outlined,
                  text: item.veiculoPlaca.isNotEmpty
                      ? item.veiculoPlaca
                      : 'Veículo Geral',
                ),
                const SizedBox(width: 8),
                _buildInfoTag(
                  colors: colors,
                  icon: Icons.speed_outlined,
                  text: '${item.kmVistoria} km',
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: totalAvarias > 0
                        ? (isDark
                            ? const Color(0xFF38290A)
                            : const Color(0xFFFEF3C7))
                        : colors.primaryBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    totalAvarias > 0
                        ? '$totalAvarias avaria(s)'
                        : 'Sem avarias',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: totalAvarias > 0
                          ? (isDark
                              ? const Color(0xFFFCD34D)
                              : Colors.amber.shade900)
                          : colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botão Visualizar Detalhes (Modo Somente Leitura)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _abrirModalDetalhesImutavel(context, item),
                icon: Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                label: Text(
                  'Visualizar Vistoria (Somente Leitura)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag({
    required AppColorsExtension colors,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.sidebarTextMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraPaginacao({
    required AppColorsExtension colors,
    required int paginaAtual,
    required int totalPaginas,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Anterior
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: paginaAtual > 1
                ? () {
                    setState(() {
                      _paginaAtual--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Anterior'),
          ),

          // Botões numéricos de páginas
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(totalPaginas, (index) {
              final numeroPagina = index + 1;
              final selecionada = numeroPagina == paginaAtual;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    if (!selecionada) {
                      setState(() {
                        _paginaAtual = numeroPagina;
                      });
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selecionada ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selecionada ? colors.primary : colors.border,
                      ),
                    ),
                    child: Text(
                      '$numeroPagina',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selecionada ? FontWeight.bold : FontWeight.normal,
                        color: selecionada ? Colors.white : colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Botão Próxima
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: paginaAtual < totalPaginas
                ? () {
                    setState(() {
                      _paginaAtual++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Próxima'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVazio(
    AppColorsExtension colors,
    VeiculoCatalogoModel? veiculo,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 32,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              veiculo != null
                  ? 'Nenhum checklist enviado para ${veiculo.placa}'
                  : 'Nenhum checklist enviado ainda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              veiculo != null
                  ? 'As vistorias finalizadas para o veículo ${veiculo.placa} (${veiculo.modelo}) aparecerão aqui em histórico imutável com data e horário fixos.'
                  : 'Os checklists realizados e sincronizados aparecerão aqui em histórico imutável com data e horário fixos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
