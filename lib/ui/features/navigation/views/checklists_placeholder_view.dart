import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../checklist/view_models/driver_home_view_model.dart';

class ChecklistsPlaceholderView extends StatelessWidget {
  final DriverHomeViewModel? homeViewModel;

  const ChecklistsPlaceholderView({
    super.key,
    this.homeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: colors.sidebarBg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checklists',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              'Histórico e Gerenciamento',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Card de status da tela
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    size: 38,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Central de Checklists',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nesta aba serão listados os checklists realizados, pendentes de envio e o histórico completo de vistorias.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 14,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Próxima Etapa • Construção desta tela',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Resumo rápido de dados conectados
          if (homeViewModel != null)
            ListenableBuilder(
              listenable: homeViewModel!,
              builder: (context, _) {
                final vm = homeViewModel!;
                final veiculo = vm.veiculoSelecionado;
                final totalPendentes = vm.totalPendenciasNaFila;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Status Atual Conectado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              colors: colors,
                              icon: Icons.directions_car_outlined,
                              label: 'Veículo Selecionado',
                              value: veiculo != null
                                  ? '${veiculo.placa} (${veiculo.tipo})'
                                  : 'Nenhum selecionado',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              colors: colors,
                              icon: Icons.sync_outlined,
                              label: 'Fila Offline Pendente',
                              value: totalPendentes > 0
                                  ? '$totalPendentes item(ns) aguardando envio'
                                  : 'Tudo sincronizado',
                              valueColor: totalPendentes > 0
                                  ? const Color(0xFFE65100)
                                  : colors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required AppColorsExtension colors,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.sidebarTextMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
