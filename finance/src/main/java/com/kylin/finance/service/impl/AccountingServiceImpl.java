package com.kylin.finance.service.impl;

import com.kylin.finance.dto.AccountBalanceDTO;
import com.kylin.finance.dto.AccountBalanceSummary;
import com.kylin.finance.dto.TrialBalanceDTO;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.mapper.FinAccountMapper;
import com.kylin.finance.mapper.FinSplitMapper;
import com.kylin.finance.service.IAccountingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 核算服务实现
 * 重构后使用批量查询，避免 N+1 查询问题
 */
@Service
public class AccountingServiceImpl implements IAccountingService {
    
    @Autowired
    private FinAccountMapper accountMapper;
    
    @Autowired
    private FinSplitMapper splitMapper;
    
    @Override
    @Transactional(readOnly = true)
    public AccountBalanceDTO calculateAccountBalance(Long accountId, LocalDate date) {
        FinAccount account = accountMapper.selectById(accountId);
        if (account == null) {
            return null;
        }
        
        // 使用批量查询方法，传入单个科目ID列表
        List<Long> accountIds = Collections.singletonList(accountId);
        List<AccountBalanceSummary> summaries = splitMapper.selectBalanceByAccountIds(accountIds, date);
        
        AccountBalanceDTO dto = new AccountBalanceDTO();
        dto.setAccountId(account.getAccountId());
        dto.setAccountCode(account.getAccountCode());
        dto.setAccountName(account.getAccountName());
        dto.setAccountType(account.getAccountType());
        
        // 从批量查询结果中获取该科目的余额
        BigDecimal debitAmount = BigDecimal.ZERO;
        BigDecimal creditAmount = BigDecimal.ZERO;
        
        if (!summaries.isEmpty()) {
            AccountBalanceSummary summary = summaries.get(0);
            debitAmount = summary.getDebitAmount() != null ? summary.getDebitAmount() : BigDecimal.ZERO;
            creditAmount = summary.getCreditAmount() != null ? summary.getCreditAmount() : BigDecimal.ZERO;
        }
        
        dto.setDebitBalance(debitAmount);
        dto.setCreditBalance(creditAmount);
        
        // 根据科目类型计算余额
        BigDecimal balance = calculateBalanceByType(account.getAccountType(), debitAmount, creditAmount);
        dto.setBalance(balance);
        
        return dto;
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<AccountBalanceDTO> calculateAllAccountBalances(LocalDate date) {
        // 查询所有科目
        List<FinAccount> accounts = accountMapper.selectList(null);
        if (accounts.isEmpty()) {
            return new ArrayList<>();
        }
        
        // 提取所有科目ID
        List<Long> accountIds = accounts.stream()
                .map(FinAccount::getAccountId)
                .collect(Collectors.toList());
        
        // 批量查询所有科目的余额（一次性查询，避免 N+1）
        List<AccountBalanceSummary> summaries = splitMapper.selectBalanceByAccountIds(accountIds, date);
        
        // 将批量查询结果转换为 Map，便于快速查找
        Map<Long, AccountBalanceSummary> summaryMap = summaries.stream()
                .collect(Collectors.toMap(
                        AccountBalanceSummary::getAccountId,
                        summary -> summary,
                        (existing, replacement) -> existing
                ));
        
        // 组装结果
        List<AccountBalanceDTO> result = new ArrayList<>();
        for (FinAccount account : accounts) {
            AccountBalanceDTO dto = new AccountBalanceDTO();
            dto.setAccountId(account.getAccountId());
            dto.setAccountCode(account.getAccountCode());
            dto.setAccountName(account.getAccountName());
            dto.setAccountType(account.getAccountType());
            
            AccountBalanceSummary summary = summaryMap.get(account.getAccountId());
            BigDecimal debitAmount = BigDecimal.ZERO;
            BigDecimal creditAmount = BigDecimal.ZERO;
            
            if (summary != null) {
                debitAmount = summary.getDebitAmount() != null ? summary.getDebitAmount() : BigDecimal.ZERO;
                creditAmount = summary.getCreditAmount() != null ? summary.getCreditAmount() : BigDecimal.ZERO;
            }
            
            dto.setDebitBalance(debitAmount);
            dto.setCreditBalance(creditAmount);
            
            // 根据科目类型计算余额
            BigDecimal balance = calculateBalanceByType(account.getAccountType(), debitAmount, creditAmount);
            dto.setBalance(balance);
            
            result.add(dto);
        }
        
        return result;
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<TrialBalanceDTO> generateTrialBalance(LocalDate startDate, LocalDate endDate) {
        // 查询所有科目
        List<FinAccount> accounts = accountMapper.selectList(null);
        if (accounts.isEmpty()) {
            return new ArrayList<>();
        }
        
        // 提取所有科目ID
        List<Long> accountIds = accounts.stream()
                .map(FinAccount::getAccountId)
                .collect(Collectors.toList());
        
        // 批量查询期初余额（startDate之前）- 一次性查询所有科目
        LocalDate beginDate = startDate.minusDays(1);
        List<AccountBalanceSummary> beginSummaries = splitMapper.selectBalanceByAccountIds(accountIds, beginDate);
        Map<Long, AccountBalanceSummary> beginSummaryMap = beginSummaries.stream()
                .collect(Collectors.toMap(
                        AccountBalanceSummary::getAccountId,
                        summary -> summary,
                        (existing, replacement) -> existing
                ));
        
        // 批量查询本期发生额（startDate到endDate之间）- 一次性查询所有科目
        List<AccountBalanceSummary> periodSummaries = splitMapper.selectPeriodAmountByAccountIds(
                accountIds, startDate, endDate);
        Map<Long, AccountBalanceSummary> periodSummaryMap = periodSummaries.stream()
                .collect(Collectors.toMap(
                        AccountBalanceSummary::getAccountId,
                        summary -> summary,
                        (existing, replacement) -> existing
                ));
        
        // 构建试算平衡表
        List<TrialBalanceDTO> result = new ArrayList<>();
        for (FinAccount account : accounts) {
            TrialBalanceDTO dto = new TrialBalanceDTO();
            dto.setAccountId(account.getAccountId());
            dto.setAccountCode(account.getAccountCode());
            dto.setAccountName(account.getAccountName());
            dto.setAccountType(account.getAccountType());
            
            // 期初余额
            AccountBalanceSummary beginSummary = beginSummaryMap.get(account.getAccountId());
            if (beginSummary != null) {
                dto.setPeriodBeginDebit(
                        beginSummary.getDebitAmount() != null ? beginSummary.getDebitAmount() : BigDecimal.ZERO);
                dto.setPeriodBeginCredit(
                        beginSummary.getCreditAmount() != null ? beginSummary.getCreditAmount() : BigDecimal.ZERO);
            } else {
                dto.setPeriodBeginDebit(BigDecimal.ZERO);
                dto.setPeriodBeginCredit(BigDecimal.ZERO);
            }
            
            // 本期发生额
            AccountBalanceSummary periodSummary = periodSummaryMap.get(account.getAccountId());
            if (periodSummary != null) {
                dto.setPeriodDebit(
                        periodSummary.getDebitAmount() != null ? periodSummary.getDebitAmount() : BigDecimal.ZERO);
                dto.setPeriodCredit(
                        periodSummary.getCreditAmount() != null ? periodSummary.getCreditAmount() : BigDecimal.ZERO);
            } else {
                dto.setPeriodDebit(BigDecimal.ZERO);
                dto.setPeriodCredit(BigDecimal.ZERO);
            }
            
            // 计算期末余额
            BigDecimal endDebit = dto.getPeriodBeginDebit().add(dto.getPeriodDebit());
            BigDecimal endCredit = dto.getPeriodBeginCredit().add(dto.getPeriodCredit());
            
            // 根据科目类型计算期末余额方向
            // 资产类、费用类：余额 = 借方 - 贷方，余额为正数时在借方，负数时在贷方
            // 负债类、权益类、收入类：余额 = 贷方 - 借方，余额为正数时在贷方，负数时在借方
            BigDecimal balance = calculateBalanceByType(account.getAccountType(), endDebit, endCredit);
            
            if ("ASSET".equals(account.getAccountType()) || "EXPENSE".equals(account.getAccountType())) {
                // 资产类、费用类：余额为正数时在借方，负数时在贷方
                if (balance.compareTo(BigDecimal.ZERO) >= 0) {
                    dto.setPeriodEndDebit(balance.abs());
                    dto.setPeriodEndCredit(BigDecimal.ZERO);
                } else {
                    dto.setPeriodEndDebit(BigDecimal.ZERO);
                    dto.setPeriodEndCredit(balance.abs());
                }
            } else {
                // 负债类、权益类、收入类：余额为正数时在贷方，负数时在借方
                if (balance.compareTo(BigDecimal.ZERO) >= 0) {
                    dto.setPeriodEndDebit(BigDecimal.ZERO);
                    dto.setPeriodEndCredit(balance.abs());
                } else {
                    dto.setPeriodEndDebit(balance.abs());
                    dto.setPeriodEndCredit(BigDecimal.ZERO);
                }
            }
            
            result.add(dto);
        }
        
        return result;
    }
    
    @Override
    @Transactional(readOnly = true)
    public boolean verifyTrialBalance(LocalDate date) {
        List<AccountBalanceDTO> balances = calculateAllAccountBalances(date);
        
        BigDecimal totalDebit = BigDecimal.ZERO;
        BigDecimal totalCredit = BigDecimal.ZERO;
        
        for (AccountBalanceDTO balance : balances) {
            totalDebit = totalDebit.add(balance.getDebitBalance());
            totalCredit = totalCredit.add(balance.getCreditBalance());
        }
        
        return totalDebit.compareTo(totalCredit) == 0;
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
}
