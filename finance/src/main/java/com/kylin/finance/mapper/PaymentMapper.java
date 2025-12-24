package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.payment.Payment;
import org.apache.ibatis.annotations.Mapper;

/**
 * 支付表数据库访问层
 */
@Mapper
public interface PaymentMapper extends BaseMapper<Payment> {
}
