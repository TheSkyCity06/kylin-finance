package com.kylin.finance.service.impl;

import com.kylin.common.BusinessException;
import com.kylin.finance.entity.document.Invoice;
import com.kylin.finance.mapper.InvoiceMapper;
import com.kylin.finance.service.IShippingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 邮寄追踪服务实现
 */
@Slf4j
@Service
public class ShippingServiceImpl implements IShippingService {

    @Autowired
    private InvoiceMapper invoiceMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Invoice markAsSent(Long invoiceId, String trackingNo) {
        Invoice invoice = invoiceMapper.selectById(invoiceId);
        if (invoice == null) {
            throw new BusinessException("发票不存在");
        }

        // 更新邮寄状态和快递单号
        invoice.setShippingStatus("SENT");
        invoice.setTrackingNo(trackingNo);
        invoiceMapper.updateById(invoice);

        // 发送提醒给客户（模拟）
        sendShippingNotification(invoice);

        log.info("发票 {} 已标记为已邮寄，快递单号：{}", invoice.getInvoiceNo(), trackingNo);

        return invoice;
    }

    @Override
    public void sendShippingNotification(Invoice invoice) {
        // 模拟发送邮件/短信提醒
        log.info("========== 邮寄提醒 ==========");
        log.info("收件人：客户 ID {}", invoice.getCustomerId());
        log.info("发票编号：{}", invoice.getInvoiceNo());
        log.info("发票金额：{}", invoice.getTotalAmount());
        log.info("快递单号：{}", invoice.getTrackingNo());
        log.info("邮寄状态：{}", invoice.getShippingStatus());
        log.info("=============================");

        // 实际实现中可以：
        // 1. 查询客户邮箱/手机号
        // 2. 调用邮件服务发送通知
        // 3. 调用短信服务发送通知
        // 4. 记录通知日志
    }
}
