package com.kylin.finance.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kylin.finance.entity.biz.BizReceiptPayment;

/**
 * 收付款单服务接口
 */
public interface IBizReceiptPaymentService {

    /**
     * 保存收付款单（新增或更新）
     * 
     * @param payment 收付款单对象
     * @return 保存后的收付款单对象
     */
    BizReceiptPayment saveReceiptPayment(BizReceiptPayment payment);

    /**
     * 保存并过账收付款单
     * 
     * @param payment 收付款单对象
     * @return 保存后的收付款单对象
     */
    BizReceiptPayment saveAndPostReceiptPayment(BizReceiptPayment payment);

    /**
     * 分页查询收付款单列表
     * 
     * @param page 分页参数
     * @param type 类型（可选）：RECEIPT(收款), PAYMENT(付款)
     * @param status 状态（可选）：0=草稿, 1=已过账
     * @return 分页结果
     */
    IPage<BizReceiptPayment> getReceiptPaymentList(Page<BizReceiptPayment> page, String type, Integer status);

    /**
     * 根据ID查询收付款单
     * 
     * @param id 收付款单ID
     * @return 收付款单对象
     */
    BizReceiptPayment getById(Long id);

    /**
     * 根据ID查询收付款单详情
     * 
     * @param id 收付款单ID
     * @return 收付款单对象
     */
    BizReceiptPayment selectBizReceiptPaymentById(Long id);
}

