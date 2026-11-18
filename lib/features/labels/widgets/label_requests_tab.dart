import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../models/label_request.dart';
import '../models/product_label.dart';
import '../providers/labels_provider.dart';
import 'label_widgets.dart';

const _offSiteColor = Color(0xFF818CF8);

class LabelRequestsTab extends ConsumerStatefulWidget {
  const LabelRequestsTab({super.key});

  @override
  ConsumerState<LabelRequestsTab> createState() => _LabelRequestsTabState();
}

class _LabelRequestsTabState extends ConsumerState<LabelRequestsTab> {
  bool _showClosed = false;

  Future<void> _update(LabelRequest request, LabelRequestStatus status) {
    return runLabelAction(
      context,
      () => ref.read(labelActionsProvider).updateRequest(request.id, status),
      status == LabelRequestStatus.done
          ? 'Talep basıldı olarak işaretlendi.'
          : 'Talep iptal edildi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(labelRequestsProvider);
    final col = context.col;

    return requests.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => ErrorStateView(
        message: 'Etiket talepleri yüklenemedi.',
        onRetry: () => ref.invalidate(labelRequestsProvider),
      ),
      data: (all) {
        final open = all.where((r) => r.isOpen).toList();
        final closed = all.where((r) => !r.isOpen).toList();
        final visible = _showClosed ? closed : open;

        return Column(
          children: [
            Container(
              color: col.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _Segment(
                      label: 'Açık',
                      count: open.length,
                      selected: !_showClosed,
                      onTap: () => setState(() => _showClosed = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Segment(
                      label: 'Tamamlanan',
                      count: closed.length,
                      selected: _showClosed,
                      onTap: () => setState(() => _showClosed = true),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: col.border),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.gold,
                backgroundColor: col.card,
                onRefresh: () async {
                  ref.invalidate(labelRequestsProvider);
                  await ref.read(labelRequestsProvider.future);
                },
                child: visible.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 60),
                          EmptyStateView(
                            message: _showClosed
                                ? 'Tamamlanan talep yok.'
                                : 'Açık etiket talebi yok.\n'
                                    'Sağ alttaki "Etiket talebi" ile oluşturun.',
                            icon: Icons.notifications_none_rounded,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final request = visible[index];
                          return _RequestCard(
                            request: request,
                            onDone: () =>
                                _update(request, LabelRequestStatus.done),
                            onCancel: () =>
                                _update(request, LabelRequestStatus.cancelled),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.gold.withValues(alpha: 0.14) : col.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.gold.withValues(alpha: 0.5) : col.border,
            ),
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.gold : col.textPrimary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onDone,
    required this.onCancel,
  });

  final LabelRequest request;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final createdAt = request.createdAt;
    final resolvedAt = request.resolvedAt;
    final reprint = request.reason == LabelRequestReason.reprint;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: request.isOpen
              ? AppTheme.gold.withValues(alpha: 0.35)
              : col.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(
                      text: reprint ? 'Yeniden basım' : 'Yeni ürün',
                      color: reprint ? AppTheme.warning : AppTheme.gold,
                    ),
                    if (!request.isOnSite)
                      const _Tag(text: 'Sitede yok', color: _offSiteColor),
                  ],
                ),
              ),
              if (createdAt != null)
                Text(
                  labelAge(createdAt),
                  style: TextStyle(color: col.textSecondary, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.productName,
            style: TextStyle(
              color: col.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            [
              request.supplierName,
              if (request.floor.isNotEmpty) 'Kat: ${request.floor}',
            ].where((v) => v.isNotEmpty).join(' · '),
            style: TextStyle(color: col.textSecondary, fontSize: 12),
          ),
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: col.border),
              ),
              child: Text(
                request.note,
                style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14, color: col.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  [
                    'Talep: ${request.createdBy.isEmpty ? '-' : request.createdBy}',
                    if (createdAt != null) formatLabelDateTime(createdAt),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: col.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
          if (request.isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text('İptal et'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onDone,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Etiket basıldı'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              [
                request.status == LabelRequestStatus.done
                    ? '✓ Basıldı'
                    : 'İptal edildi',
                if (request.resolvedBy != null) request.resolvedBy!,
                if (resolvedAt != null) formatLabelDateTime(resolvedAt),
              ].join(' · '),
              style: TextStyle(
                color: request.status == LabelRequestStatus.done
                    ? AppTheme.success
                    : col.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
