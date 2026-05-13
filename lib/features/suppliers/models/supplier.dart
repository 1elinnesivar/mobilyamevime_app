class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.companyCode,
    required this.discountRate,
    required this.balance,
    required this.status,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? companyCode;
  final num? discountRate;
  final num? balance;
  final String status;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: _detailInt(json['id']),
      name: (json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      companyCode: json['company_code']?.toString(),
      discountRate: _detailNum(json['discount_rate']),
      balance: _num(json['balance']),
      status: (json['status'] ?? '').toString(),
    );
  }

  static num? _num(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse((value ?? '').toString());
  }
}

class SupplierDetail {
  const SupplierDetail({
    required this.id,
    required this.companyName,
    required this.authorizedPerson,
    required this.phone,
    required this.email,
    required this.companyCode,
    required this.priceListDate,
    required this.discountRate,
    required this.note,
    required this.logo,
    required this.currentPriceList,
    required this.priceLists,
  });

  final int id;
  final String companyName;
  final String? authorizedPerson;
  final String? phone;
  final String? email;
  final String? companyCode;
  final String? priceListDate;
  final num? discountRate;
  final String? note;
  final String? logo;
  final SupplierCurrentPriceList currentPriceList;
  final List<SupplierPriceListFile> priceLists;

  factory SupplierDetail.fromJson(Map<String, dynamic> json) {
    final current = json['current_price_list'];
    final files = json['price_lists'];

    return SupplierDetail(
      id: _detailInt(json['id']),
      companyName: (json['company_name'] ?? '').toString(),
      authorizedPerson: json['authorized_person']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      companyCode: json['company_code']?.toString(),
      priceListDate: json['price_list_date']?.toString(),
      discountRate: _detailNum(json['discount_rate']),
      note: json['note']?.toString(),
      logo: json['logo']?.toString(),
      currentPriceList: current is Map<String, dynamic>
          ? SupplierCurrentPriceList.fromJson(current)
          : const SupplierCurrentPriceList(fileName: null, url: null, exists: false),
      priceLists: files is List
          ? files
              .whereType<Map<String, dynamic>>()
              .map(SupplierPriceListFile.fromJson)
              .toList()
          : [],
    );
  }
}

class SupplierCurrentPriceList {
  const SupplierCurrentPriceList({
    required this.fileName,
    required this.url,
    required this.exists,
  });

  final String? fileName;
  final String? url;
  final bool exists;

  factory SupplierCurrentPriceList.fromJson(Map<String, dynamic> json) {
    return SupplierCurrentPriceList(
      fileName: json['file_name']?.toString(),
      url: json['url']?.toString(),
      exists: json['exists'] == true,
    );
  }
}

class SupplierPriceListFile {
  const SupplierPriceListFile({
    required this.fileName,
    required this.url,
    required this.modifiedAt,
    required this.size,
    required this.isCurrent,
  });

  final String fileName;
  final String? url;
  final String? modifiedAt;
  final int size;
  final bool isCurrent;

  factory SupplierPriceListFile.fromJson(Map<String, dynamic> json) {
    return SupplierPriceListFile(
      fileName: (json['file_name'] ?? '').toString(),
      url: json['url']?.toString(),
      modifiedAt: json['modified_at']?.toString(),
      size: _detailInt(json['size']),
      isCurrent: json['is_current'] == true,
    );
  }
}

int _detailInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString()) ?? 0;
}

num? _detailNum(dynamic value) {
  if (value is num) {
    return value;
  }
  return num.tryParse((value ?? '').toString());
}
