import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/layout/app_sidebar.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/categories/domain/entities/category_tree.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

const _user = AppUser(uid: 'u1', email: 'ali@test.dev');
const _desktop = Size(1280, 800);
const _phone = Size(390, 844);

/// İş > Projeler > Alpha, Kişisel
void main() {
  late FakeCategoryRepository categories;

  setUp(() => categories = FakeCategoryRepository(sampleCategories()));

  Future<void> pump(WidgetTester tester, Size size) => tester.pumpApp(
        auth: FakeAuthRepository(initialUser: _user),
        categories: categories,
        tasks: FakeTaskRepository(tasks: sampleTasks(), categories: categories),
        size: size,
      );

  Finder inSidebar(String text) => find.descendant(of: find.byType(AppSidebar), matching: find.text(text));

  Future<void> openMenu(WidgetTester tester, String categoryName) async {
    // Menü butonu hover/seçim ile görünür; uzun basma her cihazda açar.
    await tester.longPress(inSidebar(categoryName));
    await tester.pumpAndSettle();
  }

  group('CategoryTree.canMoveTo / moveTargetsFor', () {
    late CategoryTree tree;
    setUp(() => tree = categories.tree);

    test('kendisi ve alt dalı hedef olamaz', () {
      expect(tree.canMoveTo('work', 'alpha'), isFalse);
      expect(tree.canMoveTo('work', 'work'), isFalse);
      expect(tree.canMoveTo('alpha', 'personal'), isTrue);
      expect(tree.canMoveTo('alpha', null), isTrue);
      expect(tree.canMoveTo('alpha', 'missing'), isFalse);
    });

    test('taşıma seçenekleri alt dalı içermez', () {
      expect(tree.moveTargetsFor('projects').map((f) => f.category.id), ['work', 'personal']);
    });
  });

  group('düzenleme diyaloğu', () {
    testWidgets('yeniden adlandırma', (tester) async {
      await pump(tester, _desktop);
      await openMenu(tester, 'Kişisel');
      await tester.tap(find.byKey(const Key('category.menu.edit')));
      await tester.pumpAndSettle();
      expect(find.text('Kategoriyi düzenle'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('categoryForm.name')), 'Ev');
      await tester.tap(find.byKey(const Key('categoryForm.submit')));
      await tester.pumpAndSettle();
      expect(inSidebar('Ev'), findsOneWidget);
      expect(inSidebar('Kişisel'), findsNothing);
      expect(categories.tree['personal']!.name, 'Ev');
    });

    testWidgets('üst kategori seçimiyle taşıma; alt dal seçeneklerde yok', (tester) async {
      await pump(tester, _desktop);
      await openMenu(tester, 'Projeler');
      await tester.tap(find.byKey(const Key('category.menu.edit')));
      await tester.pumpAndSettle();

      // Mevcut üst: İş. Açılır listede Alpha (kendi alt dalı) olmamalı.
      await tester.tap(find.text('İş').last);
      await tester.pumpAndSettle();
      final menu = find.byType(Scrollable).last;
      expect(find.descendant(of: menu, matching: find.text('Alpha')), findsNothing);
      expect(find.descendant(of: menu, matching: find.text('Kişisel')), findsOneWidget);

      await tester.tap(find.descendant(of: menu, matching: find.text('Kişisel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('categoryForm.submit')));
      await tester.pumpAndSettle();

      expect(categories.tree['projects']!.parentId, 'personal');
      expect(categories.tree.pathTo('alpha').map((c) => c.name), ['Kişisel', 'Projeler', 'Alpha'],
          reason: 'alt dal kategoriyle birlikte taşınır');
    });

    testWidgets('hedef seviyede aynı ad varsa hata gösterilir', (tester) async {
      await pump(tester, _desktop);
      await openMenu(tester, 'Kişisel');
      await tester.tap(find.byKey(const Key('category.menu.edit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('categoryForm.name')), 'iş');
      await tester.tap(find.byKey(const Key('categoryForm.submit')));
      await tester.pumpAndSettle();
      expect(find.text('Bu seviyede aynı adda bir kategori zaten var.'), findsOneWidget);
    });

    testWidgets('telefonda Kategoriler sekmesinden de düzenlenebilir', (tester) async {
      await pump(tester, _phone);
      await tester.tap(find.byIcon(Icons.folder_outlined));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category.menu.edit')), findsOneWidget);
    });
  });

  group('sürükle-bırak (masaüstü)', () {
    Future<void> dragOnto(WidgetTester tester, Finder from, Finder to, {bool expectRootZone = false}) async {
      final gesture = await tester.startGesture(tester.getCenter(from), kind: PointerDeviceKind.mouse);
      await tester.pump();
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      if (expectRootZone) expect(find.byKey(const Key('categories.rootDrop')), findsOneWidget);
      await gesture.moveTo(tester.getCenter(to));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('kategoriyi başka bir kategorinin üzerine bırakınca altına taşınır', (tester) async {
      await pump(tester, _desktop);
      await dragOnto(tester, inSidebar('Alpha'), inSidebar('Kişisel'));
      expect(categories.tree['alpha']!.parentId, 'personal');
      expect(find.text('"Alpha" "Kişisel" altına taşındı'), findsOneWidget);
    });

    testWidgets('"En üst seviyeye taşı" alanı köke taşır', (tester) async {
      await pump(tester, _desktop);
      await dragOnto(
        tester,
        inSidebar('Alpha'),
        find.byKey(const Key('categories.rootDrop')),
        expectRootZone: true,
      );
      expect(categories.tree['alpha']!.parentId, isNull);
      expect(find.byKey(const Key('categories.rootDrop')), findsNothing, reason: 'sürükleme bitince gizlenir');
    });

    testWidgets('üst kategori kendi alt kategorisine bırakılamaz', (tester) async {
      await pump(tester, _desktop);
      await dragOnto(tester, inSidebar('İş'), inSidebar('Alpha'));
      expect(categories.tree['work']!.parentId, isNull);
      expect(categories.tree.pathTo('alpha').map((c) => c.id), ['work', 'projects', 'alpha']);
    });

    testWidgets('kök kategori için "en üst seviye" alanı gösterilmez', (tester) async {
      await pump(tester, _desktop);
      final gesture = await tester.startGesture(tester.getCenter(inSidebar('İş')), kind: PointerDeviceKind.mouse);
      await tester.pump();
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(find.byKey(const Key('categories.rootDrop')), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
