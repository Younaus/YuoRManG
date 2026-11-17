import 'package:flutter_test/flutter_test.dart';
import 'package:yourmang/core/utils/text_case.dart';

void main() {
  test('Türkçe büyük harf: i → İ, ı → I', () {
    expect(toUpperTr('Kategoriler'), 'KATEGORİLER');
    expect(toUpperTr('Hiyerarşi özeti'), 'HİYERARŞİ ÖZETİ');
    expect(toUpperTr('ılık çay'), 'ILIK ÇAY');
    expect(toUpperTr('YouRManG'), 'YOURMANG');
  });
}
