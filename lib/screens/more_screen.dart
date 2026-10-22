import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../services/csv_import.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_helpers.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.clearAllData),
        content: Text(t.clearAllDataConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true) await repo.clearAll();
  }

  Future<void> _importCsv(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(t.importFailed('no data'))));
        return;
      }
      final plan = CsvImporter.plan(
        csv: utf8.decode(bytes, allowMalformed: true),
        existingAccounts: repo.accounts,
        existingHoldings: repo.holdings,
        existingTrades: repo.trades,
        existingDividends: repo.dividends,
        baseCurrency: settings.baseCurrency,
        fx: fx,
      );
      if (!context.mounted) return;
      final ok = await showDialog<bool>(context: context, builder: (ctx) => _ImportPreview(plan: plan));
      if (ok != true) return;
      await repo.applyImport(plan);
      messenger.showSnackBar(SnackBar(content: Text(t.importDone)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.importFailed(e.toString()))));
    }
  }

  Future<void> _copyTemplate(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: CsvImporter.templateCsv));
    messenger.showSnackBar(SnackBar(content: Text(t.templateCopied)));
  }

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SafeArea(
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              ScreenTitle(t.navMore),

              _label(context, t.settingsTheme),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: Text(t.settingsThemeSystem), selected: settings.themeMode == ThemeMode.system, onSelected: (_) => settings.setThemeMode(ThemeMode.system)),
                  ChoiceChip(label: Text(t.settingsThemeLight), selected: settings.themeMode == ThemeMode.light, onSelected: (_) => settings.setThemeMode(ThemeMode.light)),
                  ChoiceChip(label: Text(t.settingsThemeDark), selected: settings.themeMode == ThemeMode.dark, onSelected: (_) => settings.setThemeMode(ThemeMode.dark)),
                ],
              ),

              _label(context, t.settingsLanguage),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('English'), selected: settings.locale.languageCode == 'en', onSelected: (_) => settings.setLocale(const Locale('en'))),
                  ChoiceChip(label: const Text('中文'), selected: settings.locale.languageCode == 'zh', onSelected: (_) => settings.setLocale(const Locale('zh'))),
                ],
              ),

              _label(context, t.settingsBaseCurrency),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in fx.supportedCurrencies)
                    ChoiceChip(label: Text(code), selected: settings.baseCurrency == code, onSelected: (_) => settings.setBaseCurrency(code)),
                ],
              ),

              _label(context, t.settingsData),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: () => _importCsv(context), child: Text(t.importCsv)),
                  OutlinedButton(onPressed: () => _copyTemplate(context), child: Text(t.copyCsvTemplate)),
                  OutlinedButton(onPressed: () => repo.loadDemo(), child: Text(t.loadDemoData)),
                  OutlinedButton(onPressed: () => _confirmClear(context), child: Text(t.clearAllData)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImportPreview extends StatelessWidget {
  final ImportPlan plan;
  const _ImportPreview({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    return AlertDialog(
      title: Text(t.importPreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.isEmpty)
              Text(t.importNothing)
            else
              Text(t.importSummary(plan.trades.length.toString(), plan.dividends.length.toString(), plan.newAccounts.length.toString())),
            if (plan.skippedDuplicates > 0) ...[
              const SizedBox(height: 8),
              Text(t.importSkipped(plan.skippedDuplicates.toString()), style: TextStyle(color: c.textSecondary)),
            ],
            if (plan.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(t.importErrors(plan.errors.length.toString()), style: TextStyle(color: c.loss, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              for (final e in plan.errors.take(6))
                Text('Row ${e.row}: ${e.message}', style: TextStyle(fontSize: 12, color: c.loss)),
              if (plan.errors.length > 6) Text('…', style: TextStyle(color: c.loss)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        TextButton(onPressed: plan.isEmpty ? null : () => Navigator.pop(context, true), child: Text(t.importConfirm)),
      ],
    );
  }
}
