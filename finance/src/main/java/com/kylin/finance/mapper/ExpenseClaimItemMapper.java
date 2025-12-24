package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.expense.ExpenseClaimItem;
import org.apache.ibatis.annotations.Mapper;

/**
 * 员工报销明细表数据库访问层
 */
@Mapper
public interface ExpenseClaimItemMapper extends BaseMapper<ExpenseClaimItem> {
}
