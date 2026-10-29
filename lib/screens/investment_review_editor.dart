import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/holding_record.dart';

String reviewStatusLabel(InvestmentReviewStatus status, bool zh) {
  switch (status) {
    case InvestmentReviewStatus.hold: return zh ? '持有' : 'Hold';
    case InvestmentReviewStatus.watch: return zh ? '观察' : 'Watch';
    case InvestmentReviewStatus.addCandidate: return zh ? '考虑加仓' : 'Add Candidate';
    case InvestmentReviewStatus.reduceReview: return zh ? '考虑减仓' : 'Reduce Review';
    case InvestmentReviewStatus.exitReview: return zh ? '考虑退出' : 'Exit Review';
  }
}

bool reviewDue(HoldingRecord record, DateTime now) {
  final due = record.nextReviewDate;
  if (due == null) return false;
  return DateTime(due.year, due.month, due.day).compareTo(
      DateTime(now.year, now.month, now.day)) <= 0;
}

/// User-entered labels only, not automatic investment advice.
class InvestmentReviewEditor extends StatefulWidget {
  final HoldingRecord holding;
  const InvestmentReviewEditor({super.key, required this.holding});

  @override
  State<InvestmentReviewEditor> createState() => _InvestmentReviewEditorState();
}

class _InvestmentReviewEditorState extends State<InvestmentReviewEditor> {
  late InvestmentReviewStatus _status;
  late final TextEditingController _thesis;
  late final TextEditingController _notes;
  DateTime? _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.holding.reviewStatus;
    _thesis = TextEditingController(text: widget.holding.investmentThesis ?? '');
    _notes = TextEditingController(text: widget.holding.reviewNotes ?? '');
    _date = widget.holding.nextReviewDate;
  }

  @override
  void dispose() {
    _thesis.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final dateLabel = _date == null ? (zh ? '未设日期' : 'No date') :
      '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: Text(zh ? '投资复核' : 'Investment Review')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.holding.symbol, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(zh ? '仅供个人投资记录，不会自动下单。' :
            'Personal decision journal only. No orders are placed.'),
          const SizedBox(height: 20),
          DropdownButtonFormField<InvestmentReviewStatus>(
            value: _status,
            decoration: InputDecoration(labelText: zh ? '投资状态' : 'Review status'),
            items: [
              for (final status in InvestmentReviewStatus.values)
                DropdownMenuItem(value: status,
                  child: Text(reviewStatusLabel(status, zh))),
            ],
            onChanged: (next) {
              if (next != null) setState(() => _status = next);
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _thesis,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: zh ? '投资理由' : 'Investment thesis',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: zh ? '风险条件及复核备注' : 'Risk conditions and review notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(zh ? '下次复核日期' : 'Next review date'),
            subtitle: Text(dateLabel),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final today = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? today,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          if (_date != null)
            TextButton(
              onPressed: () => setState(() => _date = null),
              child: Text(zh ? '清除复核日期' : 'Clear review date'),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : () async {
              setState(() => _saving = true);
              try {
                // Use current record to avoid overwriting a fresh price update.
                final current = repo.holdingFor(widget.holding.accountId, widget.holding.symbol);
                if (current == null) throw StateError('Holding no longer exists');
                await repo.putHolding(current.copyWith(
                  reviewStatus: _status,
                  investmentThesis: _thesis.text.trim(),
                  reviewNotes: _notes.text.trim(),
                  nextReviewDate: _date,
                  clearReviewDate: _date == null,
                ));
                if (context.mounted) Navigator.pop(context);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(zh ? '保存失败，请重试。' : 'Could not save. Please retry.'),
                  ));
                  setState(() => _saving = false);
                }
              }
            },
            child: Text(_saving ? (zh ? '保存中…' : 'Saving…') : (zh ? '保存' : 'Save')),
          ),
        ],
      ),
    );
  }
}
