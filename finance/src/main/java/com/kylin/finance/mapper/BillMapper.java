package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.document.Bill;
import org.apache.ibatis.annotations.Mapper;

/**
 * 账单表数据库访问层
 */
@Mapper
public interface BillMapper extends BaseMapper<Bill> {
}
