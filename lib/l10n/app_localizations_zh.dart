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

  @override
  String get navInsights => '洞察';

  @override
  String get navSettings => '设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsRegion => '地区';

  @override
  String get settingsThemeAuto => '自动';

  @override
  String get insightsHighlights => '要点';

  @override
  String get insightsMore => '更多洞察';

  @override
  String get insightsEmpty => '添加几笔交易后即可查看洞察。';

  @override
  String get tabPerformance => '表现';

  @override
  String get tabIncome => '收入';

  @override
  String get returnByHolding => '各持仓资本收益';

  @override
  String get investedByMonth => '每月投入';

  @override
  String get dividendsByMonth => '每月股息';

  @override
  String get byHolding => '按持仓';

  @override
  String get breakdown => '明细';

  @override
  String get unrealisedGain => '未实现收益';

  @override
  String get realisedGain => '已实现收益';

  @override
  String get feesPaid => '已付手续费';

  @override
  String get holdingsInProfit => '盈利持仓';

  @override
  String winRateValue(String count, String total) {
    return '$count / $total';
  }

  @override
  String get dividendsTtm => '过去 12 个月';

  @override
  String get yieldOnCost => '成本收益率';

  @override
  String get incomeEmpty => '暂无股息记录。';

  @override
  String insightTopContributor(String symbol, String amount, String share) {
    return '$symbol 对资本收益贡献最大：$amount，占总盈利的 $share%。';
  }

  @override
  String insightBiggestDrag(String symbol, String amount) {
    return '$symbol 是拖累资本收益最多的持仓：$amount。';
  }

  @override
  String insightConcentration(String count, String pct) {
    return '前 $count 大持仓占投资组合的 $pct%。';
  }

  @override
  String insightDividends(String amount, String yieldPct) {
    return '今年以来的股息为 $amount，按成本计算收益率为 $yieldPct%。';
  }

  @override
  String insightCurrency(String pct, String currency) {
    return '投资组合的 $pct% 以 $currency 持有。';
  }

  @override
  String insightFees(String amount, String pct) {
    return '已支付手续费 $amount，占累计投入的 $pct%。';
  }

  @override
  String get rangeAll => '全部';

  @override
  String get chartValueVsCost => '市值与成本';

  @override
  String get chartValue => '市值';

  @override
  String get chartCost => '成本';

  @override
  String get chartNote => '历史市值按今日汇率计算。基金的走势会随每次刷新价格逐步补全。';

  @override
  String get chartNeedsData => '历史数据还不够。在总览或持仓页下拉即可刷新价格。';

  @override
  String get chartTotal => '合计';

  @override
  String get dividendsYoY => '今年与去年对比';

  @override
  String get incomeSources => '收入来源';

  @override
  String get othersLabel => '其他';

  @override
  String pricesUpdated(String when) {
    return '价格更新于 $when';
  }

  @override
  String get pricesNever => '价格尚未更新';

  @override
  String get pricesUpdating => '正在更新价格…';

  @override
  String pricesRefreshResult(String updated, String failed) {
    return '已更新 $updated 个，失败 $failed 个';
  }

  @override
  String get settingsPrices => '价格';

  @override
  String get refreshPrices => '刷新价格';

  @override
  String get assetClassCrypto => '加密货币';

  @override
  String get exportCsv => '导出 CSV';

  @override
  String get exportEmpty => '暂无可导出的数据。';

  @override
  String exportDone(String count) {
    return '已导出 $count 行。';
  }

  @override
  String get exportCopied => '无法打开保存窗口，已将 CSV 复制到剪贴板。';

  @override
  String get filterDate => '日期';

  @override
  String get filterType => '类型';

  @override
  String get filterBroker => '券商';

  @override
  String get filterClass => '资产类别';

  @override
  String get filterClear => '清除';

  @override
  String get rangeAllTime => '全部时间';

  @override
  String get rangeThisMonth => '本月';

  @override
  String get rangeLast30 => '最近 30 天';

  @override
  String get rangeThisYear => '今年';

  @override
  String get rangeLastYear => '去年';

  @override
  String get rangeCustom => '自定义范围…';

  @override
  String get filterNoMatch => '没有符合筛选条件的交易。';

  @override
  String filterBrokersCount(String count) {
    return '$count 个券商';
  }

  @override
  String filterClassesCount(String count) {
    return '$count 个类别';
  }

  @override
  String filterTransactions(String count) {
    return '共 $count 笔';
  }

  @override
  String get summaryBought => '买入';

  @override
  String get summarySold => '卖出';

  @override
  String get priceNotUpdated => '价格未更新';

  @override
  String priceAsOf(String date) {
    return '价格截至 $date';
  }

  @override
  String pricesFailedList(String symbols) {
    return '无法获取价格：$symbols';
  }

  @override
  String get lockedTitle => 'HuatLui 已锁定';

  @override
  String get unlockButton => '解锁';

  @override
  String get unlockReason => '解锁 HuatLui 以查看你的投资组合';

  @override
  String get settingsSecurity => '安全';

  @override
  String get settingsLock => '生物识别解锁';

  @override
  String get settingsLockHelp => '使用指纹、面容或手机的屏幕锁。应用在后台超过 30 秒后会再次锁定。';

  @override
  String get lockUnavailable => '请先在手机上设置指纹、面容或屏幕锁。';

  @override
  String get filterAll => '全部';

  @override
  String get byAssetClass => '按资产类别';

  @override
  String incomeYearLabel(String year) {
    return '$year 年股息';
  }

  @override
  String incomeLastYear(String amount) {
    return '去年 $amount';
  }

  @override
  String incomeEmptyYear(String year) {
    return '$year 年没有股息记录。';
  }

  @override
  String get chartHowLink => '这是怎么计算的？';

  @override
  String get chartHowTitle => '市值与成本的计算方式';

  @override
  String get chartHowCostTitle => '成本（虚线）';

  @override
  String get chartHowCostBody =>
      '你仍持有的资产的买入成本。每笔买入加上 数量 × 价格 + 手续费，并按该笔交易当时的汇率换算。卖出时按比例扣减成本（平均成本法），因此已全部卖出的持仓不再计入。';

  @override
  String get chartHowValueTitle => '市值（实线）';

  @override
  String get chartHowValueBody =>
      '每一天：当天持有的数量（根据你的交易重建）× 当天收盘价，并按今天的汇率换算。周末和假日沿用上一个收盘价。基金没有历史价格，因此按你的交易价格逐步变化，并使用你开始刷新价格之后获取的价格。';

  @override
  String get chartHowGapTitle => '两条线之间的差距';

  @override
  String get chartHowGapBody => '这就是你的未实现盈亏。股息和已卖出实现的收益不在此图中，请查看下方“明细”和“收入”页。';

  @override
  String get settingsAbout => '关于';

  @override
  String get aboutVersion => '版本';

  @override
  String latestPrice(String price) {
    return '最新价 $price';
  }

  @override
  String get editEntry => '编辑记录';

  @override
  String get errBreaksHoldings => '这样会使之后的某笔卖出数量超过当时的持仓。请先修改或删除那笔卖出。';

  @override
  String get holdingDetails => '详情';

  @override
  String get detailMarketValue => '市值';

  @override
  String get detailUnits => '数量';

  @override
  String get detailAvgPrice => '平均成本价';

  @override
  String get detailLatestPrice => '最新价';

  @override
  String get detailCost => '成本';

  @override
  String get detailDividends => '已收股息';

  @override
  String get detailBroker => '券商';

  @override
  String get detailTarget => '目标占比';

  @override
  String get detailNotSet => '未设置';

  @override
  String get detailTransactions => '交易记录';

  @override
  String get detailEmpty => '此持仓暂无交易记录。';

  @override
  String get fxSection => '汇率';

  @override
  String get fxSource => '汇率数据来源';

  @override
  String get fxDaily => 'Frankfurter（每日）';

  @override
  String get fxAsOf => '汇率数据日期';

  @override
  String get fxCached => '（缓存）';

  @override
  String get fxIndicative => '仅供参考';

  @override
  String get fxRefresh => '刷新汇率';

  @override
  String get fxRefreshing => '更新中…';

  @override
  String get fxUpdated => '汇率已更新';

  @override
  String get fxRefreshFailed => '汇率更新失败，已保留缓存数据。';

  @override
  String get fxFailedCached => '汇率刷新失败，当前显示缓存汇率。';

  @override
  String get fxFailedIndicative => '汇率刷新失败，当前显示参考汇率。';

  @override
  String get fxDashboardIndicative => '汇率：离线参考值（并非实时市场数据）';

  @override
  String get fxDashboardCached => '汇率：缓存数据，日期';

  @override
  String get fxDashboardReference => '汇率：每日参考汇率，日期';

  @override
  String get pricesSomeStale => '部分价格需要更新';

  @override
  String get backupSave => '保存完整备份（JSON）';

  @override
  String get backupRestore => '恢复完整备份（JSON）';

  @override
  String get backupSaveDialog => '保存 HuatLui 备份';

  @override
  String get backupSaved => '备份已保存，请妥善保管。';

  @override
  String get backupSaveFailed => '备份失败：';

  @override
  String get backupRestoreTitle => '恢复投资组合备份？';

  @override
  String get backupReplaceWarning => '这将覆盖本设备现有的投资组合数据。';

  @override
  String get backupAccounts => '账户';

  @override
  String get backupHoldings => '持仓';

  @override
  String get backupTrades => '交易';

  @override
  String get backupDividends => '股息';

  @override
  String get backupRestoreWarning => '建议先备份当前数据。设备锁定设置不会更改。';

  @override
  String get backupReplace => '覆盖并恢复';

  @override
  String get backupRestored => '投资组合备份已恢复。';

  @override
  String get backupRestoreFailed => '恢复失败：';
}
