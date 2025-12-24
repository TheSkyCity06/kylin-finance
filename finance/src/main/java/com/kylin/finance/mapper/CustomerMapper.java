package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.business.Customer;
import org.apache.ibatis.annotations.Mapper;

/**
 * 客户表数据库访问层
 */
@Mapper
public interface CustomerMapper extends BaseMapper<Customer> {
}

