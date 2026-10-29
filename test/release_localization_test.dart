import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/l10n/app_localizations_en.dart';
import 'package:huatlui/l10n/app_localizations_zh.dart';

void main() {
  test('FX status, stale price and backup actions are translated', () {
    final en = AppLocalizationsEn();
    final zh = AppLocalizationsZh();
    for (final value in [
      en.fxSection, en.fxDashboardIndicative, en.pricesSomeStale,
      en.backupSave, en.backupRestore, en.backupReplaceWarning,
      zh.fxSection, zh.fxDashboardIndicative, zh.pricesSomeStale,
      zh.backupSave, zh.backupRestore, zh.backupReplaceWarning,
    ]) {
      expect(value.trim(), isNotEmpty);
    }
    expect(zh.fxSection, isNot(en.fxSection));
    expect(zh.backupReplaceWarning, isNot(en.backupReplaceWarning));
  });
}
