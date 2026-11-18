enum LabelRequestStatus { open, done, cancelled }

enum LabelRequestReason { newProduct, reprint }

/// "Print a label for this product" request sent from the mobile app.
/// productId is null when the product is not on the website yet.
class LabelRequest {
  const LabelRequest({
    required this.id,
    required this.productId,
    required this.productName,
    required this.supplierId,
    required this.supplierName,
    required this.floor,
    required this.note,
    required this.reason,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.resolvedBy,
    required this.resolvedAt,
  });

  final int id;
  final int? productId;
  final String productName;
  final int? supplierId;
  final String supplierName;
  final String floor;
  final String note;
  final LabelRequestReason reason;
  final LabelRequestStatus status;
  final String createdBy;
  final DateTime? createdAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  bool get isOnSite => (productId ?? 0) > 0;
  bool get isOpen => status == LabelRequestStatus.open;

  factory LabelRequest.fromJson(Map<String, dynamic> json) {
    final productId = _int(json['product_id']);
    final supplierId = _int(json['supplier_id']);
    final resolvedBy = json['resolved_by']?.toString();
    return LabelRequest(
      id: _int(json['id']),
      productId: productId > 0 ? productId : null,
      productName: (json['product_name'] ?? '').toString(),
      supplierId: supplierId > 0 ? supplierId : null,
      supplierName: (json['supplier_name'] ?? '').toString(),
      floor: (json['floor'] ?? '').toString().trim(),
      note: (json['note'] ?? '').toString().trim(),
      reason: json['reason'] == 'reprint'
          ? LabelRequestReason.reprint
          : LabelRequestReason.newProduct,
      status: switch (json['status']) {
        'done' => LabelRequestStatus.done,
        'cancelled' => LabelRequestStatus.cancelled,
        _ => LabelRequestStatus.open,
      },
      createdBy: (json['created_by'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      resolvedBy: (resolvedBy ?? '').isEmpty ? null : resolvedBy,
      resolvedAt: DateTime.tryParse((json['resolved_at'] ?? '').toString()),
    );
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}

class LabelRequestDraft {
  const LabelRequestDraft({
    required this.productName,
    required this.supplierName,
    required this.reason,
    this.productId,
    this.supplierId,
    this.floor = '',
    this.note = '',
  });

  final int? productId;
  final String productName;
  final int? supplierId;
  final String supplierName;
  final String floor;
  final String note;
  final LabelRequestReason reason;

  Map<String, dynamic> toPayload() => {
        'product_id': productId,
        'product_name': productName.trim(),
        'supplier_id': supplierId,
        'supplier_name': supplierName.trim(),
        'floor': floor.trim(),
        'note': note.trim(),
        'reason': reason == LabelRequestReason.reprint ? 'reprint' : 'new',
      };
}

String requestStatusPayload(LabelRequestStatus status) => switch (status) {
      LabelRequestStatus.open => 'open',
      LabelRequestStatus.done => 'done',
      LabelRequestStatus.cancelled => 'cancelled',
    };
