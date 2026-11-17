/// Türkçe kurallarıyla büyük harfe çevirir: "i" → "İ", "ı" → "I" ("Kategoriler" → "KATEGORİLER").
/// Dart'ın `toUpperCase()` yerel ayardan bağımsızdır ve "i"yi "I" yapar.
String toUpperTr(String text) => text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
