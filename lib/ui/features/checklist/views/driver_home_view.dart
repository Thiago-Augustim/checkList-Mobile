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
    final veiculos = widget.homeViewModel.catalogo.veiculos;
    if (veiculos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum veículo disponível no catálogo offline.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => DynamicChecklistFormView(
          template: template,
          veiculos: veiculos,
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
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (context, _) {
        final vm = widget.homeViewModel;
        final usuario = widget.authViewModel.sessao?.usuario;

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
                          const Text(
                            'Fila de Sincronização Local (Hive)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
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
                      FilledButton.icon(
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
                              : 'Sincronizar Fila Agora (2 Etapas)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Iniciar Nova Vistoria (Formulários Dinâmicos)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...vm.catalogo.templates.map(
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
                      '${template.perguntas.length} perguntas dinâmicas • ${template.descricao ?? "Pronto para preenchimento offline"}',
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
