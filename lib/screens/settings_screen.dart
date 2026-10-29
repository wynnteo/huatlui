import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../services/csv_export.dart';
import '../services/csv_import.dart';
import '../services/lock_service.dart';
import '../services/portfolio_backup.dart';
import '../theme/app_colors.dart';
import '../widgets/ui_helpers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      prices.refreshAll(); // imported prices are only placeholders: fetch real ones now
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.importFailed(e.toString()))));
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final count = repo.trades.length + repo.dividends.length;
    if (count == 0) {
      messenger.showSnackBar(SnackBar(content: Text(t.exportEmpty)));
      return;
    }
    final csv = CsvExporter.build(
      trades: repo.trades,
      dividends: repo.dividends,
      holdings: repo.holdings,
      accounts: repo.accounts,
    );
    try {
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: t.exportCsv,
        fileName: 'huatlui_${fmtDate(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );
      if (saved != null) messenger.showSnackBar(SnackBar(content: Text(t.exportDone(count.toString()))));
    } catch (_) {
      // No file dialog on this device: fall back to the clipboard.
      await Clipboard.setData(ClipboardData(text: csv));
      messenger.showSnackBar(SnackBar(content: Text(t.exportCopied)));
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backup = PortfolioBackup(
        accounts: repo.accounts,
        holdings: repo.holdings,
        trades: repo.trades,
        dividends: repo.dividends,
        priceHistory: repo.priceHistory,
        baseCurrency: settings.baseCurrency,
        locale: settings.locale.languageCode,
        themeMode: settings.themeMode.name,
      );
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Save HuatLui backup',
        fileName: 'huatlui_backup_${fmtDate(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(backup.encode())),
      );
      if (saved != null) {
        messenger.showSnackBar(const SnackBar(content: Text('Backup saved. Keep it in a secure location.')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) throw const FormatException('No backup file data');
      final backup = PortfolioBackup.decode(utf8.decode(bytes));
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore portfolio backup?'),
          content: Text(
            'This will REPLACE your current portfolio data on this device.\n\n'
            'Accounts: ${backup.accounts.length}\n'
            'Holdings: ${backup.holdings.length}\n'
            'Trades: ${backup.trades.length}\n'
            'Dividends: ${backup.dividends.length}\n\n'
            'Create and save a backup of your current portfolio first. '
            'Device lock preferences will not be changed.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Replace & restore')),
          ],
        ),
      );
      if (confirmed != true) return;
      await repo.restoreBackup(backup);
      await settings.setBaseCurrency(backup.baseCurrency);
      await settings.setLocale(Locale(backup.locale));
      await settings.setThemeMode(ThemeMode.values.byName(backup.themeMode));
      if (context.mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Portfolio backup restored successfully.')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _refreshPrices(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final r = await prices.refreshAll();
    if (r == null) return;
    var text = t.pricesRefreshResult(r.updated.toString(), r.failed.toString());
    if (r.failedSymbols.isNotEmpty) {
      final shown = r.failedSymbols.take(4).join(', ') + (r.failedSymbols.length > 4 ? ' …' : '');
      text += '\n${t.pricesFailedList(shown)}';
    }
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  /// Turning the lock on (or off) needs one successful check first, so you
  /// can't lock yourself out with a setup that doesn't work.
  Future<void> _toggleLock(BuildContext context, bool want) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (want && !await LockService.isSupported()) {
      messenger.showSnackBar(SnackBar(content: Text(t.lockUnavailable)));
      return;
    }
    final ok = await LockService.authenticate(t.unlockReason);
    if (ok) await settings.setLockEnabled(want);
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.settingsBaseCurrency, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const SizedBox(height: 8),
                for (final code in fx.supportedCurrencies)
                  InkWell(
                    onTap: () {
                      settings.setBaseCurrency(code);
                      Navigator.pop(ctx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(child: Text(code, style: TextStyle(fontSize: 15, color: c.textPrimary))),
                          if (settings.baseCurrency == code) Icon(Icons.check, size: 18, color: c.accentText),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([settings, prices, fx]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              ScreenTitle(t.navSettings),

              SectionLabel(t.settingsAppearance, padding: const EdgeInsets.only(top: 8, bottom: 4)),
              const HairlineDivider(),
              _SettingRow(
                title: t.settingsTheme,
                trailing: AppSegmented(
                  labels: [t.settingsThemeAuto, t.settingsThemeLight, t.settingsThemeDark],
                  selected: modes.indexOf(settings.themeMode),
                  onChanged: (i) => settings.setThemeMode(modes[i]),
                ),
              ),

              SectionLabel(t.settingsRegion),
              const HairlineDivider(),
              _SettingRow(
                title: t.settingsLanguage,
                trailing: AppSegmented(
                  labels: const ['English', '中文'],
                  selected: settings.locale.languageCode == 'zh' ? 1 : 0,
                  onChanged: (i) => settings.setLocale(Locale(i == 1 ? 'zh' : 'en')),
                ),
              ),
              _SettingRow(title: t.settingsBaseCurrency, value: settings.baseCurrency, onTap: () => _pickCurrency(context)),

              SectionLabel(t.settingsSecurity),
              const HairlineDivider(),
              _SettingRow(
                title: t.settingsLock,
                trailing: Switch(value: settings.lockEnabled, onChanged: (v) => _toggleLock(context, v)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(t.settingsLockHelp, style: TextStyle(fontSize: 12, height: 1.4, color: c.textTertiary)),
              ),

              SectionLabel(t.settingsPrices),
              const HairlineDivider(),
              _SettingRow(
                title: t.refreshPrices,
                value: prices.refreshing ? t.pricesUpdating : null,
                onTap: prices.refreshing ? null : () => _refreshPrices(context),
              ),

              SectionLabel('Exchange rates'),
              const HairlineDivider(),
              _SettingRow(
                title: 'FX data source',
                value: 'Frankfurter (daily)',
              ),
              _SettingRow(
                title: 'FX rates as of',
                value: fx.hasLiveData && fx.asOf != null
                    ? '${fx.asOf!.year}-${fx.asOf!.month.toString().padLeft(2, '0')}-${fx.asOf!.day.toString().padLeft(2, '0')}${fx.isStale ? ' (cached)' : ''}'
                    : 'Indicative only',
              ),
              _SettingRow(
                title: 'Refresh exchange rates',
                value: fx.refreshing ? 'Updating…' : null,
                onTap: fx.refreshing ? null : () async {
                  final ok = await fx.refresh(force: true);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'FX rates updated' : 'FX update failed. Cached rates retained.'),
                  ));
                },
              ),
              if (fx.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  child: Text('FX: last refresh failed; showing ${fx.hasLiveData ? 'cached' : 'indicative'} values.',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
                ),

              SectionLabel(t.settingsData),
              const HairlineDivider(),
              _SettingRow(title: 'Save full backup (JSON)', onTap: () => _exportBackup(context)),
              _SettingRow(title: 'Restore full backup (JSON)', onTap: () => _restoreBackup(context)),
              _SettingRow(title: t.importCsv, onTap: () => _importCsv(context)),
              _SettingRow(title: t.exportCsv, onTap: () => _exportCsv(context)),
              _SettingRow(title: t.clearAllData, titleColor: c.loss, onTap: () => _confirmClear(context)),

              SectionLabel(t.settingsAbout),
              const HairlineDivider(),
              const _VersionRow(),
            ],
          );
        },
      ),
    );
  }
}

/// App version, read from pubspec.yaml (`version: 0.1.0+1` shows as "0.1.0 (1)").
class _VersionRow extends StatefulWidget {
  const _VersionRow();

  @override
  State<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends State<_VersionRow> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snap) {
        final v = snap.data;
        return _SettingRow(title: t.aboutVersion, value: v == null ? '' : '${v.version} (${v.buildNumber})');
      },
    );
  }
}

/// One line in a settings list: title on the left; a value, a control or a
/// chevron on the right; hairline underneath.
class _SettingRow extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  const _SettingRow({required this.title, this.value, this.trailing, this.onTap, this.titleColor});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: trailing != null ? 10 : 15),
            child: Row(
              children: [
                Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: titleColor ?? c.textPrimary))),
                if (value != null) Text(value!, style: TextStyle(fontSize: 15, color: c.textSecondary)),
                if (trailing != null) trailing!,
                if (onTap != null && trailing == null) Icon(Icons.chevron_right, size: 20, color: c.textTertiary),
              ],
            ),
          ),
        ),
        const HairlineDivider(),
      ],
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
