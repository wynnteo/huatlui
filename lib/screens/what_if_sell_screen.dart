import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/holding_record.dart';
import '../services/portfolio_service.dart';
import '../services/sell_simulator.dart';
import '../theme/app_colors.dart';
import '../widgets/currency_display.dart';

class WhatIfSellScreen extends StatefulWidget {
  final String accountId;
  final String symbol;

  const WhatIfSellScreen({
    super.key,
    required this.accountId,
    required this.symbol,
  });

  @override
  State<WhatIfSellScreen> createState() => _WhatIfSellScreenState();
}

class _WhatIfSellScreenState extends State<WhatIfSellScreen> {
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
      appBar: AppBar(title: Text(zh ? '模拟卖出盈亏' : 'What-if Sell / P&L')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([repo, settings]),
          builder: (context, _) {
            final key = HoldingRecord.keyOf(widget.accountId, widget.symbol);
            Position? holding;
            for (final p in PortfolioService(fx: fx, baseCurrency: settings.baseCurrency)
                .positions(trades: repo.trades, dividends: repo.dividends, holdings: repo.holdings)) {
              if (HoldingRecord.keyOf(p.accountId, p.symbol) == key) {
                holding = p;
                break;
              }
            }
            if (holding == null || !holding.isOpen) {
              return Center(child: Text(zh ? '没有可卖出的持仓。' : 'No open position to sell.'));
            }
            final p = holding;
            return AnimatedBuilder(
              animation: Listenable.merge([_quantity, _price, _fees]),
              builder: (context, _) {
                final q = double.tryParse(_quantity.text.replaceAll(',', '').trim());
                final salePrice = double.tryParse(_price.text.replaceAll(',', '').trim());
                final fee = double.tryParse(_fees.text.replaceAll(',', '').trim());
                SellScenarioResult? result;
                String? error;
                if (_quantity.text.trim().isNotEmpty && _price.text.trim().isNotEmpty) {
                  if (q == null || salePrice == null || fee == null) {
                    error = zh ? '请输入有效的数量、价格及费用。' : 'Enter valid quantity, price and fees.';
                  } else {
                    try {
                      result = const SellSimulator().calculate(
                        holding: p, scenario: SellScenario(quantity: q, price: salePrice, fees: fee),
                      );
                    } catch (_) {
                      error = zh
                        ? '卖出数量须大于零且不超过持仓；价格须为正数，费用不能为负数。'
                        : 'Sell units must be positive and within holdings; price must be positive and fees non-negative.';
                    }
                  }
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  children: [
                    Text('${p.symbol} · ${p.currency}',
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(zh ? '仅供模拟，不会执行交易或更改资产。' :
                      'Simulation only. No trade is placed or saved.',
                      style: TextStyle(color: c.textSecondary)),
                    const SizedBox(height: 20),
                    _ResultLine(zh ? '持有数量' : 'Units held', _units(p.quantity)),
                    _ResultLine(zh ? '平均持仓成本' : 'Average cost',
                      CurrencyText.formatPrice(p.avgCostLocal, p.currency)),
                    _ResultLine(zh ? '当前市价' : 'Latest market price',
                      p.currentPrice > 0
                        ? CurrencyText.formatPrice(p.currentPrice, p.currency)
                        : '—'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: zh ? '拟卖出数量' : 'Units to sell',
                        suffixIcon: TextButton(
                          onPressed: () => _quantity.text = p.quantity.toString(),
                          child: Text(zh ? '全部' : 'All'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: zh ? '拟卖出单价（${p.currency}）' : 'Sell price (${p.currency})',
                        suffixIcon: p.currentPrice > 0
                          ? IconButton(
                              tooltip: zh ? '使用当前市价' : 'Use latest price',
                              icon: const Icon(Icons.auto_fix_high_outlined),
                              onPressed: () => _price.text = p.currentPrice.toString(),
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fees,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: zh ? '卖出费用（${p.currency}）' : 'Selling fees (${p.currency})',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error, style: TextStyle(color: c.loss)),
                    ],
                    if (result != null) ...[
                      const SizedBox(height: 24),
                      Text(zh ? '预计卖出结果' : 'Projected sale',
                        style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Text(CurrencyText.formatSigned(result.profitLoss, p.currency),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: result.profitLoss < 0 ? c.loss : c.textPrimary,
                          fontWeight: FontWeight.bold,
                        )),
                      Text(zh ? '预计本次已实现盈亏（${result.profitLossPct.toStringAsFixed(2)}%）' :
                        'Estimated realized P/L on this sale (${result.profitLossPct.toStringAsFixed(2)}%)',
                        style: TextStyle(color: c.textSecondary)),
                      const SizedBox(height: 18),
                      _ResultLine(zh ? '卖出总金额' : 'Gross proceeds',
                        CurrencyText.formatAmount(result.grossProceeds, p.currency)),
                      _ResultLine(zh ? '扣除手续费后收入' : 'Net sale proceeds',
                        CurrencyText.formatAmount(result.netProceeds, p.currency)),
                      _ResultLine(zh ? '卖出股份对应成本' : 'Cost basis sold',
                        CurrencyText.formatAmount(result.allocatedCost, p.currency)),
                      _ResultLine(zh ? '本次盈亏平衡价（含费用）' : 'Break-even price (with fees)',
                        CurrencyText.formatPrice(result.breakEvenPrice, p.currency)),
                      _ResultLine(zh ? '卖出后剩余数量' : 'Remaining units',
                        _units(result.remainingQuantity)),
                      _ResultLine(zh ? '剩余持仓成本' : 'Remaining cost',
                        CurrencyText.formatAmount(result.remainingCost, p.currency)),
                      _ResultLine(zh ? '剩余平均成本' : 'Remaining average cost',
                        result.remainingQuantity > 0
                          ? CurrencyText.formatPrice(result.remainingAverageCost, p.currency)
                          : '—'),
                      const SizedBox(height: 16),
                      Text(zh
                        ? '按 HuatLui 当前持仓的加权平均成本计算，只显示本次假设卖出的盈亏；不包含历史已实现盈亏、股息、汇率变动或未输入的税费。'
                        : 'Uses HuatLui’s weighted-average cost for currently held shares. Sale P/L excludes previous realized gains, dividends, FX movements and unentered taxes/fees.',
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

  String _units(double value) {
    final raw = value.toStringAsFixed(6);
    return raw.replaceFirst(RegExp(r'\\.?0+$'), '');
  }
}

class _ResultLine extends StatelessWidget {
  final String label;
  final String value;
  const _ResultLine(this.label, this.value);

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
