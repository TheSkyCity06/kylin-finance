package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.biz.BizExpenseClaimDetail;
import org.apache.ibatis.annotations.Mapper;

/**
 * 报销明细表 Mapper 接口
 */
@Mapper
public interface BizExpenseClaimDetailMapper extends BaseMapper<BizExpenseClaimDetail> {
}

