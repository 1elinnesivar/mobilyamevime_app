class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.salePrice,
    required this.purchasePrice,
    required this.stock,
    required this.status,
    required this.supplierId,
    required this.supplierName,
    required this.image,
  });

  final int id;
  final String code;
  final String name;
  final num? salePrice;
  final num? purchasePrice;
  final int stock;
  final String status;
  final int? supplierId;
  final String? supplierName;
  final String? image;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _int(json['id']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      salePrice: _num(json['sale_price']),
      purchasePrice: _num(json['purchase_price']),
      stock: _int(json['stock']),
      status: (json['status'] ?? '').toString(),
      supplierId: _nullableInt(json['supplier_id']),
      supplierName: json['supplier_name']?.toString(),
      image: json['image']?.toString(),
    );
  }

  static int _int(dynamic value) => _nullableInt(value) ?? 0;

  static int? _nullableInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString());
  }

  static num? _num(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse((value ?? '').toString());
  }
}
