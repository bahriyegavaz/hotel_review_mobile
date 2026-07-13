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
      reviewId: json['reviewId']?.toString(),
      assignedTo: json['assignedTo']?.toString(),
      assignedToName: json['assignedToName'] as String?,
      dueDate: json['dueDate'] as String?,
      reviewComment: json['reviewComment'] as String?,
      suggestion: json['suggestion'] as String?,
    );
  }

  ActionItem toDomain() => ActionItem(
        id: id,
        title: title,
        status: ActionStatus.fromString(status),
        departmentId: departmentId,
        reviewId: reviewId,
        assignedToId: assignedTo,
        assignedToName: assignedToName,
        // Bozuk/eksik tarih gelirse null kalsın, çökmesin.
        dueDate: dueDate == null ? null : DateTime.tryParse(dueDate!),
        reviewComment: reviewComment,
        suggestion: suggestion,
      );
}