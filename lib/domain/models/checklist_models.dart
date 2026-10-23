import 'dart:convert';

String normalizarCodigoTipoVeiculo(String tipo) {
  switch (tipo.trim().toUpperCase()) {
    case 'CAVALO':
    case 'CAVALO-MECANICO':
    case 'CAVALO_MECANICO':
      return 'CAVALO_MECANICO';
    case 'CARRETA':
    case 'REBOQUE':
      return 'REBOQUE';
    case 'UTILITARIO':
    case 'CAMINHONETE':
      return 'CAMINHONETE';
    default:
      return tipo.trim().toUpperCase();
  }
}

String formatarTipoVeiculo(String tipo) {
  switch (normalizarCodigoTipoVeiculo(tipo)) {
    case 'CARRO':
      return 'CARRO';
    case 'CAMINHONETE':
      return 'CAMINHONETE';
    case 'TOCO':
      return 'TOCO';
    case 'TRUCK':
      return 'TRUCK';
    case 'CAVALO_MECANICO':
      return 'CAVALO-MECANICO';
    case 'REBOQUE':
      return 'REBOQUE';
    default:
      return tipo;
  }
}

class UsuarioModel {
  final String id;
  final String nome;
  final String username;
  final String email;
  final String perfil;

  const UsuarioModel({
    required this.id,
    required this.nome,
    this.username = '',
    required this.email,
    required this.perfil,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      username: json['username'] as String? ?? (json['email'] as String? ?? ''),
      email: json['email'] as String,
      perfil: json['perfil'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'username': username,
        'email': email,
        'perfil': perfil,
      };
}

class AuthSessionModel {
  final String accessToken;
  final String refreshToken;
  final UsuarioModel usuario;

  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'usuario': usuario.toJson(),
      };
}

class VeiculoCatalogoModel {
  final String id;
  final String placa;
  final String modelo;
  final String tipo;
  final int kmAtual;

  const VeiculoCatalogoModel({
    required this.id,
    required this.placa,
    required this.modelo,
    required this.tipo,
    required this.kmAtual,
  });

  String get tipoFormatado => formatarTipoVeiculo(tipo);

  factory VeiculoCatalogoModel.fromJson(Map<String, dynamic> json) {
    return VeiculoCatalogoModel(
      id: json['id'] as String,
      placa: json['placa'] as String,
      modelo: json['modelo'] as String,
      tipo: normalizarCodigoTipoVeiculo(json['tipo'] as String),
      kmAtual: (json['kmAtual'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placa': placa,
        'modelo': modelo,
        'tipo': tipo,
        'kmAtual': kmAtual,
      };
}

class PerguntaTemplateModel {
  final String id;
  final String enunciado;
  final String tipoResposta; // TEXTO | BOOLEANO | ESCALA_1_5
  final int ordem;
  final bool obrigatoria;
  final bool exigeFotoSeAvaria;
  final String? valorGatilhoAvaria;

  const PerguntaTemplateModel({
    required this.id,
    required this.enunciado,
    required this.tipoResposta,
    required this.ordem,
    required this.obrigatoria,
    required this.exigeFotoSeAvaria,
    this.valorGatilhoAvaria,
  });

  factory PerguntaTemplateModel.fromJson(Map<String, dynamic> json) {
    return PerguntaTemplateModel(
      id: json['id'] as String,
      enunciado: json['enunciado'] as String,
      tipoResposta: json['tipoResposta'] as String,
      ordem: (json['ordem'] as num).toInt(),
      obrigatoria: json['obrigatoria'] as bool? ?? true,
      exigeFotoSeAvaria: json['exigeFotoSeAvaria'] as bool? ?? false,
      valorGatilhoAvaria: json['valorGatilhoAvaria'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enunciado': enunciado,
        'tipoResposta': tipoResposta,
        'ordem': ordem,
        'obrigatoria': obrigatoria,
        'exigeFotoSeAvaria': exigeFotoSeAvaria,
        'valorGatilhoAvaria': valorGatilhoAvaria,
      };

  /// Avalia em tempo real no formulário dinâmico se a resposta atual aciona condição de avaria.
  bool respostaDisparaAvaria(String valorAtual) {
    final val = valorAtual.trim().toUpperCase();
    if (val.isEmpty) return false;

    final gatilho = (valorGatilhoAvaria ?? '').trim().toUpperCase();
    if (tipoResposta == 'BOOLEANO') {
      final alvo = gatilho.isEmpty ? 'FALSE' : gatilho;
      return val == alvo;
    }
    if (tipoResposta == 'ESCALA_1_5') {
      final nota = int.tryParse(val);
      if (nota == null) return false;
      final limite =
          int.tryParse(gatilho.replaceAll('<=', '').trim()) ?? 2;
      return nota <= limite;
    }
    return false;
  }
}

class ChecklistTemplateModel {
  final String id;
  final String titulo;
  final String? descricao;
  final String tipoVeiculo;
  final List<PerguntaTemplateModel> perguntas;

  const ChecklistTemplateModel({
    required this.id,
    required this.titulo,
    this.descricao,
    this.tipoVeiculo = 'CAVALO_MECANICO',
    required this.perguntas,
  });

  String get tipoVeiculoFormatado => formatarTipoVeiculo(tipoVeiculo);

  factory ChecklistTemplateModel.fromJson(Map<String, dynamic> json) {
    final rawPerguntas = (json['perguntas'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return ChecklistTemplateModel(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String?,
      tipoVeiculo: normalizarCodigoTipoVeiculo(
        json['tipoVeiculo'] as String? ?? 'CAVALO_MECANICO',
      ),
      perguntas: rawPerguntas.map(PerguntaTemplateModel.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descricao': descricao,
        'tipoVeiculo': tipoVeiculo,
        'perguntas': perguntas.map((p) => p.toJson()).toList(),
      };
}

class CatalogoOfflineModel {
  final String sincronizadoEm;
  final List<VeiculoCatalogoModel> veiculos;
  final List<ChecklistTemplateModel> templates;

  const CatalogoOfflineModel({
    required this.sincronizadoEm,
    required this.veiculos,
    required this.templates,
  });

  factory CatalogoOfflineModel.fromJson(Map<String, dynamic> json) {
    final rawVeiculos = (json['veiculos'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    final rawTemplates = (json['templates'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return CatalogoOfflineModel(
      sincronizadoEm: json['sincronizadoEm'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
      veiculos: rawVeiculos.map(VeiculoCatalogoModel.fromJson).toList(),
      templates: rawTemplates.map(ChecklistTemplateModel.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sincronizadoEm': sincronizadoEm,
        'veiculos': veiculos.map((v) => v.toJson()).toList(),
        'templates': templates.map((t) => t.toJson()).toList(),
      };
}

class FotoEsperadaMetaModel {
  final String id;
  final String capturadaEm;
  final double? latitude;
  final double? longitude;

  const FotoEsperadaMetaModel({
    required this.id,
    required this.capturadaEm,
    this.latitude,
    this.longitude,
  });

  factory FotoEsperadaMetaModel.fromJson(Map<String, dynamic> json) {
    return FotoEsperadaMetaModel(
      id: json['id'] as String,
      capturadaEm: json['capturadaEm'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'capturadaEm': capturadaEm,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class RespostaFilaItemModel {
  final String id;
  final String perguntaId;
  final String valorResposta;
  final String? observacaoAvaria;
  final bool avariaDetectada;
  final List<FotoEsperadaMetaModel> fotosEsperadas;

  const RespostaFilaItemModel({
    required this.id,
    required this.perguntaId,
    required this.valorResposta,
    this.observacaoAvaria,
    required this.avariaDetectada,
    required this.fotosEsperadas,
  });

  factory RespostaFilaItemModel.fromJson(Map<String, dynamic> json) {
    final rawFotos = (json['fotosEsperadas'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return RespostaFilaItemModel(
      id: json['id'] as String,
      perguntaId: json['perguntaId'] as String,
      valorResposta: json['valorResposta'] as String,
      observacaoAvaria: json['observacaoAvaria'] as String?,
      avariaDetectada: json['avariaDetectada'] as bool? ?? false,
      fotosEsperadas: rawFotos.map(FotoEsperadaMetaModel.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'perguntaId': perguntaId,
        'valorResposta': valorResposta,
        'observacaoAvaria': observacaoAvaria,
        'avariaDetectada': avariaDetectada,
        'fotosEsperadas': fotosEsperadas.map((f) => f.toJson()).toList(),
      };
}

/// Representa o pacote JSON leve (Etapa 1 da Fila Offline no Hive).
class ChecklistFilaItemModel {
  final String id;
  final String templateId;
  final String templateTitulo;
  final String veiculoId;
  final String veiculoPlaca;
  final int kmVistoria;
  final String? observacoesGerais;
  final double? latitude;
  final double? longitude;
  final String realizadoEm;
  final List<RespostaFilaItemModel> respostas;
  final bool etapa1Concluida;

  const ChecklistFilaItemModel({
    required this.id,
    required this.templateId,
    required this.templateTitulo,
    required this.veiculoId,
    required this.veiculoPlaca,
    required this.kmVistoria,
    this.observacoesGerais,
    this.latitude,
    this.longitude,
    required this.realizadoEm,
    required this.respostas,
    this.etapa1Concluida = false,
  });

  ChecklistFilaItemModel copyWith({bool? etapa1Concluida}) {
    return ChecklistFilaItemModel(
      id: id,
      templateId: templateId,
      templateTitulo: templateTitulo,
      veiculoId: veiculoId,
      veiculoPlaca: veiculoPlaca,
      kmVistoria: kmVistoria,
      observacoesGerais: observacoesGerais,
      latitude: latitude,
      longitude: longitude,
      realizadoEm: realizadoEm,
      respostas: respostas,
      etapa1Concluida: etapa1Concluida ?? this.etapa1Concluida,
    );
  }

  factory ChecklistFilaItemModel.fromJson(Map<String, dynamic> json) {
    final rawRespostas = (json['respostas'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return ChecklistFilaItemModel(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      templateTitulo: json['templateTitulo'] as String? ?? 'Checklist',
      veiculoId: json['veiculoId'] as String,
      veiculoPlaca: json['veiculoPlaca'] as String? ?? '',
      kmVistoria: (json['kmVistoria'] as num).toInt(),
      observacoesGerais: json['observacoesGerais'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      realizadoEm: json['realizadoEm'] as String,
      respostas: rawRespostas.map(RespostaFilaItemModel.fromJson).toList(),
      etapa1Concluida: json['etapa1Concluida'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'templateId': templateId,
        'templateTitulo': templateTitulo,
        'veiculoId': veiculoId,
        'veiculoPlaca': veiculoPlaca,
        'kmVistoria': kmVistoria,
        'observacoesGerais': observacoesGerais,
        'latitude': latitude,
        'longitude': longitude,
        'realizadoEm': realizadoEm,
        'respostas': respostas.map((r) => r.toJson()).toList(),
        'etapa1Concluida': etapa1Concluida,
      };

  /// Contrato JSON enviado para `POST /api/v1/sync/checklists` (Etapa 1).
  Map<String, dynamic> toSyncApiPayload() => {
        'id': id,
        'templateId': templateId,
        'veiculoId': veiculoId,
        'kmVistoria': kmVistoria,
        'observacoesGerais': observacoesGerais,
        'latitude': latitude,
        'longitude': longitude,
        'realizadoEm': realizadoEm,
        'respostas': respostas.map((r) => r.toJson()).toList(),
      };
}

/// Representa uma foto comprimida na fila secundária (Etapa 2 da Fila Offline no Hive).
class FotoFilaUploadModel {
  final String id;
  final String checklistId;
  final String respostaId;
  final String capturadaEm;
  final double? latitude;
  final double? longitude;
  final String bytesJpegBase64;

  const FotoFilaUploadModel({
    required this.id,
    required this.checklistId,
    required this.respostaId,
    required this.capturadaEm,
    this.latitude,
    this.longitude,
    required this.bytesJpegBase64,
  });

  List<int> get bytesComprimidos => base64Decode(bytesJpegBase64);

  factory FotoFilaUploadModel.fromJson(Map<String, dynamic> json) {
    return FotoFilaUploadModel(
      id: json['id'] as String,
      checklistId: json['checklistId'] as String,
      respostaId: json['respostaId'] as String,
      capturadaEm: json['capturadaEm'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      bytesJpegBase64: json['bytesJpegBase64'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'checklistId': checklistId,
        'respostaId': respostaId,
        'capturadaEm': capturadaEm,
        'latitude': latitude,
        'longitude': longitude,
        'bytesJpegBase64': bytesJpegBase64,
      };
}
