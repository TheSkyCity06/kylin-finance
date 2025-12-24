package com.kylin.finance.service;

import com.kylin.finance.entity.payment.Payment;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.entity.business.Owner;

import java.math.BigDecimal;

/**
 * 支付处理服务接口（参考 GnuCash Payment Processing）
 * 处理客户付款、供应商付款以及自动核销（Lot Tracking）
 */
public interface IPaymentService {

    /**
     * 处理客户付款（收款）
     * @param owner 客户业务实体
     * @param amount 付款金额
     * @param accountId 收款账户ID（银行存款等）
     * @return 生成的支付记录（包含分配结果）
     */
    Payment processCustomerPayment(Owner owner, BigDecimal amount, Long accountId);

    /**
     * 处理供应商付款（付款）
     * @param owner 供应商业务实体
     * @param amount 付款金额
     * @param accountId 付款账户ID（银行存款等）
     * @return 生成的支付记录
     */
    Payment processVendorPayment(Owner owner, BigDecimal amount, Long accountId);

    /**
     * 通用支付处理方法
     * @param owner 业务实体（客户或供应商）
     * @param amount 支付金额
     * @param accountId 支付账户ID
     * @param paymentType 支付类型：RECEIPT(收款) 或 PAYMENT(付款)
     * @return 生成的支付记录
     */
    Payment processPayment(Owner owner, BigDecimal amount, Long accountId, String paymentType);

    /**
     * 执行 Lot Tracking 核销算法
     * 自动匹配未结清的单据进行核销
     * @param payment 支付记录
     */
    void performLotTracking(Payment payment);

    /**
     * 将支付过账到账目中
     * 生成财务凭证并更新相关状态
     * @param payment 支付记录
     * @return 生成的交易
     */
    FinTransaction postPaymentToLedger(Payment payment);

    /**
     * 取消支付过账（撤销）
     * @param paymentId 支付ID
     */
    void unpostPayment(Long paymentId);

    /**
     * 获取实体的未结清金额
     * @param ownerId 业务实体ID
     * @return 未结清金额
     */
    BigDecimal getUnpaidAmount(Long ownerId);

    /**
     * 获取支付的分配结果
     * @param paymentId 支付ID
     * @return 分配结果列表
     */
    java.util.List<com.kylin.finance.dto.PaymentAllocationResultDTO> getPaymentAllocations(Long paymentId);
}
