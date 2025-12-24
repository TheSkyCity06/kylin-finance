package com.kylin.finance.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.kylin.finance.dto.AccountDTO;
import com.kylin.finance.entity.FinAccount;

import java.util.List;

/**
 * 科目管理服务接口
 */
public interface IFinAccountService extends IService<FinAccount> {
    
    /**
     * 获取科目树形结构
     */
    List<AccountDTO> getAccountTree();
    
    /**
     * 根据父ID获取子科目列表
     */
    List<FinAccount> getChildrenByParentId(Long parentId);
    
    /**
     * 添加科目
     */
    void addAccount(FinAccount account);
    
    /**
     * 更新科目
     */
    void updateAccount(FinAccount account);
    
    /**
     * 删除科目（检查是否有子科目或已使用）
     */
    void deleteAccount(Long accountId);
    
    /**
     * 判断是否为末级科目（没有子科目）
     */
    boolean isLeafAccount(Long accountId);
    
    /**
     * 获取所有末级科目列表（用于凭证录入）
     */
    List<AccountDTO> getLeafAccounts();
    
    /**
     * 获取科目的层级路径
     */
    String getAccountPath(Long accountId);
}
