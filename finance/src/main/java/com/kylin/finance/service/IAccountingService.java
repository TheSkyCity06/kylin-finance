package com.kylin.finance.service;

import com.kylin.finance.dto.AccountBalanceDTO;
import com.kylin.finance.dto.TrialBalanceDTO;

import java.time.LocalDate;
import java.util.List;

/**
 * 核算服务接口
 */
public interface IAccountingService {
    
    /**
     * 计算科目余额（指定日期）
     */
    AccountBalanceDTO calculateAccountBalance(Long accountId, LocalDate date);
    
    /**
     * 计算所有科目余额（指定日期）
     */
    List<AccountBalanceDTO> calculateAllAccountBalances(LocalDate date);
    
    /**
     * 生成试算平衡表
     * @param startDate 开始日期
     * @param endDate 结束日期
     */
    List<TrialBalanceDTO> generateTrialBalance(LocalDate startDate, LocalDate endDate);
    
    /**
     * 验证试算平衡（借贷是否相等）
     */
    boolean verifyTrialBalance(LocalDate date);
}
