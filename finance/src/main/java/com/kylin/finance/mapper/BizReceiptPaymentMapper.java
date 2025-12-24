package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.biz.BizReceiptPayment;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 收付款单 Mapper 接口
 */
@Mapper
public interface BizReceiptPaymentMapper extends BaseMapper<BizReceiptPayment> {

    /**
     * 根据ID查询收付款单详情
     * 
     * @param id 收付款单ID
     * @return 收付款单对象
     */
    @Select("SELECT * FROM biz_receipt_payment WHERE id = #{id}")
    BizReceiptPayment selectBizReceiptPaymentById(@Param("id") Long id);
}

