import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

void main() {
  final tree = FakeCategoryRepository(sampleCategories()).tree;

  test('ön-sıralı düz liste ve derinlikler', () {
    expect(tree.flattened.map((f) => '${f.depth}:${f.category.name}'), ['0:İş', '1:Projeler', '2:Alpha', '0:Kişisel']);
  });

  test('pathTo kökten yaprağa', () {
    expect(tree.pathTo('alpha').map((c) => c.id), ['work', 'projects', 'alpha']);
    expect(tree.pathTo('missing'), isEmpty);
  });

  test('subtreeIds kendisi dahil tüm torunlar', () {
    expect(tree.subtreeIds('work'), ['work', 'projects', 'alpha']);
    expect(tree.subtreeIds('personal'), ['personal']);
    expect(tree['alpha']!.name, 'Alpha');
    expect(tree[null], isNull);
  });
}
