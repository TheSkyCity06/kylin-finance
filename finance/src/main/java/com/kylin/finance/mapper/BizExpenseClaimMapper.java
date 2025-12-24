package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.biz.BizExpenseClaim;
import org.apache.ibatis.annotations.Mapper;

/**
 * 报销单主表 Mapper 接口
 */
@Mapper
public interface BizExpenseClaimMapper extends BaseMapper<BizExpenseClaim> {
}

