import '../domain/action_item.dart';

/// !!! BACKEND GELİNCE KONTROL EDİLECEK !!!
/// Rapor bölüm 7'deki alan adları snake_case (action_items tablosu),
/// ama .NET API'si camelCase JSON dönecektir: assignedTo, dueDate...
/// assignedToName backend'in join yapıp göndermesine bağlı - göndermezse null kalır.
class ActionItemDto {
  const ActionItemDto({
    required this.id,
    required this.title,
    required this.status,
    required this.departmentId,
    this.departmentName,
    this.reviewId,
    this.assignedTo,
    this.assignedToName,
    this.dueDate,
    this.reviewComment,
    this.suggestion,
  });

  final String id;
  final String title;
  final String status;
  final String departmentId;
  final String? departmentName;
  final String? reviewId;
  final String? assignedTo;
  final String? assignedToName;
  final String? dueDate;
  final String? reviewComment;
  final String? suggestion;

  factory ActionItemDto.fromJson(Map<String, dynamic> json) {
    return ActionItemDto(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      departmentId: json['departmentId']?.toString() ?? '',
      departmentName: json['departmentName'] as String?,
      reviewId: json['reviewId']?.toString(),
      assignedTo: json['assignedTo']?.toString(),
      assignedToName: json['assignedToName'] as String?,
      dueDate: json['dueDate'] as String?,
      reviewComment: json['reviewComment'] as String?,
      suggestion: json['suggestion'] as String?,
    );
  }
  static String _cleanTitle(String raw) {
    final cleaned = raw.replaceFirst(RegExp(r'^\s*\[[^\]]*\]\s*'), '').trim();
    if (cleaned.isEmpty) return raw;
    // İlk harfi büyüt - yorum metni küçük harfle başlıyor olabilir.
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  ActionItem toDomain() => ActionItem(
    id: id,
    title: _cleanTitle(title),
    status: ActionStatus.fromString(status),
    departmentId: departmentId,
    departmentName: departmentName,
    reviewId: reviewId,
    assignedToId: assignedTo,
    assignedToName: assignedToName,
    // Bozuk/eksik tarih gelirse null kalsın, çökmesin.
    dueDate: dueDate == null ? null : DateTime.tryParse(dueDate!),
    reviewComment: reviewComment,
    suggestion: suggestion,
  );
}
