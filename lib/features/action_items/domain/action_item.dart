/// Rapor bölüm 11: Open, InProgress, Resolved, Rejected
enum ActionStatus {
  open,
  inProgress,
  resolved,
  rejected,
  unknown;

  static ActionStatus fromString(String? value) {
    switch (value?.toLowerCase().replaceAll('_', '')) {
      case 'open':
        return ActionStatus.open;
      case 'inprogress':
        return ActionStatus.inProgress;
      case 'resolved':
        return ActionStatus.resolved;
      case 'rejected':
        return ActionStatus.rejected;
      default:
        return ActionStatus.unknown;
    }
  }

  /// Backend'e gönderirken. .NET enum'ları genelde PascalCase.
  String get apiValue => switch (this) {
    ActionStatus.open => 'Open',
    ActionStatus.inProgress => 'InProgress',
    ActionStatus.resolved => 'Resolved',
    ActionStatus.rejected => 'Rejected',
    ActionStatus.unknown => 'Open',
  };

  String get label => switch (this) {
    ActionStatus.open => 'Açık',
    ActionStatus.inProgress => 'Devam Ediyor',
    ActionStatus.resolved => 'Tamamlandı',
    ActionStatus.rejected => 'Reddedildi',
    ActionStatus.unknown => 'Bilinmiyor',
  };

  /// Kapalı durumlar - bunlardan sonra değişiklik beklenmiyor.
  bool get isClosed =>
      this == ActionStatus.resolved || this == ActionStatus.rejected;

  /// Mobilden seçilebilecek durumlar (unknown hariç).
  static List<ActionStatus> get selectable => const [
    ActionStatus.open,
    ActionStatus.inProgress,
    ActionStatus.resolved,
    ActionStatus.rejected,
  ];
}

/// Rapor bölüm 7: action_items tablosu.
/// id, review_id, department_id, assigned_to, title, status, due_date
class ActionItem {
  const ActionItem({
    required this.id,
    required this.title,
    required this.status,
    required this.departmentId,
    this.departmentName,
    this.reviewId,
    this.assignedToId,
    this.assignedToName,
    this.dueDate,
    this.reviewComment,
    this.suggestion,
  });

  final String id;
  final String title;
  final ActionStatus status;
  final String departmentId;
  final String? departmentName;

  /// Görevin doğduğu negatif yorum.
  final String? reviewId;

  /// Atama Angular panelinden yapılır - mobilde SALT OKUNUR.
  /// Rapor bölüm 8'de mobile açık tek güncelleme endpoint'i
  /// PATCH /action-items/{id}/status - yani sadece durum.
  final String? assignedToId;
  final String? assignedToName;

  final DateTime? dueDate;

  /// Görevin bağlamını göstermek için - saha personeli neden bu görevi
  /// yaptığını görsün diye. Backend include ederse dolar.
  final String? reviewComment;
  final String? suggestion;

  bool get isOverdue {
    if (dueDate == null || status.isClosed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool isAssignedTo(String? userId) => userId != null && assignedToId == userId;

  /// Durum güncellendiğinde yeni bir kopya üret (immutable model).
  ActionItem copyWithStatus(ActionStatus newStatus) => ActionItem(
    id: id,
    title: title,
    status: newStatus,
    departmentId: departmentId,
    departmentName: departmentName,
    reviewId: reviewId,
    assignedToId: assignedToId,
    assignedToName: assignedToName,
    dueDate: dueDate,
    reviewComment: reviewComment,
    suggestion: suggestion,
  );

  /// AI'ın önerdiği departman yanlışsa Admin/Manager düzeltebilir - kişi
  /// bazlı değil departman bazlı gidiyoruz (bkz. ActionItemRepository).
  ActionItem copyWithDepartment({
    required String departmentId,
    String? departmentName,
  }) => ActionItem(
    id: id,
    title: title,
    status: status,
    departmentId: departmentId,
    departmentName: departmentName,
    reviewId: reviewId,
    assignedToId: assignedToId,
    assignedToName: assignedToName,
    dueDate: dueDate,
    reviewComment: reviewComment,
    suggestion: suggestion,
  );
}
