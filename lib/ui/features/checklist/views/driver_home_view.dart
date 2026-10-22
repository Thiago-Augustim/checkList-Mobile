import 'package:flutter/material.dart';
import '../../../../data/services/camera_compression_service.dart';
import '../../../../domain/models/checklist_models.dart';
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

  Future<void> _confirmarLimparFila(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Fila Local?'),
        content: const Text(
          'Deseja descartar todos os checklists e fotos pendentes na fila local do Hive? '
          'Essa ação remove itens inválidos e permite reiniciar os testes do zero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await widget.homeViewModel.limparFilaLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (context, _) {
        final vm = widget.homeViewModel;
        final usuario = widget.authViewModel.sessao?.usuario;
        final veiculoAtual = vm.veiculoSelecionado;
        final templatesFiltrados = vm.templatesParaVeiculoSelecionado;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CheckList Motorista',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  usuario?.nome ?? 'Motorista',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Baixar Catálogo do Servidor',
                onPressed:
                    vm.sincronizando ? null : vm.baixarCatalogoAtualizado,
                icon: const Icon(Icons.cloud_download_outlined),
              ),
              IconButton(
                tooltip: 'Sair',
                onPressed: widget.authViewModel.logout,
                icon: const Icon(Icons.logout),
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
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFECFDF5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: vm.modoOfflineSimulado
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    vm.modoOfflineSimulado
                        ? 'Modo Estrada: SEM INTERNET (Offline)'
                        : 'Modo Pátio: CONECTADO (Online)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    vm.modoOfflineSimulado
                        ? 'As vistorias e fotos comprimidas serão retidas na fila local do Hive.'
                        : 'Sincronização automática em 2 etapas com o Spring Boot ativa.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: vm.modoOfflineSimulado,
                  onChanged: vm.alternarModoOfflineSimulado,
                  secondary: Icon(
                    vm.modoOfflineSimulado ? Icons.wifi_off : Icons.wifi,
                    color: vm.modoOfflineSimulado
                        ? Colors.amber.shade900
                        : Colors.teal.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card da Fila de Sincronização (Hive Boxes)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Fila de Sincronização Local (Hive)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              '${vm.totalPendenciasNaFila} pendentes',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: vm.totalPendenciasNaFila > 0
                                ? Colors.amber.shade100
                                : Colors.grey.shade200,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Etapa 1 (JSONs leves de Checklist): ${vm.checklistsNaFila.length} na fila\n'
                        '• Etapa 2 (Uploads Multipart de Fotos): ${vm.fotosNaFila.length} na fila',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      if (vm.mensagemStatus != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vm.mensagemStatus!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: vm.sincronizando ||
                                      vm.totalPendenciasNaFila == 0
                                  ? null
                                  : vm.sincronizarFilaAgora,
                              icon: vm.sincronizando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(
                                vm.sincronizando
                                    ? 'Sincronizando Fila...'
                                    : 'Sincronizar Fila Agora',
                              ),
                            ),
                          ),
                          if (vm.totalPendenciasNaFila > 0) ...[
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Limpar Fila do Hive',
                              style: IconButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                backgroundColor: Colors.red.shade50,
                              ),
                              onPressed: vm.sincronizando
                                  ? null
                                  : () => _confirmarLimparFila(context),
                              icon: const Icon(Icons.delete_sweep_outlined),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 1. Seleção do Veículo pelo Motorista
              const Text(
                '1. Selecione o Veículo da Vistoria',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: vm.catalogo.veiculos.isEmpty
                      ? const Text(
                          'Nenhum veículo sincronizado no catálogo offline.',
                          style: TextStyle(fontSize: 13),
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
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              items: vm.catalogo.veiculos
                                  .map(
                                    (v) => DropdownMenuItem<String>(
                                      value: v.id,
                                      child: Text(
                                        '${v.placa} — ${v.modelo} (${v.tipoFormatado})',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
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
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      'Tipo: ${veiculoAtual.tipoFormatado}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'KM Atual: ${veiculoAtual.kmAtual}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (templatesFiltrados.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      veiculoAtual != null
                          ? 'Nenhum modelo de checklist cadastrado para o tipo "${veiculoAtual.tipoFormatado}".'
                          : 'Selecione um veículo para ver os checklists compatíveis.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )
              else
                ...templatesFiltrados.map(
                  (template) => Card(
                    key: ValueKey(template.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(
                          Icons.assignment_turned_in,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      title: Text(
                        template.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${template.perguntas.length} perguntas • ${template.tipoVeiculoFormatado}\n${template.descricao ?? "Pronto para preenchimento offline"}',
                        style: const TextStyle(fontSize: 12),
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
