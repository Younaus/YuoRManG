import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/layout/app_sidebar.dart';
import 'package:yourmang/features/auth/domain/entities/app_user.dart';
import 'package:yourmang/features/tasks/domain/entities/task_status.dart';
import 'package:yourmang/features/tasks/presentation/widgets/task_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_app.dart';

const _user = AppUser(uid: 'u1', email: 'ali@test.dev', displayName: 'Ali Veli');
const desktop = Size(1280, 800);
const tablet = Size(800, 900);
const phone = Size(390, 844);

void main() {
  late FakeCategoryRepository categories;
  late FakeTaskRepository tasks;

  setUp(() {
    categories = FakeCategoryRepository(sampleCategories());
    tasks = FakeTaskRepository(tasks: sampleTasks(), categories: categories);
  });

  Future<void> pump(WidgetTester tester, Size size) => tester.pumpApp(
        auth: FakeAuthRepository(initialUser: _user),
        tasks: tasks,
        categories: categories,
        size: size,
      );

  group('responsive iskelet', () {
    testWidgets('masaüstü: sabit yan menü + kategori ağacı, alt menü yok', (tester) async {
      await pump(tester, desktop);
      expect(find.byType(AppSidebar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('tasks.newTask')), findsOneWidget);
      for (final name in ['İş', 'Projeler', 'Alpha', 'Kişisel']) {
        expect(find.descendant(of: find.byType(AppSidebar), matching: find.text(name)), findsOneWidget);
      }
      expect(find.byType(TaskCard), findsNWidgets(4));
    });

    testWidgets('tablet: NavigationRail', (tester) async {
      await pump(tester, tablet);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(AppSidebar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('telefon: alt menü + FAB, kategoriler çekmecede', (tester) async {
      await pump(tester, phone);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const Key('tasks.fab')), findsOneWidget);
      expect(find.byType(AppSidebar), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(Drawer), matching: find.text('Kişisel')));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing, reason: 'seçimden sonra çekmece kapanır');
      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Market alışverişi'), findsOneWidget);
    });

    testWidgets('pencere daralınca düzen değişir', (tester) async {
      await pump(tester, desktop);
      expect(find.byType(AppSidebar), findsOneWidget);
      tester.view.physicalSize = phone * tester.view.devicePixelRatio;
      await tester.pumpAndSettle();
      expect(find.byType(AppSidebar), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(TaskCard), findsNWidgets(4), reason: 'içerik korunur');
    });
  });

  group('kategori seçimi', () {
    testWidgets('üst kategori seçilince alt kategorilerin görevleri de listelenir, başlık değişir', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.descendant(of: find.byType(AppSidebar), matching: find.text('İş')));
      await tester.pumpAndSettle();
      expect(find.byType(TaskCard), findsNWidgets(2));
      expect(find.text('Sprint planlaması'), findsOneWidget);
      expect(find.text('API dokümantasyonu'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(AppSidebar), matching: find.text('Alpha')));
      await tester.pumpAndSettle();
      expect(find.text('İş › Projeler'), findsOneWidget, reason: 'breadcrumb');
      expect(find.byType(TaskCard), findsOneWidget);
    });
  });

  group('görev kartı', () {
    testWidgets('başlık, açıklamanın ilk satırı ve durum etiketi görünür', (tester) async {
      await pump(tester, desktop);
      final card = find.ancestor(of: find.text('Sprint planlaması'), matching: find.byType(TaskCard));
      expect(find.descendant(of: card, matching: find.text('Hedefleri belirle')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('ikinci satır')), findsNothing);
      expect(find.descendant(of: card, matching: find.text('Yapılacak')), findsOneWidget);
    });

    testWidgets('daire butonu görevi tamamlar ve geri alır', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.byTooltip('Tamamlandı olarak işaretle').first);
      await tester.pumpAndSettle();
      expect(tasks.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.done);

      await tester.tap(find.byTooltip('Tamamlanmadı olarak işaretle').first);
      await tester.pumpAndSettle();
      expect(tasks.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.todo);
    });

    testWidgets('durum etiketi menüsünden "Devam ediyor" seçilir', (tester) async {
      await pump(tester, desktop);
      final card = find.ancestor(of: find.text('Sprint planlaması'), matching: find.byType(TaskCard));
      await tester.tap(find.descendant(of: card, matching: find.text('Yapılacak')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Devam ediyor').last);
      await tester.pumpAndSettle();
      expect(tasks.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.inProgress);
    });

    testWidgets('sağa kaydırma tamamlar, kart listede kalır', (tester) async {
      await pump(tester, phone);
      await tester.drag(find.text('Sprint planlaması'), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(tasks.tasks.firstWhere((t) => t.id == 't1').status, TaskStatus.done);
      expect(find.text('Sprint planlaması'), findsOneWidget);
    });

    testWidgets('sola kaydırma siler; "Geri al" geri getirir', (tester) async {
      await pump(tester, phone);
      await tester.drag(find.text('Sprint planlaması'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Sprint planlaması'), findsNothing);
      expect(find.text('"Sprint planlaması" silindi'), findsOneWidget);

      await tester.tap(find.text('Geri al'));
      await tester.pumpAndSettle();
      expect(find.text('Sprint planlaması'), findsOneWidget);
      expect(tasks.tasks.any((t) => t.id == 't1'), isTrue, reason: 'sunucuya silme gitmedi');
    });

    testWidgets('sola kaydırma: geri alınmazsa süre sonunda sunucudan silinir', (tester) async {
      await pump(tester, phone);
      await tester.drag(find.text('Sprint planlaması'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(tasks.tasks.any((t) => t.id == 't1'), isTrue);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(tasks.tasks.any((t) => t.id == 't1'), isFalse);
      expect(find.text('Sprint planlaması'), findsNothing);
    });
  });

  group('arama ve filtre', () {
    testWidgets('arama kutusu debounce sonrası sunucuya q gönderir ve listeyi daraltır', (tester) async {
      await pump(tester, desktop);
      final before = tasks.queries.length;
      await tester.enterText(find.byKey(const Key('tasks.search')), 'mar');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('tasks.search')), 'MARKET');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(tasks.queries.length, before + 1, reason: 'hızlı yazımda tek istek (debounce)');
      expect(tasks.queries.last.search, 'MARKET');
      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Market alışverişi'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('tasks.search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
    });

    testWidgets('durum çipi listeyi filtreler', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tamamlandı'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Market alışverişi'), findsOneWidget);
    });
  });

  group('Clarity Workspace', () {
    testWidgets('genel bakış kartı tamamlanma oranını gösterir; filtre/aramada gizlenir', (tester) async {
      await pump(tester, desktop);
      final overview = find.byKey(const Key('tasks.overview'));
      expect(overview, findsOneWidget);
      expect(find.descendant(of: overview, matching: find.textContaining('1/4 görev tamamlandı')), findsOneWidget);
      expect(find.descendant(of: overview, matching: find.text('%25')), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tamamlandı'));
      await tester.pumpAndSettle();
      expect(overview, findsNothing, reason: 'durum filtresinde oran anlamsız');
    });

    testWidgets('masaüstü yan menüsündeki "Yeni görev" ayarlardayken de görevler sekmesine döner', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.byKey(const Key('sidebar.settings')));
      await tester.pumpAndSettle();
      expect(find.byType(TaskCard), findsNothing);

      await tester.tap(find.byKey(const Key('tasks.newTask')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byKey(const Key('taskForm.title')), findsOneWidget);
    });

    testWidgets('masaüstü başlığındaki tema düğmesi açık/koyu arasında geçiş yapar', (tester) async {
      await pump(tester, desktop);
      final context = tester.element(find.byType(TaskCard).first);
      expect(Theme.of(context).brightness, Brightness.light);
      await tester.tap(find.byKey(const Key('tasks.themeToggle')));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(find.byType(TaskCard).first)).brightness, Brightness.dark);
    });
  });

  group('görev oluşturma', () {
    testWidgets('masaüstü: diyalog, doğrulama ve seçili kategoriyle oluşturma', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.descendant(of: find.byType(AppSidebar), matching: find.text('Kişisel')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tasks.newTask')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.byKey(const Key('taskForm.submit')));
      await tester.pumpAndSettle();
      expect(find.text('Başlık gerekli'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('taskForm.title')), 'Fatura öde');
      await tester.enterText(find.byKey(const Key('taskForm.description')), 'Elektrik\nve su');
      await tester.tap(find.descendant(of: find.byKey(const Key('taskForm.status')), matching: find.text('Devam ediyor')));
      await tester.tap(find.byKey(const Key('taskForm.submit')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      final created = tasks.tasks.last;
      expect(created.title, 'Fatura öde');
      expect(created.description, 'Elektrik\nve su');
      expect(created.status, TaskStatus.inProgress);
      expect(created.categoryId, 'personal', reason: 'seçili kategori varsayılan');
      expect(find.text('Fatura öde'), findsOneWidget);
    });

    testWidgets('masaüstü: tarih seçici ile bitiş tarihi', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.byKey(const Key('tasks.newTask')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('taskForm.title')), 'Tarihli');
      await tester.tap(find.byKey(const Key('taskForm.dueDate')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Tamam').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('taskForm.submit')));
      await tester.pumpAndSettle();

      final due = tasks.tasks.last.dueDate!;
      final now = DateTime.now();
      expect((due.year, due.month, due.day, due.hour, due.minute), (now.year, now.month, now.day, 23, 59));
    });

    testWidgets('telefon: FAB alt sayfa (bottom sheet) açar', (tester) async {
      await pump(tester, phone);
      await tester.tap(find.byKey(const Key('tasks.fab')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byKey(const Key('taskForm.title')), findsOneWidget);
    });

    testWidgets('karta dokununca düzenleme formu dolu açılır ve kaydeder', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.text('Sprint planlaması'));
      await tester.pumpAndSettle();
      expect(find.text('Görevi düzenle'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('taskForm.title')), 'Sprint planlaması v2');
      await tester.tap(find.byKey(const Key('taskForm.submit')));
      await tester.pumpAndSettle();
      expect(tasks.tasks.firstWhere((t) => t.id == 't1').title, 'Sprint planlaması v2');
      expect(find.text('Sprint planlaması v2'), findsOneWidget);
    });
  });

  group('kategori yönetimi', () {
    testWidgets('yan menüden yeni kategori oluşturulur', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.byKey(const Key('categories.add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('categoryForm.name')), 'Okul');
      await tester.tap(find.byKey(const Key('categoryForm.submit')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(AppSidebar), matching: find.text('Okul')), findsOneWidget);
    });

    testWidgets('aynı seviyede aynı ad hata mesajı verir', (tester) async {
      await pump(tester, desktop);
      await tester.tap(find.byKey(const Key('categories.add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('categoryForm.name')), 'iş');
      await tester.tap(find.byKey(const Key('categoryForm.submit')));
      await tester.pumpAndSettle();
      expect(find.text('Bu seviyede aynı adda bir kategori zaten var.'), findsOneWidget);
    });
  });
}
