package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.kylin.common.BusinessException;
import com.kylin.finance.dto.AccountDTO;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.mapper.FinAccountMapper;
import com.kylin.finance.mapper.FinSplitMapper;
import com.kylin.finance.service.IFinAccountService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 科目管理服务实现
 */
@Service
public class FinAccountServiceImpl extends ServiceImpl<FinAccountMapper, FinAccount> implements IFinAccountService {
    
    @Autowired
    private FinSplitMapper splitMapper;
    
    @Override
    public List<AccountDTO> getAccountTree() {
        // 查询所有科目
        List<FinAccount> allAccounts = this.list();
        
        // 如果列表为空，返回空列表而不是null
        if (allAccounts == null || allAccounts.isEmpty()) {
            return new ArrayList<>();
        }
        
        // 转换为DTO，过滤掉null值
        List<AccountDTO> accountDTOs = allAccounts.stream()
            .filter(account -> account != null)
            .map(account -> {
                AccountDTO dto = new AccountDTO();
                BeanUtils.copyProperties(account, dto);
                // 确保关键字段不为null
                if (dto.getAccountId() == null) {
                    return null;
                }
                // 初始化children为空列表
                if (dto.getChildren() == null) {
                    dto.setChildren(new ArrayList<>());
                }
                return dto;
            })
            .filter(dto -> dto != null)
            .collect(Collectors.toList());
        
        // 构建树形结构
        List<AccountDTO> tree = buildTree(accountDTOs, null);
        
        // 设置isLeaf和path
        setTreeProperties(tree, accountDTOs, "");
        
        return tree != null ? tree : new ArrayList<>();
    }
    
    /**
     * 递归构建树形结构
     */
    private List<AccountDTO> buildTree(List<AccountDTO> allAccounts, Long parentId) {
        List<AccountDTO> result = new ArrayList<>();
        
        if (allAccounts == null || allAccounts.isEmpty()) {
            return result;
        }
        
        for (AccountDTO account : allAccounts) {
            if (account == null) {
                continue;
            }
            
            // 安全地比较parentId
            boolean isMatch = false;
            if (parentId == null) {
                isMatch = (account.getParentId() == null);
            } else {
                isMatch = parentId.equals(account.getParentId());
            }
            
            if (isMatch) {
                // 确保children字段不为null
                if (account.getChildren() == null) {
                    account.setChildren(new ArrayList<>());
                }
                
                // 递归查找子节点
                List<AccountDTO> children = buildTree(allAccounts, account.getAccountId());
                if (children != null && !children.isEmpty()) {
                    account.setChildren(children);
                } else {
                    account.setChildren(new ArrayList<>());
                }
                
                result.add(account);
            }
        }
        
        return result;
    }
    
    /**
     * 设置树形结构的isLeaf和path属性
     */
    private void setTreeProperties(List<AccountDTO> tree, List<AccountDTO> allAccounts, String parentPath) {
        if (tree == null || tree.isEmpty()) {
            return;
        }
        
        for (AccountDTO account : tree) {
            if (account == null) {
                continue;
            }
            
            // 安全地获取账户名称
            String accountName = account.getAccountName();
            if (accountName == null) {
                accountName = "";
            }
            
            String currentPath = parentPath == null || parentPath.isEmpty() 
                ? accountName 
                : parentPath + " > " + accountName;
            account.setPath(currentPath);
            
            // 安全地检查children
            List<AccountDTO> children = account.getChildren();
            if (children == null || children.isEmpty()) {
                account.setIsLeaf(true);
            } else {
                account.setIsLeaf(false);
                setTreeProperties(children, allAccounts, currentPath);
            }
        }
    }
    
    @Override
    public List<FinAccount> getChildrenByParentId(Long parentId) {
        LambdaQueryWrapper<FinAccount> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FinAccount::getParentId, parentId);
        return this.list(wrapper);
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void addAccount(FinAccount account) {
        // 检查科目代码是否重复
        LambdaQueryWrapper<FinAccount> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FinAccount::getAccountCode, account.getAccountCode());
        if (this.count(wrapper) > 0) {
            throw new BusinessException("科目代码已存在：" + account.getAccountCode());
        }
        
        this.save(account);
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateAccount(FinAccount account) {
        // 检查科目代码是否与其他科目重复
        LambdaQueryWrapper<FinAccount> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FinAccount::getAccountCode, account.getAccountCode());
        wrapper.ne(FinAccount::getAccountId, account.getAccountId());
        if (this.count(wrapper) > 0) {
            throw new BusinessException("科目代码已存在：" + account.getAccountCode());
        }
        
        this.updateById(account);
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteAccount(Long accountId) {
        // 检查是否有子科目
        List<FinAccount> children = getChildrenByParentId(accountId);
        if (!children.isEmpty()) {
            throw new BusinessException("该科目下存在子科目，无法删除");
        }
        
        // 检查是否已被使用（检查是否有分录使用该科目）
        LambdaQueryWrapper<com.kylin.finance.entity.FinSplit> splitWrapper = 
            new LambdaQueryWrapper<>();
        splitWrapper.eq(com.kylin.finance.entity.FinSplit::getAccountId, accountId);
        long count = splitMapper.selectCount(splitWrapper);
        if (count > 0) {
            throw new BusinessException("该科目已被使用，无法删除");
        }
        
        this.removeById(accountId);
    }
    
    @Override
    public boolean isLeafAccount(Long accountId) {
        List<FinAccount> children = getChildrenByParentId(accountId);
        return children.isEmpty();
    }
    
    @Override
    public List<AccountDTO> getLeafAccounts() {
        // 查询所有科目
        List<FinAccount> allAccounts = this.list();
        
        // 转换为DTO并过滤出末级科目
        List<AccountDTO> leafAccounts = allAccounts.stream()
            .filter(account -> {
                // 检查是否有子科目
                List<FinAccount> children = getChildrenByParentId(account.getAccountId());
                return children.isEmpty();
            })
            .map(account -> {
                AccountDTO dto = new AccountDTO();
                BeanUtils.copyProperties(account, dto);
                dto.setIsLeaf(true);
                // 设置路径
                dto.setPath(getAccountPath(account.getAccountId()));
                return dto;
            })
            .collect(Collectors.toList());
        
        return leafAccounts;
    }
    
    @Override
    public String getAccountPath(Long accountId) {
        List<String> pathNames = new ArrayList<>();
        FinAccount account = this.getById(accountId);
        
        if (account == null) {
            return "";
        }
        
        // 递归向上查找父节点
        Long currentParentId = account.getParentId();
        pathNames.add(0, account.getAccountName());
        
        while (currentParentId != null) {
            FinAccount parent = this.getById(currentParentId);
            if (parent == null) {
                break;
            }
            pathNames.add(0, parent.getAccountName());
            currentParentId = parent.getParentId();
        }
        
        return String.join(" > ", pathNames);
    }
}
