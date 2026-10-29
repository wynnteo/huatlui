import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/holding_record.dart';
import '../services/buy_simulator.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../widgets/currency_display.dart';

/// A scenario is strictly local to this screen: nothing is persisted.
class WhatIfBuyScreen extends StatefulWidget {
  final String accountId;
  final String symbol;
  const WhatIfBuyScreen({
    super.key,
    required this.accountId,
    required this.symbol,
  });

  @override
  State<WhatIfBuyScreen> createState() => _WhatIfBuyScreenState();
}

class _WhatIfBuyScreenState extends State<WhatIfBuyScreen> {
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _fees = TextEditingController(text: '0');

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _fees.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(zh ? '模拟买入' : 'What-if Buy')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([repo, settings, fx]),
          builder: (context, _) {
            final base = settings.baseCurrency;
            final svc = PortfolioService(fx: fx, baseCurrency: base);
            final positions = svc.positions(
              trades: repo.trades,
              dividends: repo.dividends,
              holdings: repo.holdings,
            );
            final key = HoldingRecord.keyOf(widget.accountId, widget.symbol);
            Position? holding;
            for (final p in positions) {
              if (HoldingRecord.keyOf(p.accountId, p.symbol) == key) {
                holding = p;
                break;
              }
            }
            if (holding == null || !holding.isOpen) {
              return Center(child: Text(zh
                  ? '找不到有效持仓。'
                  : 'This holding is no longer open.'));
            }
            final p = holding;
            final total = svc.summary(positions).marketValueBase;
            return AnimatedBuilder(
              animation: Listenable.merge([_quantity, _price, _fees]),
              builder: (context, _) {
                final qty = double.tryParse(_quantity.text.replaceAll(',', ''));
                final buyPrice = double.tryParse(_price.text.replaceAll(',', ''));
                final fees = double.tryParse(_fees.text.replaceAll(',', ''));
                BuyScenarioResult? result;
                String? error;
                if (_quantity.text.trim().isNotEmpty && _price.text.trim().isNotEmpty) {
                  try {
                    if (qty == null || buyPrice == null || fees == null) {
                      throw const FormatException('Invalid number');
                    }
                    result = BuySimulator(fx: fx, baseCurrency: base).calculate(
                      holding: p,
                      portfolioMarketValueBase: total,
                      scenario: BuyScenario(
                        extraQuantity: qty,
                        buyPrice: buyPrice,
                        fees: fees,
                      ),
                    );
                  } catch (_) {
                    error = zh ? '请输入有效的数量、价格及手续费。' :
                        'Enter a valid quantity, price and fee.';
                  }
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  children: [
                    Text('${p.symbol} · ${p.currency}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(zh ? '只供模拟，不会执行交易或修改持仓。'
                             : 'Simulation only — no order is placed and no data is saved.',
                        style: TextStyle(color: c.textSecondary)),
                    const SizedBox(height: 20),
                    _DataLine(zh ? '现有数量' : 'Current units', p.quantity.toStringAsFixed(4)),
                    _DataLine(zh ? '现有平均成本' : 'Current average cost',
                        CurrencyText.formatPrice(p.avgCostLocal, p.currency)),
                    _DataLine(zh ? '当前市价' : 'Current market price',
                        CurrencyText.formatPrice(p.currentPrice, p.currency)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: zh ? '拟买入数量' : 'Units to buy',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: zh ? '拟买入价格（${p.currency}）' : 'Buy price (${p.currency})',
                        hintText: p.currentPrice.toStringAsFixed(4),
                        suffixIcon: IconButton(
                          tooltip: zh ? '使用当前市价' : 'Use current market price',
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          onPressed: () => _price.text = p.currentPrice.toString(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fees,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: zh ? '手续费（${p.currency}）' : 'Fees (${p.currency})',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error, style: TextStyle(color: c.loss)),
                    ],
                    if (result != null) ...[
                      const SizedBox(height: 24),
                      Text(zh ? '模拟结果' : 'Projected position',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      _DataLine(zh ? '拟投入金额（含费用）' : 'Additional cash needed',
                          CurrencyText.formatAmount(result.addedCashLocal, p.currency)),
                      _DataLine(zh ? '新持仓数量' : 'Projected units',
                          result.newQuantity.toStringAsFixed(4)),
                      _DataLine(zh ? '新平均成本' : 'Projected average cost',
                          CurrencyText.formatPrice(result.newAverageCostLocal, p.currency)),
                      _DataLine(zh ? '预估浮动盈亏' : 'Projected unrealized P/L',
                          CurrencyText.formatSigned(result.newUnrealizedLocal, p.currency)),
                      _DataLine(zh ? '当前组合占比' : 'Current portfolio weight',
                          '${result.currentWeightPct.toStringAsFixed(2)}%'),
                      _DataLine(zh ? '模拟后组合占比' : 'Projected portfolio weight',
                          '${result.projectedWeightPct.toStringAsFixed(2)}%'),
                      const SizedBox(height: 14),
                      Text(zh
                        ? '假设投入的是组合以外的新资金，新增股份按当前市价估值。换汇使用当前参考汇率；不包含滑点、税费（填写的手续费除外）或其他持仓价格变化。'
                        : 'Assumes new money from outside the tracked portfolio. Added units are valued at the current market price and converted using reference FX rates. Excludes slippage, taxes beyond entered fees, and changes to other holdings.',
                        style: TextStyle(fontSize: 12, color: c.textSecondary)),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DataLine extends StatelessWidget {
  final String label;
  final String value;
  const _DataLine(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: context.colors.textSecondary))),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
