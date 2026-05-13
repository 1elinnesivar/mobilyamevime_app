import 'product.dart';

class ProductDetail extends Product {
  const ProductDetail({
    required super.id,
    required super.code,
    required super.name,
    required super.salePrice,
    required super.purchasePrice,
    required super.stock,
    required super.status,
    required super.supplierId,
    required super.supplierName,
    required super.image,
    required this.categoryName,
    required this.description,
    required this.images,
    required this.modules,
    required this.supplierDiscountRate,
  });

  final String? categoryName;
  final String? description;
  final List<String> images;
  final List<ProductModule> modules;
  final num? supplierDiscountRate;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final base = Product.fromJson(json);
    final category = json['category'];
    final supplier = json['supplier'];
    final images = json['images'];
    final modules = json['modules'];

    return ProductDetail(
      id: base.id,
      code: base.code,
      name: base.name,
      salePrice: base.salePrice,
      purchasePrice: base.purchasePrice,
      stock: base.stock,
      status: base.status,
      supplierId: base.supplierId,
      supplierName: base.supplierName,
      image: base.image,
      categoryName: category is Map<String, dynamic>
          ? category['name']?.toString()
          : null,
      description: json['description']?.toString(),
      images: images is List ? images.map((e) => e.toString()).toList() : [],
      modules: modules is List
          ? modules
              .whereType<Map<String, dynamic>>()
              .map(ProductModule.fromJson)
              .toList()
          : [],
      supplierDiscountRate: supplier is Map<String, dynamic>
          ? _num(supplier['discount_rate'])
          : null,
    );
  }

  static num? _num(dynamic value) {
    if (value is num) {
      return value;
    }
    return num.tryParse((value ?? '').toString());
  }
}

class ProductModule {
  const ProductModule({
    required this.moduleId,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.quantity,
    required this.salePrice,
    required this.purchasePrice,
    required this.discountRate,
    required this.discountAmount,
    required this.discountedPurchasePrice,
    required this.width,
    required this.height,
    required this.depth,
  });

  final int moduleId;
  final String? name;
  final String? nameEn;
  final String? icon;
  final int? quantity;
  final num? salePrice;
  final num? purchasePrice;
  final num? discountRate;
  final num? discountAmount;
  final num? discountedPurchasePrice;
  final String? width;
  final String? height;
  final String? depth;

  factory ProductModule.fromJson(Map<String, dynamic> json) {
    return ProductModule(
      moduleId: _int(json['module_id']),
      name: json['name']?.toString(),
      nameEn: json['name_en']?.toString(),
      icon: json['icon']?.toString(),
      quantity: _nullableInt(json['quantity']),
      salePrice: _num(json['sale_price']),
      purchasePrice: _num(json['purchase_price']),
      discountRate: _num(json['discount_rate']),
      discountAmount: _num(json['discount_amount']),
      discountedPurchasePrice: _num(json['discounted_purchase_price']),
      width: json['width']?.toString(),
      height: json['height']?.toString(),
      depth: json['depth']?.toString(),
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
