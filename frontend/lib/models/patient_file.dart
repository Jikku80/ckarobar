/// Mirrors the file records served by dentaldb's `/files` endpoints
/// (see components/files/PatientFilesPanel.tsx on the web app).
library;

const List<String> kFileCategories = ['xray', 'report', 'document', 'image', 'other'];

class PatientFile {
  final String id;
  final String patientId;
  final String originalName;
  final String mimeType;
  final int size;
  final String category;
  final String? uploadedByName;
  final String createdAt;

  const PatientFile({
    required this.id,
    required this.patientId,
    required this.originalName,
    required this.mimeType,
    required this.size,
    required this.category,
    this.uploadedByName,
    required this.createdAt,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf' || originalName.toLowerCase().endsWith('.pdf');
  bool get isPreviewable => isImage || isPdf;

  factory PatientFile.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploadedBy'] as Map<String, dynamic>?;
    return PatientFile(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ?? '',
      originalName: json['originalName'] as String? ?? json['name'] as String? ?? 'file',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'other',
      uploadedByName: uploader != null
          ? ['${uploader['firstName'] ?? ''}', '${uploader['lastName'] ?? ''}'].join(' ').trim()
          : null,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}