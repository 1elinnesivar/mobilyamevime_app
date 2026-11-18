/// A printed shop label from my-admin (urun_etiket_durum + panel_label_records).
class ProductLabel {
  const ProductLabel({
    required this.key,
    required this.productId,
    required this.productCode,
    required this.name,
    required this.supplier,
    required this.supplierId,
    required this.floor,
    required this.printedTotal,
    required this.printedAt,
    required this.isCustom,
    required this.isActive,
    required this.isCurrent,
    required this.currentTotal,
  });

  final String key;
  final int productId;
  final String? productCode;
  final String name;
  final String supplier;
  final int supplierId;
  final String floor;
  final num printedTotal;
  final DateTime? printedAt;
  final bool isCustom;
  final bool isActive;

  /// False when the product price changed after printing.
  final bool isCurrent;
  final num currentTotal;

  bool get hasFloor => floor.trim().isNotEmpty;
  bool get needsReprint => !isCurrent;

  factory ProductLabel.fromJson(Map<String, dynamic> json) {
    final code = json['product_code']?.toString();
    return ProductLabel(
      key: (json['label_key'] ?? '').toString(),
      productId: _int(json['product_id']),
      productCode: (code ?? '').isEmpty ? null : code,
      name: (json['name'] ?? '').toString(),
      supplier: (json['supplier'] ?? '').toString(),
      supplierId: _int(json['supplier_id']),
      floor: (json['floor_info'] ?? '').toString().trim(),
      printedTotal: _num(json['printed_total']),
      printedAt: DateTime.tryParse((json['printed_at'] ?? '').toString()),
      isCustom: json['kind'] == 'custom',
      isActive: _bool(json['active']),
      isCurrent: _bool(json['current']),
      currentTotal: _num(json['current_total']),
    );
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static num _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString()) ?? 0;
  }

  static bool _bool(dynamic value) =>
      value == true || value == 1 || value == '1' || value == 'true';
}

enum LabelSort { newest, name, supplier, floor }

/// Client-side filtering; the whole label list is small enough to load once.
class LabelFilter {
  const LabelFilter({
    this.query = '',
    this.floor,
    this.supplierId,
    this.onlyReprint = false,
    this.sort = LabelSort.newest,
  });

  final String query;

  /// null = all floors, '' = labels without floor info.
  final String? floor;
  final int? supplierId;
  final bool onlyReprint;
  final LabelSort sort;

  LabelFilter copyWith({
    String? query,
    String? Function()? floor,
    int? Function()? supplierId,
    bool? onlyReprint,
    LabelSort? sort,
  }) {
    return LabelFilter(
      query: query ?? this.query,
      floor: floor != null ? floor() : this.floor,
      supplierId: supplierId != null ? supplierId() : this.supplierId,
      onlyReprint: onlyReprint ?? this.onlyReprint,
      sort: sort ?? this.sort,
    );
  }

  List<ProductLabel> apply(List<ProductLabel> labels) {
    final words = foldTurkish(query)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final result = labels.where((label) {
      if (floor != null && label.floor != floor) return false;
      if (supplierId != null && label.supplierId != supplierId) return false;
      if (onlyReprint && !label.needsReprint) return false;
      if (words.isEmpty) return true;
      final haystack = foldTurkish(
          '${label.name} ${label.productCode ?? ''} ${label.supplier} ${label.floor}');
      return words.every(haystack.contains);
    }).toList();

    int byName(ProductLabel a, ProductLabel b) =>
        turkishSortKey(a.name).compareTo(turkishSortKey(b.name));
    int byDate(ProductLabel a, ProductLabel b) =>
        (b.printedAt ?? DateTime(0)).compareTo(a.printedAt ?? DateTime(0));

    result.sort(switch (sort) {
      LabelSort.newest => byDate,
      LabelSort.name => byName,
      LabelSort.supplier => (a, b) {
          final c = turkishSortKey(a.supplier)
              .compareTo(turkishSortKey(b.supplier));
          return c != 0 ? c : byName(a, b);
        },
      LabelSort.floor => (a, b) {
          final c = compareFloors(a.floor, b.floor);
          return c != 0 ? c : byName(a, b);
        },
    });
    return result;
  }
}

/// Lowercases and strips Turkish diacritics so "yatak odasi" finds "Odası".
String foldTurkish(String input) {
  const map = {
    'ç': 'c', 'Ç': 'c', 'ğ': 'g', 'Ğ': 'g', 'ı': 'i', 'I': 'i', 'İ': 'i',
    'ö': 'o', 'Ö': 'o', 'ş': 's', 'Ş': 's', 'ü': 'u', 'Ü': 'u',
  };
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    buffer.write(map[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

/// Sort key following the Turkish alphabet (c < ç, ı < i, o < ö ...).
String turkishSortKey(String input) {
  const order = 'abcçdefgğhıijklmnoöprsştuüvyz';
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    final lower = switch (char) {
      'I' => 'ı',
      'İ' => 'i',
      _ => char.toLowerCase(),
    };
    final index = order.indexOf(lower);
    buffer.write(index >= 0
        ? String.fromCharCode(0x100 + index)
        : lower);
  }
  return buffer.toString();
}

/// Orders floors naturally: Bodrum < Zemin/Giriş < 1. Kat < 2. Kat;
/// labels without floor info go last.
int compareFloors(String a, String b) {
  if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
  final rank = _floorRank(a).compareTo(_floorRank(b));
  return rank != 0 ? rank : turkishSortKey(a).compareTo(turkishSortKey(b));
}

num _floorRank(String floor) {
  final folded = foldTurkish(floor);
  if (folded.contains('bodrum')) return -1;
  if (folded.contains('zemin') || folded.contains('giris')) return 0;
  final number = RegExp(r'-?\d+').firstMatch(folded);
  if (number != null) return int.parse(number.group(0)!);
  return 1000;
}

const _months = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

String formatLabelDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// "17 Kas 14:05"
String formatLabelDateTime(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.day} ${_months[date.month - 1]} '
      '${two(date.hour)}:${two(date.minute)}';
}

/// "bugün", "dün", "12 gün önce", "3 ay önce".
String labelAge(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  if (days <= 0) return 'bugün';
  if (days == 1) return 'dün';
  if (days < 30) return '$days gün önce';
  if (days < 365) return '${days ~/ 30} ay önce';
  return '${days ~/ 365} yıl önce';
}
