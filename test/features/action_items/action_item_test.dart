import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_review_mobile/features/action_items/domain/action_item.dart';

ActionItem buildItem({
  ActionStatus status = ActionStatus.open,
  DateTime? dueDate,
  String? assignedToId,
}) {
  return ActionItem(
    id: '1',
    title: 'Test görevi',
    status: status,
    departmentId: '10',
    dueDate: dueDate,
    assignedToId: assignedToId,
  );
}

void main() {
  group('ActionStatus.fromString', () {
    test('backend formatlarını tanır', () {
      expect(ActionStatus.fromString('Open'), ActionStatus.open);
      expect(ActionStatus.fromString('InProgress'), ActionStatus.inProgress);
      // Backend snake_case dönerse de çalışsın diye _ temizleniyor.
      expect(ActionStatus.fromString('in_progress'), ActionStatus.inProgress);
      expect(ActionStatus.fromString('RESOLVED'), ActionStatus.resolved);
    });

    test('tanımadığı değer için unknown döner', () {
      expect(ActionStatus.fromString('Beklemede'), ActionStatus.unknown);
      expect(ActionStatus.fromString(null), ActionStatus.unknown);
    });
  });

  group('ActionStatus.isClosed', () {
    test('resolved ve rejected kapalı sayılır', () {
      expect(ActionStatus.resolved.isClosed, isTrue);
      expect(ActionStatus.rejected.isClosed, isTrue);
    });

    test('open ve inProgress açık sayılır', () {
      expect(ActionStatus.open.isClosed, isFalse);
      expect(ActionStatus.inProgress.isClosed, isFalse);
    });
  });

  group('ActionItem.isOverdue', () {
    test('geçmiş tarihli açık görev gecikmiştir', () {
      final item = buildItem(
        status: ActionStatus.open,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(item.isOverdue, isTrue);
    });

    test('geçmiş tarihli ama tamamlanmış görev gecikmiş sayılmaz', () {
      // Kapanmış bir görev için "gecikti" uyarısı göstermek anlamsız.
      final item = buildItem(
        status: ActionStatus.resolved,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(item.isOverdue, isFalse);
    });

    test('gelecek tarihli görev gecikmemiştir', () {
      final item = buildItem(
        dueDate: DateTime.now().add(const Duration(days: 3)),
      );
      expect(item.isOverdue, isFalse);
    });

    test('tarihi olmayan görev gecikmemiştir', () {
      expect(buildItem(dueDate: null).isOverdue, isFalse);
    });
  });

  group('ActionItem.isAssignedTo', () {
    test('atanan kişi eşleşirse true döner', () {
      expect(buildItem(assignedToId: '3').isAssignedTo('3'), isTrue);
    });

    test('farklı kişi için false döner', () {
      expect(buildItem(assignedToId: '3').isAssignedTo('5'), isFalse);
    });

    test('atanmamış görev veya null kullanıcı için false döner', () {
      expect(buildItem(assignedToId: null).isAssignedTo('3'), isFalse);
      expect(buildItem(assignedToId: '3').isAssignedTo(null), isFalse);
      // Kritik: ikisi de null olsa bile "atanmış" sayılmamalı.
      expect(buildItem(assignedToId: null).isAssignedTo(null), isFalse);
    });
  });

  group('ActionItem.copyWithStatus', () {
    test('sadece durumu değiştirir, diğer alanları korur', () {
      final original = buildItem(
        status: ActionStatus.open,
        assignedToId: '3',
        dueDate: DateTime(2026, 1, 1),
      );

      final updated = original.copyWithStatus(ActionStatus.resolved);

      expect(updated.status, ActionStatus.resolved);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.assignedToId, original.assignedToId);
      expect(updated.dueDate, original.dueDate);
    });
  });
}