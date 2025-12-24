package com.kylin.finance.service;

import com.kylin.finance.entity.FinSplit;
import java.util.List;

/**
 * 业务实体校验服务接口
 * 确保涉及往来实体的分录必须同时记录在实体的关联科目下
 */
public interface IOwnerValidationService {
    
    /**
     * 校验交易中的所有分录是否满足业务实体关联规则
     * @param splits 分录列表
     */
    void validateOwnerAssociation(List<FinSplit> splits);
    
    /**
     * 校验单个分录是否满足业务实体关联规则
     * @param split 分录
     */
    void validateSplitOwnerAssociation(FinSplit split);
}

