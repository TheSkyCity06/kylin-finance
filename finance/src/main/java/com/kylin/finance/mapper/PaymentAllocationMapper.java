package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.payment.PaymentAllocation;
import org.apache.ibatis.annotations.Mapper;

/**
 * 支付分配表数据库访问层
 */
@Mapper
public interface PaymentAllocationMapper extends BaseMapper<PaymentAllocation> {
}
