import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/checklist_models.dart';

class HiveStorageService {
  static const String authBoxName = 'auth_box';
  static const String catalogBoxName = 'catalog_box';
  static const String syncChecklistsBoxName = 'sync_checklists_box';
  static const String syncPhotosBoxName = 'sync_photos_box';

  late final Box<String> _authBox;
  late final Box<String> _catalogBox;
  late final Box<String> _syncChecklistsBox;
  late final Box<String> _syncPhotosBox;

  Future<void> init({String? customSubDir}) async {
    if (customSubDir != null) {
      Hive.init(customSubDir);
    } else {
      await Hive.initFlutter();
    }
    _authBox = await Hive.openBox<String>(authBoxName);
    _catalogBox = await Hive.openBox<String>(catalogBoxName);
    _syncChecklistsBox = await Hive.openBox<String>(syncChecklistsBoxName);
    _syncPhotosBox = await Hive.openBox<String>(syncPhotosBoxName);
  }

  // ===========================================================================
  // Autenticação Local (JWT + Refresh Token)
  // ===========================================================================
  Future<void> salvarSessao(AuthSessionModel session) async {
    await _authBox.put('session', jsonEncode(session.toJson()));
  }

  AuthSessionModel? obterSessao() {
    final raw = _authBox.get('session');
    if (raw == null) return null;
    return AuthSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> limparSessao() async {
    await _authBox.delete('session');
  }

  // ===========================================================================
  // Cache do Catálogo Offline (Veículos + Templates Dinâmicos)
  // ===========================================================================
  Future<void> salvarCatalogo(CatalogoOfflineModel catalogo) async {
    await _catalogBox.put('catalogo', jsonEncode(catalogo.toJson()));
  }

  CatalogoOfflineModel? obterCatalogo() {
    final raw = _catalogBox.get('catalogo');
    if (raw == null) return null;
    return CatalogoOfflineModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  // ===========================================================================
  // Fila Offline Etapa 1: Checklists JSON Leves
  // ===========================================================================
  Future<void> enfileirarChecklist(ChecklistFilaItemModel item) async {
    await _syncChecklistsBox.put(
      item.id,
      jsonEncode(item.toStorageJson()),
    );
  }

  List<ChecklistFilaItemModel> listarChecklistsNaFila() {
    return _syncChecklistsBox.values
        .map(
          (raw) => ChecklistFilaItemModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> removerChecklistDaFila(String checklistId) async {
    await _syncChecklistsBox.delete(checklistId);
  }

  // ===========================================================================
  // Fila Offline Etapa 2: Fotos de Avarias Comprimidas
  // ===========================================================================
  Future<void> enfileirarFoto(FotoFilaUploadModel foto) async {
    await _syncPhotosBox.put(foto.id, jsonEncode(foto.toJson()));
  }

  List<FotoFilaUploadModel> listarFotosNaFila() {
    return _syncPhotosBox.values
        .map(
          (raw) => FotoFilaUploadModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> removerFotoDaFila(String fotoId) async {
    await _syncPhotosBox.delete(fotoId);
  }

  // ===========================================================================
  // Limpeza de Filas para Reset de Testes / Descarte de Itens Inválidos
  // ===========================================================================
  Future<void> limparFilasDeSincronizacao() async {
    await _syncChecklistsBox.clear();
    await _syncPhotosBox.clear();
  }
}
