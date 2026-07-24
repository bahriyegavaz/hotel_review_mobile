import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../action_items/domain/action_item.dart';
import '../../action_items/presentation/action_items_controller.dart';

/// Dashboard'da gösterilecek "en acil" görevler.
///
/// Yeni bir backend çağrısı YAPMAZ - zaten yüklenmiş aksiyon listesini
/// (actionItemsControllerProvider) süzer. Böylece dashboard ve görevler
/// ekranı aynı veriyi paylaşır, çift istek atılmaz.
///
/// Öncelik sırası:
///   1. Gecikmiş ve hâlâ açık görevler (en kritik)
///   2. Diğer açık/devam eden görevler
/// Kapanmış görevler (Resolved/Rejected) gösterilmez - yapılacak bir şey yok.
final urgentActionItemsProvider = Provider<AsyncValue<List<ActionItem>>>((ref) {
  final itemsAsync = ref.watch(actionItemsControllerProvider);

  return itemsAsync.whenData((items) {
    final open = items.where((i) => !i.status.isClosed).toList()
      ..sort((a, b) {
        // Gecikmiş olanlar en üstte.
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        // Sonra tarihi yakın olanlar.
        final aDate = a.dueDate;
        final bDate = b.dueDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    // Dashboard'da en fazla 2 tanesini göster - sadece bir önizleme.
    return open.take(2).toList();
  });
});
