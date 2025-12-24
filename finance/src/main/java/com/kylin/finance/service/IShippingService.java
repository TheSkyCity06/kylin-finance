package com.kylin.finance.service;

import com.kylin.finance.entity.document.Invoice;

/**
 * 邮寄追踪服务接口
 */
public interface IShippingService {

    /**
     * 标记发票为已邮寄
     * @param invoiceId 发票ID
     * @param trackingNo 快递单号
     * @return 更新后的发票
     */
    Invoice markAsSent(Long invoiceId, String trackingNo);

    /**
     * 发送邮寄提醒给客户（模拟）
     * @param invoice 发票
     */
    void sendShippingNotification(Invoice invoice);
}
