enum DocumentType {
  aadhaar,
  pan,
  udyam,
  gst,
  bankStatement,
  passbook,
  businessLicense,
}

enum DocumentStatus { pending, verifying, verified }

extension DocumentTypeExt on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.aadhaar:
        return 'Aadhaar Card';
      case DocumentType.pan:
        return 'PAN Card';
      case DocumentType.udyam:
        return 'Udyam Registration';
      case DocumentType.gst:
        return 'GST Certificate';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.passbook:
        return 'Bank Passbook';
      case DocumentType.businessLicense:
        return 'Business License';
    }
  }

  String get description {
    switch (this) {
      case DocumentType.aadhaar:
        return 'Identity proof issued by UIDAI';
      case DocumentType.pan:
        return 'Permanent Account Number card';
      case DocumentType.udyam:
        return 'MSME/Udyam registration certificate';
      case DocumentType.gst:
        return 'Goods & Services Tax certificate';
      case DocumentType.bankStatement:
        return 'Last 6 months bank statement';
      case DocumentType.passbook:
        return 'Bank passbook with recent entries';
      case DocumentType.businessLicense:
        return 'Municipal or trade license';
    }
  }

  bool get isMandatory {
    switch (this) {
      case DocumentType.aadhaar:
      case DocumentType.pan:
        return true;
      default:
        return false;
    }
  }

  String get jsonValue => name;

  static DocumentType fromJson(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.aadhaar,
    );
  }
}

extension DocumentStatusExt on DocumentStatus {
  String get label {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.verifying:
        return 'Verifying...';
      case DocumentStatus.verified:
        return 'Verified';
    }
  }

  String get jsonValue => name;

  static DocumentStatus fromJson(String value) {
    return DocumentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentStatus.pending,
    );
  }
}

class DocumentModel {
  final String id;
  final String name;
  final DocumentType type;
  final DocumentStatus status;
  final DateTime? uploadDate;
  final String? filePath;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.uploadDate,
    this.filePath,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    DocumentType? type,
    DocumentStatus? status,
    DateTime? uploadDate,
    String? filePath,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      uploadDate: uploadDate ?? this.uploadDate,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.jsonValue,
    'status': status.jsonValue,
    'uploadDate': uploadDate?.toIso8601String(),
    'filePath': filePath,
  };

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
    id: json['id'] as String,
    name: json['name'] as String,
    type: DocumentTypeExt.fromJson(json['type'] as String),
    status: DocumentStatusExt.fromJson(json['status'] as String),
    uploadDate: json['uploadDate'] != null
        ? DateTime.parse(json['uploadDate'] as String)
        : null,
    filePath: json['filePath'] as String?,
  );
}
