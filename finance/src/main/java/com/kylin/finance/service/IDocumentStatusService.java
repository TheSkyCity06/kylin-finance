package com.kylin.finance.service;

import com.kylin.finance.entity.document.Invoice;
import com.kylin.finance.entity.document.Bill;

/**
 * 文档状态机服务接口
 * 负责管理发票和账单的状态转换和校验
 */
public interface IDocumentStatusService {
    
    /**
     * 审核发票（DRAFT -> VALIDATED）
     * @param invoice 发票
     */
    void validateInvoice(Invoice invoice);
    
    /**
     * 审核账单（DRAFT -> VALIDATED）
     * @param bill 账单
     */
    void validateBill(Bill bill);
    
    /**
     * 作废发票（任何状态 -> CANCELLED）
     * @param invoice 发票
     */
    void cancelInvoice(Invoice invoice);
    
    /**
     * 作废账单（任何状态 -> CANCELLED）
     * @param bill 账单
     */
    void cancelBill(Bill bill);
    
    /**
     * 校验发票是否可以更新
     * @param invoice 发票
     * @throws com.kylin.common.BusinessException 如果不允许更新
     */
    void checkInvoiceCanUpdate(Invoice invoice);
    
    /**
     * 校验账单是否可以更新
     * @param bill 账单
     * @throws com.kylin.common.BusinessException 如果不允许更新
     */
    void checkBillCanUpdate(Bill bill);
    
    /**
     * 校验发票是否可以删除
     * @param invoice 发票
     * @throws com.kylin.common.BusinessException 如果不允许删除
     */
    void checkInvoiceCanDelete(Invoice invoice);
    
    /**
     * 校验账单是否可以删除
     * @param bill 账单
     * @throws com.kylin.common.BusinessException 如果不允许删除
     */
    void checkBillCanDelete(Bill bill);
}

