import 'package:flutter/material.dart';
import '../../../../data/services/camera_compression_service.dart';
import '../../../../domain/models/checklist_models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_controller.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/driver_home_view_model.dart';
import 'dynamic_checklist_form_view.dart';

class DriverHomeView extends StatefulWidget {
  final AuthViewModel authViewModel;
  final DriverHomeViewModel homeViewModel;
  final CameraCompressionService cameraService;

  const DriverHomeView({
    super.key,
    required this.authViewModel,
    required this.homeViewModel,
    required this.cameraService,
  });

  @override
  State<DriverHomeView> createState() => _DriverHomeViewState();
}

class _DriverHomeViewState extends State<DriverHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.homeViewModel.baixarCatalogoAtualizado();
    });
  }

  Future<void> _abrirFormularioDinamico(
    ChecklistTemplateModel template,
  ) async {
    final veiculoSelecionado = widget.homeViewModel.veiculoSelecionado;
    if (veiculoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um veículo antes de iniciar a vistoria.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DynamicChecklistFormView(
          template: template,
          veiculos: widget.homeViewModel.catalogo.veiculos,
          veiculoInicialId: veiculoSelecionado.id,
          cameraService: widget.cameraService,
          onSalvarOffline: (checklist, fotos) async {
            await widget.homeViewModel.registrarNovaVistoriaOffline(
              checklist: checklist,
              fotosComprimidas: fotos,
            );
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (context, _) {
        final vm = widget.homeViewModel;
        final usuario = widget.authViewModel.sessao?.usuario;
        final veiculoAtual = vm.veiculoSelecionado;
        final templatesFiltrados = vm.templatesParaVeiculoSelecionado;

        return Scaffold(
          backgroundColor: colors.sidebarBg,
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CheckList Motorista',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  usuario?.nome ?? 'Motorista',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<ThemeMode>(
                tooltip: 'Tema do Aplicativo',
                icon: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: colors.textPrimary,
                ),
                initialValue: context.themeController.themeMode,
                onSelected: (mode) =>
                    context.themeController.setThemeMode(mode),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        Icon(Icons.light_mode, size: 20),
                        SizedBox(width: 8),
                        Text('Tema Claro'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode, size: 20),
                        SizedBox(width: 8),
                        Text('Tema Escuro'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        Icon(Icons.brightness_auto, size: 20),
                        SizedBox(width: 8),
                        Text('Padrão do Sistema'),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Baixar Catálogo do Servidor',
                onPressed:
                    vm.sincronizando ? null : vm.baixarCatalogoAtualizado,
                icon: Icon(
                  Icons.cloud_download_outlined,
                  color: colors.textPrimary,
                ),
              ),
              IconButton(
                tooltip: 'Sair',
                onPressed: widget.authViewModel.logout,
                icon: Icon(Icons.logout, color: colors.textPrimary),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Chave de Simulação de Estrada (Online vs Offline)
              Card(
                elevation: 0,
                color: vm.modoOfflineSimulado
                    ? (isDark
                        ? const Color(0xFF2E2008)
                        : const Color(0xFFFEF3C7))
                    : colors.primaryBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: vm.modoOfflineSimulado
                        ? const Color(0xFFF59E0B)
                        : colors.primary,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    vm.modoOfflineSimulado
                        ? 'Modo Estrada: SEM INTERNET (Offline)'
                        : 'Modo Pátio: CONECTADO (Online)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    vm.modoOfflineSimulado
                        ? 'As vistorias e fotos comprimidas serão retidas na fila local do Hive.'
                        : 'Sincronização automática em 2 etapas com o Spring Boot ativa.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  value: vm.modoOfflineSimulado,
                  onChanged: vm.alternarModoOfflineSimulado,
                  secondary: Icon(
                    vm.modoOfflineSimulado ? Icons.wifi_off : Icons.wifi,
                    color: vm.modoOfflineSimulado
                        ? Colors.amber.shade700
                        : colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Fila de Sincronização Compacta (apenas quantidade pendente e botão sincronizar)
              Card(
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_sync_outlined,
                        size: 20,
                        color: vm.totalPendenciasNaFila > 0
                            ? (isDark
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFFD97706))
                            : colors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text.rich(
                        TextSpan(
                          text: 'Pendentes: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: '${vm.totalPendenciasNaFila}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: vm.totalPendenciasNaFila > 0
                                    ? (isDark
                                        ? const Color(0xFFFCD34D)
                                        : Colors.amber.shade900)
                                    : colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: vm.sincronizando ||
                                vm.totalPendenciasNaFila == 0
                            ? null
                            : () async {
                                await vm.sincronizarFilaAgora();
                                if (context.mounted &&
                                    vm.mensagemStatus != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(vm.mensagemStatus!),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                        icon: vm.sincronizando
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync, size: 16),
                        label: Text(
                          vm.sincronizando ? 'Sincronizando...' : 'Sincronizar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 1. Seleção do Veículo pelo Motorista
              Text(
                '1. Selecione o Veículo da Vistoria',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: vm.catalogo.veiculos.isEmpty
                      ? Text(
                          'Nenhum veículo sincronizado no catálogo offline.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              key: ValueKey(veiculoAtual?.id),
                              initialValue: veiculoAtual?.id,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Placa / Modelo do Veículo',
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              items: vm.catalogo.veiculos
                                  .map(
                                    (v) => DropdownMenuItem<String>(
                                      value: v.id,
                                      child: Text(
                                        '${v.placa} — ${v.modelo} (${v.tipoFormatado})',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (novoId) {
                                if (novoId != null) {
                                  vm.selecionarVeiculo(novoId);
                                }
                              },
                            ),
                            if (veiculoAtual != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.primaryBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colors.primary.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'Tipo: ${veiculoAtual.tipoFormatado}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'KM Atual: ${veiculoAtual.kmAtual}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Modelos de Checklist Filtrados pelo Tipo do Veículo Selecionado
              Text(
                veiculoAtual != null
                    ? '2. Checklists para ${veiculoAtual.tipoFormatado}'
                    : '2. Modelos de Checklist Disponíveis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              if (templatesFiltrados.isEmpty)
                Card(
                  elevation: 0,
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      veiculoAtual != null
                          ? 'Nenhum modelo de checklist cadastrado para o tipo "${veiculoAtual.tipoFormatado}".'
                          : 'Selecione um veículo para ver os checklists compatíveis.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...templatesFiltrados.map(
                  (template) => Card(
                    key: ValueKey(template.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryBg,
                        child: Icon(
                          Icons.assignment_turned_in,
                          color: colors.primary,
                        ),
                      ),
                      title: Text(
                        template.titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      trailing: FilledButton(
                        onPressed: () => _abrirFormularioDinamico(template),
                        child: const Text('Iniciar'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
