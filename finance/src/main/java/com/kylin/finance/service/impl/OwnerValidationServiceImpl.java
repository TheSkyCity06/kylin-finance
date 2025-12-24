package com.kylin.finance.service.impl;

import com.kylin.common.BusinessException;
import com.kylin.finance.entity.FinSplit;
import com.kylin.finance.entity.business.Owner;
import com.kylin.finance.mapper.OwnerMapper;
import com.kylin.finance.service.IOwnerValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

/**
 * 业务实体校验服务实现
 */
@Service
public class OwnerValidationServiceImpl implements IOwnerValidationService {
    
    @Autowired
    private OwnerMapper ownerMapper;
    
    @Override
    public void validateOwnerAssociation(List<FinSplit> splits) {
        if (splits == null || splits.isEmpty()) {
            return;
        }
        
        for (FinSplit split : splits) {
            validateSplitOwnerAssociation(split);
        }
    }
    
    @Override
    public void validateSplitOwnerAssociation(FinSplit split) {
        if (split == null) {
            return;
        }
        
        // 如果分录没有关联业务实体，跳过校验
        if (split.getOwnerId() == null || split.getOwnerType() == null) {
            return;
        }
        
        // 根据业务实体类型查找对应的实体
        Owner owner = findOwnerById(split.getOwnerId(), split.getOwnerType());
        if (owner == null) {
            throw new BusinessException(
                String.format("未找到业务实体（ID：%d，类型：%s）", split.getOwnerId(), split.getOwnerType()));
        }
        
        // 调用实体的校验方法
        BigDecimal amount = split.getAmount() != null ? split.getAmount() : BigDecimal.ZERO;
        owner.validateSplitAssociation(split.getAccountId(), amount);
    }
    
    /**
     * 根据ID和类型查找业务实体
     * 注意：ownerId 是 fin_owner 表的主键，不是子表（fin_customer、fin_vendor、fin_employee）的主键
     * 所以直接查询 fin_owner 表即可，因为所有业务实体的基础信息都在 fin_owner 表中
     */
    private Owner findOwnerById(Long ownerId, String ownerType) {
        if (ownerId == null || ownerType == null) {
            return null;
        }
        
        // 直接查询 fin_owner 表，因为 ownerId 就是 fin_owner 表的主键
        Owner owner = ownerMapper.selectById(ownerId);
        
        // 验证类型是否匹配
        if (owner != null && !ownerType.equalsIgnoreCase(owner.getOwnerType())) {
            throw new BusinessException(
                String.format("业务实体类型不匹配：期望 %s，实际 %s", ownerType, owner.getOwnerType()));
        }
        
        return owner;
    }
}

