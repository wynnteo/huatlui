// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'HuatLui';

  @override
  String get navDashboard => '总览';

  @override
  String get navHoldings => '持仓';

  @override
  String get navAllocation => '配置';

  @override
  String get navTransactions => '交易';

  @override
  String get navMore => '更多';

  @override
  String get totalReturn => '总回报';

  @override
  String get capitalGain => '资本利得';

  @override
  String get dividendIncome => '股息收入';

  @override
  String get portfolioValue => '组合市值';

  @override
  String get totalInvested => '总投入';

  @override
  String get recentTransactions => '最近交易';

  @override
  String get dashboardEmptyTitle => '还没有投资记录';

  @override
  String get dashboardEmptyBody => '添加第一笔买入，或加载示例数据看看 HuatLui 怎么用。';

  @override
  String get loadDemoData => '加载示例数据';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get clearAllDataConfirm => '这会永久删除本机上所有账户、持仓、交易和股息记录。';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get deleteEntryTitle => '删除这条记录？';

  @override
  String get holdingsEmpty => '目前没有持仓。';

  @override
  String get transactionsEmpty => '还没有交易记录。';

  @override
  String get allocationEmpty => '暂时没有可配置的资产。';

  @override
  String get buy => '买入';

  @override
  String get sell => '卖出';

  @override
  String get dividend => '股息';

  @override
  String get addTransaction => '添加交易';

  @override
  String get addDividend => '添加股息';

  @override
  String get groupAssetClass => '资产类别';

  @override
  String get groupAccount => '账户';

  @override
  String get groupCurrency => '币种';

  @override
  String get groupHolding => '个股';

  @override
  String get assetClassStock => '股票';

  @override
  String get assetClassEtf => 'ETF';

  @override
  String get assetClassUnitTrust => '单位信托';

  @override
  String get assetClassReit => 'REIT';

  @override
  String get assetClassBond => '债券';

  @override
  String get assetClassCash => '现金';

  @override
  String get assetClassOther => '其他';

  @override
  String get currentAllocation => '当前';

  @override
  String get targetAllocation => '目标';

  @override
  String targetPct(String pct) {
    return '目标 $pct%';
  }

  @override
  String get noTargetSet => '未设目标';

  @override
  String get concentrationRiskTitle => '集中度风险';

  @override
  String needAttention(String count) {
    return '$count 项需留意';
  }

  @override
  String concentrationRiskOverTarget(
      String label, String current, String target) {
    return '$label 占组合 $current%，高于你设的目标 $target%。';
  }

  @override
  String concentrationRiskUnderTarget(
      String label, String current, String target) {
    return '$label 占组合 $current%，低于你设的目标 $target%。';
  }

  @override
  String concentrationRiskAbsolute(String label, String current) {
    return '$label 占组合 $current%，单一持仓比例过高，存在集中度风险。';
  }

  @override
  String get settingsBaseCurrency => '基准货币';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsData => '数据';

  @override
  String shownInBaseCurrency(String currency) {
    return '以 $currency 显示';
  }

  @override
  String get addEntry => '添加记录';

  @override
  String get fieldAccount => '账户';

  @override
  String get newAccountOption => '新建账户…';

  @override
  String get fieldNewAccountName => '新账户名称';

  @override
  String get createAccountHint => '例如 Tiger Brokers';

  @override
  String get fieldSymbol => '代码';

  @override
  String get symbolHint => '例如 AAPL、D05.SI';

  @override
  String get fieldName => '名称（选填）';

  @override
  String get fieldAssetClass => '资产类别';

  @override
  String get fieldCurrency => '币种';

  @override
  String get fieldDate => '日期';

  @override
  String get fieldQuantity => '数量';

  @override
  String get fieldPrice => '单价';

  @override
  String get fieldFees => '手续费等费用';

  @override
  String get fieldGrossAmount => '股息金额（税前）';

  @override
  String get fieldWithholdingTax => '预扣税';

  @override
  String get fieldFxRate => '汇率';

  @override
  String fxRateHelp(String currency, String base) {
    return '1 $currency = ? $base。已按内置的今日汇率预填；想更精确可改成交易当天的汇率。';
  }

  @override
  String get fieldNotes => '备注（选填）';

  @override
  String get save => '保存';

  @override
  String get pickHoldingHint => '选择已有持仓';

  @override
  String get errAccountRequired => '请选择账户或输入新账户名称。';

  @override
  String get errSymbolRequired => '请输入代码。';

  @override
  String errNumber(String field) {
    return '$field请输入有效数字。';
  }

  @override
  String errOnlyHold(String qty, String symbol) {
    return '该账户里你只持有 $qty 的 $symbol。';
  }

  @override
  String get errDividendNeedsHolding => '记录股息需要选择已有的持仓。';

  @override
  String get errFxRate => '请输入有效的汇率。';

  @override
  String editHoldingTitle(String symbol) {
    return '更新 $symbol';
  }

  @override
  String currentPriceLabel(String currency) {
    return '现价（$currency）';
  }

  @override
  String get targetPctLabel => '目标占比 %（留空为不设）';

  @override
  String get holdingsTapHint => '点一下持仓可更新现价和目标占比。';

  @override
  String get importCsv => '从 CSV 导入';

  @override
  String get copyCsvTemplate => '复制 CSV 模板';

  @override
  String get templateCopied => '模板已复制，可粘贴到 Excel 或 Google Sheets。';

  @override
  String get importPreviewTitle => '准备导入';

  @override
  String importSummary(String trades, String dividends, String accounts) {
    return '$trades 笔买卖、$dividends 笔股息、$accounts 个新账户';
  }

  @override
  String importSkipped(String count) {
    return '已跳过 $count 条重复记录';
  }

  @override
  String importErrors(String count) {
    return '有 $count 行有问题，将被跳过：';
  }

  @override
  String get importNothing => '没有可导入的内容。';

  @override
  String get importConfirm => '导入';

  @override
  String get importDone => '导入完成。';

  @override
  String importFailed(String reason) {
    return '无法读取该文件：$reason';
  }
}
