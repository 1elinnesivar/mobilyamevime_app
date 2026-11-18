import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mobilyamevime_app/core/theme/app_theme.dart';
import 'package:mobilyamevime_app/features/labels/data/labels_repository.dart';
import 'package:mobilyamevime_app/features/labels/models/label_request.dart';
import 'package:mobilyamevime_app/features/labels/models/product_label.dart';
import 'package:mobilyamevime_app/features/labels/providers/labels_provider.dart';
import 'package:mobilyamevime_app/features/labels/screens/label_request_screen.dart';
import 'package:mobilyamevime_app/features/labels/screens/labels_screen.dart';
import 'package:mobilyamevime_app/features/labels/widgets/label_widgets.dart';
import 'package:mobilyamevime_app/features/suppliers/models/supplier.dart';

Map<String, dynamic> _labelJson(
  int id,
  String name, {
  String supplier = 'Akyol Life',
  int supplierId = 2,
  String floor = '',
  String printedAt = '2026-11-10 10:00:00',
  bool current = true,
  bool active = true,
}) {
  return {
    'label_key': 'product-$id',
    'product_id': '$id',
    'product_code': 'KOD-$id',
    'name': name,
    'supplier': supplier,
    'supplier_id': '$supplierId',
    'floor_info': floor,
    'printed_total': '100000.00',
    'printed_at': printedAt,
    'kind': 'product',
    'active': active,
    'current': current,
    'current_total': current ? 100000 : 120000,
  };
}

List<ProductLabel> _sampleLabels() => [
      _labelJson(1, 'Kapadokya Yatak Odası Takımı',
          floor: '1. Kat', printedAt: '2026-09-05 12:58:23'),
      _labelJson(2, 'Çınar Koltuk Takımı',
          floor: 'Zemin Kat',
          supplier: 'Maduca Collection',
          supplierId: 9,
          current: false),
      _labelJson(3, 'Bella Yemek Odası Takımı',
          floor: '2. Kat', printedAt: '2026-11-16 17:25:59'),
      _labelJson(4, 'Asya Genç Odası',
          supplier: 'Maduca Collection', supplierId: 9),
      _labelJson(5, 'Ilgaz Sehpa', floor: '-1 Bodrum Kat', active: false),
    ].map(ProductLabel.fromJson).toList();

/// In-memory stand-in for the labels API.
class _FakeLabelsRepository implements LabelsRepository {
  final labels = _sampleLabels().map(_labelToJson).toList();
  final requestRows = <Map<String, dynamic>>[
    {
      'id': 1,
      'product_id': null,
      'product_name': 'Lavin Yatak Odası',
      'supplier_name': 'Yeni Firma',
      'floor': '1. Kat',
      'note': 'Bugün geldi',
      'reason': 'new',
      'status': 'open',
      'created_by': 'Ayşe',
      'created_at': '2026-11-17 10:00:00',
    },
  ];

  static Map<String, dynamic> _labelToJson(ProductLabel l) => _labelJson(
        l.productId,
        l.name,
        supplier: l.supplier,
        supplierId: l.supplierId,
        floor: l.floor,
        printedAt: l.printedAt!.toIso8601String(),
        current: l.isCurrent,
        active: l.isActive,
      );

  @override
  Future<List<ProductLabel>> list() async =>
      labels.map(ProductLabel.fromJson).toList();

  @override
  Future<List<String>> floors() async => ['Zemin Kat', '1. Kat', '2. Kat'];

  @override
  Future<void> updateFloor(String key, String floor) async {
    labels.firstWhere((l) => l['label_key'] == key)['floor_info'] = floor;
  }

  @override
  Future<void> remove(String key) async {
    labels.removeWhere((l) => l['label_key'] == key);
  }

  @override
  Future<List<LabelRequest>> requests() async =>
      requestRows.map(LabelRequest.fromJson).toList();

  @override
  Future<void> createRequest(LabelRequestDraft draft) async {
    requestRows.insert(0, {
      ...draft.toPayload(),
      'id': requestRows.length + 1,
      'status': 'open',
      'created_by': 'Test',
      'created_at': '2026-11-17 12:00:00',
    });
  }

  @override
  Future<void> updateRequest(int id, LabelRequestStatus status) async {
    final request = requestRows.firstWhere((r) => r['id'] == id);
    request['status'] = requestStatusPayload(status);
    request['resolved_by'] = 'Test';
    request['resolved_at'] = '2026-11-17 13:00:00';
  }
}

Future<_FakeLabelsRepository> _pumpLabels(WidgetTester tester) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(360 * 2, 1600 * 2);
  addTearDown(tester.view.reset);

  final repository = _FakeLabelsRepository();
  final router = GoRouter(
    initialLocation: '/labels',
    routes: [
      GoRoute(path: '/labels', builder: (_, __) => const LabelsScreen()),
      GoRoute(
        path: '/label-request',
        builder: (_, state) => LabelRequestScreen(
          labelKey: state.uri.queryParameters['label'],
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        labelsRepositoryProvider.overrideWithValue(repository),
        labelSupplierSearchProvider.overrideWith((ref, query) async => [
              Supplier.fromJson({'id': 2, 'name': 'Akyol Life'}),
            ]),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  group('helpers', () {
    test('foldTurkish matches typing without Turkish characters', () {
      expect(foldTurkish('Yatak Odası ÇİĞ Şüö'), 'yatak odasi cig suo');
    });

    test('Turkish alphabetical order', () {
      final names = ['Zeta', 'Çınar', 'Cam', 'İnci', 'Ilgaz', 'Ömer', 'Oya']
        ..sort((a, b) => turkishSortKey(a).compareTo(turkishSortKey(b)));
      expect(names, ['Cam', 'Çınar', 'Ilgaz', 'İnci', 'Oya', 'Ömer', 'Zeta']);
    });

    test('floors sort naturally, empty last', () {
      final floors = ['2. Kat', '', 'Zemin Kat', '10. Kat', '-1 Bodrum Kat', '1. Kat']
        ..sort(compareFloors);
      expect(floors,
          ['-1 Bodrum Kat', 'Zemin Kat', '1. Kat', '2. Kat', '10. Kat', '']);
    });

    test('label age and date', () {
      final now = DateTime(2026, 11, 17, 9);
      expect(labelAge(DateTime(2026, 11, 17, 1), now: now), 'bugün');
      expect(labelAge(DateTime(2026, 11, 16, 23), now: now), 'dün');
      expect(labelAge(DateTime(2026, 11, 5), now: now), '12 gün önce');
      expect(labelAge(DateTime(2026, 9, 5), now: now), '2 ay önce');
      expect(formatLabelDate(DateTime(2026, 9, 5)), '5 Eyl 2026');
      expect(formatLabelDateTime(DateTime(2026, 11, 17, 9, 5)), '17 Kas 09:05');
    });

    test('label request json and draft payload', () {
      final request = LabelRequest.fromJson({
        'id': '7',
        'product_id': '0',
        'product_name': 'Lavin',
        'supplier_id': null,
        'supplier_name': 'Yeni Firma',
        'reason': 'reprint',
        'status': 'done',
        'created_at': '2026-11-17 10:00:00',
      });
      expect(request.isOnSite, isFalse);
      expect(request.reason, LabelRequestReason.reprint);
      expect(request.status, LabelRequestStatus.done);

      const draft = LabelRequestDraft(
        productName: '  Lavin  ',
        supplierName: 'Yeni Firma',
        reason: LabelRequestReason.newProduct,
        floor: ' 2. Kat ',
      );
      expect(draft.toPayload(), {
        'product_id': null,
        'product_name': 'Lavin',
        'supplier_id': null,
        'supplier_name': 'Yeni Firma',
        'floor': '2. Kat',
        'note': '',
        'reason': 'new',
      });
    });
  });

  group('LabelFilter', () {
    final labels = _sampleLabels();

    test('search is word based and diacritic insensitive', () {
      expect(const LabelFilter(query: 'odasi yatak').apply(labels).single.productId, 1);
      expect(const LabelFilter(query: 'cinar').apply(labels).single.productId, 2);
      expect(const LabelFilter(query: 'bodrum').apply(labels).single.productId, 5);
    });

    test('floor, supplier and reprint filters', () {
      expect(const LabelFilter(floor: '2. Kat').apply(labels).single.productId, 3);
      expect(const LabelFilter(floor: '').apply(labels).single.productId, 4);
      expect(const LabelFilter(supplierId: 9).apply(labels).map((l) => l.productId),
          unorderedEquals([2, 4]));
      expect(const LabelFilter(onlyReprint: true).apply(labels).single.productId, 2);
    });

    test('sorting', () {
      List<int> ids(LabelSort sort) =>
          LabelFilter(sort: sort).apply(labels).map((l) => l.productId).toList();
      expect(ids(LabelSort.newest).first, 3);
      expect(ids(LabelSort.newest).last, 1);
      expect(ids(LabelSort.name), [4, 3, 2, 5, 1]);
      expect(ids(LabelSort.floor), [5, 2, 1, 3, 4]);
    });
  });

  testWidgets('floor picker offers only managed floors', (tester) async {
    var selected = 'Eski Kat';
    Future<void> pump(List<String> floors) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => FloorPicker(
                  floors: floors,
                  selected: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        );

    await pump(['Zemin Kat', '1. Kat']);
    expect(find.byType(TextField), findsNothing); // no free text
    for (final label in ['Kat yok', 'Zemin Kat', '1. Kat', 'Eski Kat']) {
      expect(find.text(label), findsOneWidget); // legacy value stays visible
    }
    await tester.tap(find.text('1. Kat'));
    await tester.pump();
    expect(selected, '1. Kat');
    await tester.tap(find.text('Kat yok'));
    await tester.pump();
    expect(selected, '');

    await pump([]);
    expect(find.textContaining('Kat listesi boş'), findsOneWidget);
  });

  testWidgets('filters work at narrow phone width', (tester) async {
    await _pumpLabels(tester);

    expect(find.text('5 ETİKET'), findsOneWidget);
    expect(find.text('Talepler (1)'), findsOneWidget);
    expect(find.text('Güncel fiyat ₺120.000 · etiket yeniden basılmalı'),
        findsOneWidget);

    await tester.tap(find.text('Tüm firmalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maduca Collection').last);
    await tester.pumpAndSettle();
    expect(find.text('2 / 5 ETİKET'), findsOneWidget);

    // The chip row scrolls horizontally; a long supplier name pushes it right.
    await tester.ensureVisible(find.text('Yeniden basılacak').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeniden basılacak').first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 5 ETİKET'), findsOneWidget);
  });

  testWidgets('change floor and remove a label', (tester) async {
    final repository = await _pumpLabels(tester);

    await tester.tap(find.text('Asya Genç Odası'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kat bilgisini değiştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Kat').last); // suggestion chip
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(repository.labels.firstWhere((l) => l['product_id'] == '4')['floor_info'],
        '2. Kat');
    expect(find.text('Kat bilgisi: 2. Kat'), findsOneWidget); // SnackBar

    await tester.tap(find.text('Ilgaz Sehpa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Etiketi listeden kaldır'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaldır'));
    await tester.pumpAndSettle();
    expect(find.text('Ilgaz Sehpa'), findsNothing);
    expect(find.text('4 ETİKET'), findsOneWidget);
  });

  testWidgets('request for a product that is not on the website',
      (tester) async {
    final repository = await _pumpLabels(tester);

    await tester.tap(find.text('Etiket talebi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sitede olmayan ürün'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Ürün adı'), 'Lena Köşe Takımı');

    // Supplier is not in the list: type it by hand.
    await tester.tap(find.text('Firma seçin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firma listede yok, elle yaz'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Firma adı (listede yok)'), 'Lena Mobilya');
    await tester.tap(find.text('Zemin Kat').last);

    await tester.ensureVisible(find.text('Talebi gönder'));
    await tester.tap(find.text('Talebi gönder'));
    await tester.pumpAndSettle();

    final created = repository.requestRows.first;
    expect(created['product_name'], 'Lena Köşe Takımı');
    expect(created['product_id'], isNull);
    expect(created['supplier_name'], 'Lena Mobilya');
    expect(created['floor'], 'Zemin Kat');
    // Back on the labels screen, switched to the requests tab.
    expect(find.text('Talepler (2)'), findsOneWidget);
    expect(find.text('Lena Köşe Takımı'), findsOneWidget);
  });

  testWidgets('reprint request is prefilled and requests can be closed',
      (tester) async {
    final repository = await _pumpLabels(tester);

    await tester.tap(find.text('Bella Yemek Odası Takımı'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeniden basım talebi gönder'));
    await tester.pumpAndSettle();
    expect(find.text('Bella Yemek Odası Takımı'), findsOneWidget); // picked
    await tester.ensureVisible(find.text('Talebi gönder'));
    await tester.tap(find.text('Talebi gönder'));
    await tester.pumpAndSettle();

    final created = repository.requestRows.first;
    expect(created['product_id'], 3);
    expect(created['reason'], 'reprint');
    expect(created['floor'], '2. Kat');

    await tester.tap(find.text('Etiket basıldı').first);
    await tester.pumpAndSettle();
    expect(repository.requestRows.first['status'], 'done');
    expect(find.text('Talepler (1)'), findsOneWidget);
  });
}
