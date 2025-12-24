package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.kylin.finance.dto.AccountBalanceDTO;
import com.kylin.finance.dto.BalanceSheetDTO;
import com.kylin.finance.dto.BalanceSheetExportRow;
import com.kylin.finance.dto.CashFlowDTO;
import com.kylin.finance.dto.CashFlowExportRow;
import com.kylin.finance.dto.TrialBalanceDTO;
import com.kylin.finance.dto.TrialBalanceExportRow;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.entity.FinSplit;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.mapper.FinAccountMapper;
import com.kylin.finance.mapper.FinSplitMapper;
import com.kylin.finance.mapper.FinTransactionMapper;
import com.kylin.finance.service.IAccountingService;
import com.kylin.finance.service.IReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 报表服务实现
 */
@Service
public class ReportServiceImpl implements IReportService {
    
    @Autowired
    private FinAccountMapper accountMapper;
    
    @Autowired
    private FinTransactionMapper transactionMapper;
    
    @Autowired
    private FinSplitMapper splitMapper;
    
    @Autowired
    private IAccountingService accountingService;
    
    @Override
    public BalanceSheetDTO generateBalanceSheet(LocalDate reportDate) {
        BalanceSheetDTO sheet = new BalanceSheetDTO();
        sheet.setReportDate(reportDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd")));
        
        // 获取所有科目余额
        List<AccountBalanceDTO> balances = accountingService.calculateAllAccountBalances(reportDate);
        
        // 资产类科目
        List<BalanceSheetDTO.BalanceSheetItemDTO> assets = new ArrayList<>();
        BigDecimal totalAssets = BigDecimal.ZERO;
        
        // 负债类科目
        List<BalanceSheetDTO.BalanceSheetItemDTO> liabilities = new ArrayList<>();
        BigDecimal totalLiabilities = BigDecimal.ZERO;
        
        // 所有者权益类科目
        List<BalanceSheetDTO.BalanceSheetItemDTO> equity = new ArrayList<>();
        BigDecimal totalEquity = BigDecimal.ZERO;
        
        // 计算净利润：收入类科目余额 - 费用类科目余额
        BigDecimal totalIncome = BigDecimal.ZERO;  // 收入类科目余额总和
        BigDecimal totalExpense = BigDecimal.ZERO; // 费用类科目余额总和
        
        // 记录"本年利润"科目的原始余额（如果存在）
        BigDecimal originalCurrentYearProfitBalance = BigDecimal.ZERO;
        AccountBalanceDTO currentYearProfitBalanceDTO = null;
        
        // 按科目类型分类
        // 处理空列表情况：如果 balances 为空或 null，直接返回空报表
        if (balances == null || balances.isEmpty()) {
            sheet.setAssets(assets);
            sheet.setTotalAssets(BigDecimal.ZERO);
            sheet.setLiabilities(liabilities);
            sheet.setTotalLiabilities(BigDecimal.ZERO);
            sheet.setEquity(equity);
            sheet.setTotalEquity(BigDecimal.ZERO);
            sheet.setTotalLiabilitiesAndEquity(BigDecimal.ZERO);
            return sheet;
        }
        
        for (AccountBalanceDTO balance : balances) {
            // 空指针检查
            if (balance == null || balance.getAccountType() == null) {
                continue;
            }
            
            String accountType = balance.getAccountType();
            
            // 如果是"本年利润"科目，记录其原始余额
            if ("EQUITY".equals(accountType) && 
                ("4103".equals(balance.getAccountCode()) || 
                 (balance.getAccountName() != null && balance.getAccountName().contains("本年利润")))) {
                BigDecimal balanceValue = balance.getBalance();
                if (balanceValue != null) {
                    originalCurrentYearProfitBalance = balanceValue;
                    currentYearProfitBalanceDTO = balance;
                }
                continue; // 跳过，稍后单独处理
            }
            
            BalanceSheetDTO.BalanceSheetItemDTO item = new BalanceSheetDTO.BalanceSheetItemDTO();
            item.setAccountCode(balance.getAccountCode());
            item.setAccountName(balance.getAccountName());
            
            // 空指针检查：balance.getBalance() 可能为 null
            BigDecimal balanceValue = balance.getBalance();
            if (balanceValue == null) {
                balanceValue = BigDecimal.ZERO;
            }
            // 显示时使用绝对值（报表上通常显示正数）
            item.setAmount(balanceValue.abs());
            
            // 累加时使用实际余额值（带符号），以正确处理反向余额
            // 资产类：余额为正（借方余额）时增加资产，余额为负（贷方余额，如银行透支）时减少资产
            // 负债类：余额为正（贷方余额）时增加负债，余额为负（借方余额）时减少负债
            // 权益类：余额为正（贷方余额）时增加权益，余额为负（借方余额）时减少权益
            if ("ASSET".equals(accountType)) {
                assets.add(item);
                totalAssets = totalAssets.add(balanceValue);
            } else if ("LIABILITY".equals(accountType)) {
                liabilities.add(item);
                totalLiabilities = totalLiabilities.add(balanceValue);
            } else if ("EQUITY".equals(accountType)) {
                equity.add(item);
                totalEquity = totalEquity.add(balanceValue);
            } else if ("INCOME".equals(accountType)) {
                // 收入类：余额 = 贷方 - 借方，余额为正数表示收入
                totalIncome = totalIncome.add(balanceValue);
            } else if ("EXPENSE".equals(accountType)) {
                // 费用类：余额 = 借方 - 贷方，余额为正数表示费用
                totalExpense = totalExpense.add(balanceValue);
            }
        }
        
        // 计算净利润 = 收入 - 费用
        // 注意：收入类余额为正数（贷方余额），费用类余额为正数（借方余额）
        // 净利润 = 收入余额 - 费用余额
        BigDecimal netProfit = totalIncome.subtract(totalExpense);
        
        // 处理"本年利润"科目：使用计算出的净利润
        if (currentYearProfitBalanceDTO != null) {
            // 如果"本年利润"科目已存在，更新其金额为净利润
            BalanceSheetDTO.BalanceSheetItemDTO currentYearProfitItem = new BalanceSheetDTO.BalanceSheetItemDTO();
            currentYearProfitItem.setAccountCode(currentYearProfitBalanceDTO.getAccountCode());
            currentYearProfitItem.setAccountName(currentYearProfitBalanceDTO.getAccountName());
            currentYearProfitItem.setAmount(netProfit.abs());
            equity.add(currentYearProfitItem);
            // 更新所有者权益合计：减去原来的余额，加上新的净利润
            totalEquity = totalEquity.subtract(originalCurrentYearProfitBalance).add(netProfit);
        } else if (netProfit.compareTo(BigDecimal.ZERO) != 0) {
            // 如果"本年利润"科目不存在，但净利润不为零，创建新项目
            BalanceSheetDTO.BalanceSheetItemDTO currentYearProfitItem = new BalanceSheetDTO.BalanceSheetItemDTO();
            currentYearProfitItem.setAccountCode("4103");
            currentYearProfitItem.setAccountName("本年利润");
            currentYearProfitItem.setAmount(netProfit.abs());
            equity.add(currentYearProfitItem);
            totalEquity = totalEquity.add(netProfit);
        }
        
        sheet.setAssets(assets);
        sheet.setTotalAssets(totalAssets);
        sheet.setLiabilities(liabilities);
        sheet.setTotalLiabilities(totalLiabilities);
        sheet.setEquity(equity);
        sheet.setTotalEquity(totalEquity);
        sheet.setTotalLiabilitiesAndEquity(totalLiabilities.add(totalEquity));
        
        return sheet;
    }
    
    @Override
    public CashFlowDTO generateCashFlowStatement(LocalDate startDate, LocalDate endDate) {
        CashFlowDTO cashFlow = new CashFlowDTO();
        cashFlow.setReportDate(endDate.format(DateTimeFormatter.ofPattern("yyyy-MM-dd")));
        
        // 获取现金科目（通常代码为1001或类似）
        LambdaQueryWrapper<FinAccount> accountWrapper = new LambdaQueryWrapper<>();
        accountWrapper.like(FinAccount::getAccountCode, "1001")
                     .or().like(FinAccount::getAccountName, "现金")
                     .or().like(FinAccount::getAccountName, "银行存款");
        List<FinAccount> cashAccounts = accountMapper.selectList(accountWrapper);
        
        List<Long> cashAccountIds = cashAccounts.stream()
            .map(FinAccount::getAccountId)
            .collect(Collectors.toList());
        
        // 计算期初现金余额
        // 现金科目是资产类，余额为正（借方余额）时增加现金，余额为负（贷方余额，如银行透支）时减少现金
        BigDecimal beginningCashBalance = BigDecimal.ZERO;
        for (Long accountId : cashAccountIds) {
            AccountBalanceDTO balance = accountingService.calculateAccountBalance(accountId, startDate.minusDays(1));
            if (balance != null) {
                beginningCashBalance = beginningCashBalance.add(balance.getBalance());
            }
        }
        cashFlow.setBeginningCashBalance(beginningCashBalance);
        
        // 查询期间内的所有交易
        LambdaQueryWrapper<FinTransaction> transWrapper = new LambdaQueryWrapper<>();
        transWrapper.ge(FinTransaction::getTransDate, startDate);
        transWrapper.le(FinTransaction::getTransDate, endDate);
        transWrapper.eq(FinTransaction::getStatus, 1);
        List<FinTransaction> transactions = transactionMapper.selectList(transWrapper);
        
        // 经营活动产生的现金流量
        List<CashFlowDTO.CashFlowItemDTO> operatingActivities = new ArrayList<>();
        BigDecimal netOperatingCashFlow = BigDecimal.ZERO;
        
        // 投资活动产生的现金流量
        List<CashFlowDTO.CashFlowItemDTO> investingActivities = new ArrayList<>();
        BigDecimal netInvestingCashFlow = BigDecimal.ZERO;
        
        // 筹资活动产生的现金流量
        List<CashFlowDTO.CashFlowItemDTO> financingActivities = new ArrayList<>();
        BigDecimal netFinancingCashFlow = BigDecimal.ZERO;
        
        // 遍历交易，分类现金流量
        for (FinTransaction trans : transactions) {
            LambdaQueryWrapper<FinSplit> splitWrapper = new LambdaQueryWrapper<>();
            splitWrapper.eq(FinSplit::getTransId, trans.getTransId());
            splitWrapper.in(FinSplit::getAccountId, cashAccountIds);
            List<FinSplit> cashSplits = splitMapper.selectList(splitWrapper);
            
            if (!cashSplits.isEmpty()) {
                // 判断交易类型（简化处理，实际应根据业务规则判断）
                String description = trans.getDescription();
                BigDecimal amount = cashSplits.stream()
                    .filter(s -> "DEBIT".equals(s.getDirection()))
                    .map(FinSplit::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add)
                    .subtract(cashSplits.stream()
                        .filter(s -> "CREDIT".equals(s.getDirection()))
                        .map(FinSplit::getAmount)
                        .reduce(BigDecimal.ZERO, BigDecimal::add));
                
                // 简化分类逻辑（实际应根据科目和业务规则详细分类）
                if (description != null) {
                    if (description.contains("销售") || description.contains("收入")) {
                        CashFlowDTO.CashFlowItemDTO item = new CashFlowDTO.CashFlowItemDTO();
                        item.setItemName("销售商品、提供劳务收到的现金");
                        item.setAmount(amount.abs());
                        item.setDescription(description);
                        operatingActivities.add(item);
                        netOperatingCashFlow = netOperatingCashFlow.add(amount);
                    } else if (description.contains("投资")) {
                        CashFlowDTO.CashFlowItemDTO item = new CashFlowDTO.CashFlowItemDTO();
                        item.setItemName("投资支付的现金");
                        item.setAmount(amount.abs());
                        item.setDescription(description);
                        investingActivities.add(item);
                        netInvestingCashFlow = netInvestingCashFlow.add(amount);
                    } else if (description.contains("借款") || description.contains("贷款")) {
                        CashFlowDTO.CashFlowItemDTO item = new CashFlowDTO.CashFlowItemDTO();
                        item.setItemName("取得借款收到的现金");
                        item.setAmount(amount.abs());
                        item.setDescription(description);
                        financingActivities.add(item);
                        netFinancingCashFlow = netFinancingCashFlow.add(amount);
                    }
                }
            }
        }
        
        cashFlow.setOperatingActivities(operatingActivities);
        cashFlow.setNetOperatingCashFlow(netOperatingCashFlow);
        cashFlow.setInvestingActivities(investingActivities);
        cashFlow.setNetInvestingCashFlow(netInvestingCashFlow);
        cashFlow.setFinancingActivities(financingActivities);
        cashFlow.setNetFinancingCashFlow(netFinancingCashFlow);
        
        // 计算现金净增加额
        BigDecimal netIncrease = netOperatingCashFlow
            .add(netInvestingCashFlow)
            .add(netFinancingCashFlow);
        cashFlow.setNetIncreaseInCash(netIncrease);
        
        // 计算期末现金余额
        BigDecimal endingCashBalance = beginningCashBalance.add(netIncrease);
        cashFlow.setEndingCashBalance(endingCashBalance);
        
        return cashFlow;
    }
    
    @Override
    public List<BalanceSheetExportRow> generateBalanceSheetExportData(LocalDate reportDate) {
        // 获取资产负债表数据
        BalanceSheetDTO balanceSheet = generateBalanceSheet(reportDate);
        
        List<BalanceSheetExportRow> exportRows = new ArrayList<>();
        
        // 准备资产列表（包含合计行）
        List<BalanceSheetDTO.BalanceSheetItemDTO> assetItems = new ArrayList<>();
        if (balanceSheet.getAssets() != null) {
            assetItems.addAll(balanceSheet.getAssets());
        }
        // 添加资产合计行
        BalanceSheetDTO.BalanceSheetItemDTO assetTotalItem = new BalanceSheetDTO.BalanceSheetItemDTO();
        assetTotalItem.setAccountName("资产总计");
        assetTotalItem.setAmount(balanceSheet.getTotalAssets().abs());
        assetItems.add(assetTotalItem);
        
        // 准备负债及权益列表（包含合计行）
        List<BalanceSheetDTO.BalanceSheetItemDTO> liabilityEquityItems = new ArrayList<>();
        if (balanceSheet.getLiabilities() != null) {
            liabilityEquityItems.addAll(balanceSheet.getLiabilities());
        }
        // 添加负债合计行
        if (balanceSheet.getTotalLiabilities() != null && 
            balanceSheet.getTotalLiabilities().compareTo(BigDecimal.ZERO) != 0) {
            BalanceSheetDTO.BalanceSheetItemDTO liabilityTotalItem = new BalanceSheetDTO.BalanceSheetItemDTO();
            liabilityTotalItem.setAccountName("负债合计");
            liabilityTotalItem.setAmount(balanceSheet.getTotalLiabilities().abs());
            liabilityEquityItems.add(liabilityTotalItem);
        }
        // 添加所有者权益项目
        if (balanceSheet.getEquity() != null) {
            liabilityEquityItems.addAll(balanceSheet.getEquity());
        }
        // 添加所有者权益合计行
        BalanceSheetDTO.BalanceSheetItemDTO equityTotalItem = new BalanceSheetDTO.BalanceSheetItemDTO();
        equityTotalItem.setAccountName("所有者权益合计");
        equityTotalItem.setAmount(balanceSheet.getTotalEquity().abs());
        liabilityEquityItems.add(equityTotalItem);
        // 添加负债及权益总计行
        BalanceSheetDTO.BalanceSheetItemDTO totalItem = new BalanceSheetDTO.BalanceSheetItemDTO();
        totalItem.setAccountName("负债及权益总计");
        totalItem.setAmount(balanceSheet.getTotalLiabilitiesAndEquity().abs());
        liabilityEquityItems.add(totalItem);
        
        // 合并两个列表，取较长的长度
        int maxLength = Math.max(assetItems.size(), liabilityEquityItems.size());
        
        for (int i = 0; i < maxLength; i++) {
            BalanceSheetExportRow row = new BalanceSheetExportRow();
            
            // 填充资产列
            if (i < assetItems.size()) {
                BalanceSheetDTO.BalanceSheetItemDTO assetItem = assetItems.get(i);
                row.setAssetName(assetItem.getAccountName() != null ? assetItem.getAccountName() : "");
                row.setAssetAmount(assetItem.getAmount() != null ? assetItem.getAmount() : BigDecimal.ZERO);
            } else {
                row.setAssetName("");
                row.setAssetAmount(null);
            }
            
            // 填充负债及权益列
            if (i < liabilityEquityItems.size()) {
                BalanceSheetDTO.BalanceSheetItemDTO liabilityEquityItem = liabilityEquityItems.get(i);
                row.setLiabilityEquityName(liabilityEquityItem.getAccountName() != null ? 
                    liabilityEquityItem.getAccountName() : "");
                row.setLiabilityEquityAmount(liabilityEquityItem.getAmount() != null ? 
                    liabilityEquityItem.getAmount() : BigDecimal.ZERO);
            } else {
                row.setLiabilityEquityName("");
                row.setLiabilityEquityAmount(null);
            }
            
            // 设置分隔符列（空）
            row.setSpacer("");
            
            exportRows.add(row);
        }
        
        return exportRows;
    }
    
    @Override
    public List<TrialBalanceExportRow> generateTrialBalanceExportData(LocalDate startDate, LocalDate endDate) {
        // 获取试算平衡表数据
        List<TrialBalanceDTO> trialBalanceList = accountingService.generateTrialBalance(startDate, endDate);
        
        List<TrialBalanceExportRow> exportRows = new ArrayList<>();
        
        for (TrialBalanceDTO dto : trialBalanceList) {
            TrialBalanceExportRow row = new TrialBalanceExportRow();
            row.setAccountCode(dto.getAccountCode());
            row.setAccountName(dto.getAccountName());
            
            // 本期发生额
            row.setPeriodDebit(dto.getPeriodDebit() != null ? dto.getPeriodDebit() : BigDecimal.ZERO);
            row.setPeriodCredit(dto.getPeriodCredit() != null ? dto.getPeriodCredit() : BigDecimal.ZERO);
            
            // 计算期初余额（根据科目类型）
            BigDecimal openingBalance = calculateBalanceByType(
                dto.getAccountType(),
                dto.getPeriodBeginDebit() != null ? dto.getPeriodBeginDebit() : BigDecimal.ZERO,
                dto.getPeriodBeginCredit() != null ? dto.getPeriodBeginCredit() : BigDecimal.ZERO
            );
            row.setOpeningBalance(openingBalance);
            
            // 计算期末余额（根据科目类型）
            BigDecimal endingBalance = calculateBalanceByType(
                dto.getAccountType(),
                dto.getPeriodEndDebit() != null ? dto.getPeriodEndDebit() : BigDecimal.ZERO,
                dto.getPeriodEndCredit() != null ? dto.getPeriodEndCredit() : BigDecimal.ZERO
            );
            row.setEndingBalance(endingBalance);
            
            exportRows.add(row);
        }
        
        return exportRows;
    }
    
    /**
     * 根据科目类型计算余额
     * 资产类、费用类：余额 = 借方 - 贷方
     * 负债类、权益类、收入类：余额 = 贷方 - 借方
     */
    private BigDecimal calculateBalanceByType(String accountType, BigDecimal debit, BigDecimal credit) {
        if ("ASSET".equals(accountType) || "EXPENSE".equals(accountType)) {
            return debit.subtract(credit);
        } else {
            return credit.subtract(debit);
        }
    }
    
    @Override
    public List<CashFlowExportRow> generateCashFlowExportData(LocalDate startDate, LocalDate endDate) {
        // 获取现金流量表数据
        CashFlowDTO cashFlow = generateCashFlowStatement(startDate, endDate);
        
        List<CashFlowExportRow> exportRows = new ArrayList<>();
        
        // 一、经营活动产生的现金流量
        exportRows.add(CashFlowExportRow.createHeaderRow("一、经营活动产生的现金流量"));
        if (cashFlow.getOperatingActivities() != null) {
            for (CashFlowDTO.CashFlowItemDTO item : cashFlow.getOperatingActivities()) {
                exportRows.add(CashFlowExportRow.createDataRow(
                    item.getItemName(), 
                    item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO
                ));
            }
        }
        // 经营活动产生的现金流量净额
        exportRows.add(CashFlowExportRow.createDataRow(
            "经营活动产生的现金流量净额",
            cashFlow.getNetOperatingCashFlow() != null ? cashFlow.getNetOperatingCashFlow() : BigDecimal.ZERO
        ));
        
        // 添加空行分隔
        exportRows.add(CashFlowExportRow.createDataRow("", null));
        
        // 二、投资活动产生的现金流量
        exportRows.add(CashFlowExportRow.createHeaderRow("二、投资活动产生的现金流量"));
        if (cashFlow.getInvestingActivities() != null) {
            for (CashFlowDTO.CashFlowItemDTO item : cashFlow.getInvestingActivities()) {
                exportRows.add(CashFlowExportRow.createDataRow(
                    item.getItemName(), 
                    item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO
                ));
            }
        }
        // 投资活动产生的现金流量净额
        exportRows.add(CashFlowExportRow.createDataRow(
            "投资活动产生的现金流量净额",
            cashFlow.getNetInvestingCashFlow() != null ? cashFlow.getNetInvestingCashFlow() : BigDecimal.ZERO
        ));
        
        // 添加空行分隔
        exportRows.add(CashFlowExportRow.createDataRow("", null));
        
        // 三、筹资活动产生的现金流量
        exportRows.add(CashFlowExportRow.createHeaderRow("三、筹资活动产生的现金流量"));
        if (cashFlow.getFinancingActivities() != null) {
            for (CashFlowDTO.CashFlowItemDTO item : cashFlow.getFinancingActivities()) {
                exportRows.add(CashFlowExportRow.createDataRow(
                    item.getItemName(), 
                    item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO
                ));
            }
        }
        // 筹资活动产生的现金流量净额
        exportRows.add(CashFlowExportRow.createDataRow(
            "筹资活动产生的现金流量净额",
            cashFlow.getNetFinancingCashFlow() != null ? cashFlow.getNetFinancingCashFlow() : BigDecimal.ZERO
        ));
        
        // 添加空行分隔
        exportRows.add(CashFlowExportRow.createDataRow("", null));
        
        // 四、现金及现金等价物净增加额
        exportRows.add(CashFlowExportRow.createHeaderRow("四、现金及现金等价物净增加额"));
        exportRows.add(CashFlowExportRow.createDataRow(
            "现金及现金等价物净增加额",
            cashFlow.getNetIncreaseInCash() != null ? cashFlow.getNetIncreaseInCash() : BigDecimal.ZERO
        ));
        
        // 添加空行分隔
        exportRows.add(CashFlowExportRow.createDataRow("", null));
        
        // 期初和期末余额
        exportRows.add(CashFlowExportRow.createDataRow(
            "加：期初现金及现金等价物余额",
            cashFlow.getBeginningCashBalance() != null ? cashFlow.getBeginningCashBalance() : BigDecimal.ZERO
        ));
        exportRows.add(CashFlowExportRow.createDataRow(
            "期末现金及现金等价物余额",
            cashFlow.getEndingCashBalance() != null ? cashFlow.getEndingCashBalance() : BigDecimal.ZERO
        ));
        
        return exportRows;
    }
}
