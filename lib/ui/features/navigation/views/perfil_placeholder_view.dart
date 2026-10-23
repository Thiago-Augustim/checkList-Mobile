import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_controller.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../checklist/view_models/driver_home_view_model.dart';

class PerfilPlaceholderView extends StatelessWidget {
  final AuthViewModel authViewModel;
  final DriverHomeViewModel? homeViewModel;

  const PerfilPlaceholderView({
    super.key,
    required this.authViewModel,
    this.homeViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    final usuario = authViewModel.sessao?.usuario;

    return Scaffold(
      backgroundColor: colors.sidebarBg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              'Minha Conta e Configurações',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Card de Perfil do Motorista
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colors.primaryBg,
                  child: Text(
                    _obterIniciais(usuario?.nome ?? 'Motorista'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario?.nome ?? 'Motorista',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usuario?.email ?? 'motorista@checklist.com.br',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          usuario?.perfil ?? 'MOTORISTA',
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Configurações Rápidas (Aparência)
          Text(
            'Preferências de Aparência',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema Visual',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          isDark ? 'Tema Escuro ativo' : 'Tema Claro ativo',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<ThemeMode>(
                    tooltip: 'Alterar Tema',
                    icon: Icon(Icons.arrow_drop_down, color: colors.textPrimary),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Aviso de construção futura
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta tela de Perfil será personalizada e detalhada nas próximas etapas conforme seu fluxo.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botão Sair da Conta
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _confirmarLogout(context),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Sair da Conta',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deseja realmente sair?'),
        content: const Text(
          'Ao sair, você precisará informar suas credenciais novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await authViewModel.logout();
    }
  }

  String _obterIniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return 'M';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}
