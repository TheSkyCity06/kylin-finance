package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.expense.ExpenseClaim;
import org.apache.ibatis.annotations.Mapper;

/**
 * 员工报销单表数据库访问层
 */
@Mapper
public interface ExpenseClaimMapper extends BaseMapper<ExpenseClaim> {
}
