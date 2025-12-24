package com.kylin.finance.service.impl;

import com.kylin.common.BusinessException;
import com.kylin.finance.common.DocumentStatus;
import com.kylin.finance.entity.document.Invoice;
import com.kylin.finance.entity.document.Bill;
import com.kylin.finance.mapper.InvoiceMapper;
import com.kylin.finance.mapper.BillMapper;
import com.kylin.finance.service.IDocumentStatusService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 文档状态机服务实现类
 */
@Slf4j
@Service
public class DocumentStatusServiceImpl implements IDocumentStatusService {
    
    @Autowired
    private InvoiceMapper invoiceMapper;
    
    @Autowired
    private BillMapper billMapper;
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void validateInvoice(Invoice invoice) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(invoice.getStatus());
        
        if (!currentStatus.canValidate()) {
            throw new BusinessException(
                String.format("发票状态为 %s，无法审核。只有草稿状态的发票可以审核。", currentStatus.getDescription()));
        }
        
        log.info("审核发票，ID：{}，编号：{}", invoice.getInvoiceId(), invoice.getInvoiceNo());
        
        invoice.setStatus(DocumentStatus.VALIDATED.getCode());
        invoiceMapper.updateById(invoice);
        
        log.info("发票审核成功，ID：{}", invoice.getInvoiceId());
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void validateBill(Bill bill) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(bill.getStatus());
        
        if (!currentStatus.canValidate()) {
            throw new BusinessException(
                String.format("账单状态为 %s，无法审核。只有草稿状态的账单可以审核。", currentStatus.getDescription()));
        }
        
        log.info("审核账单，ID：{}，编号：{}", bill.getBillId(), bill.getBillNo());
        
        bill.setStatus(DocumentStatus.VALIDATED.getCode());
        billMapper.updateById(bill);
        
        log.info("账单审核成功，ID：{}", bill.getBillId());
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelInvoice(Invoice invoice) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(invoice.getStatus());
        
        if (!currentStatus.canCancel()) {
            throw new BusinessException("发票已作废，无法重复作废");
        }
        
        // 已过账的发票会通过红冲凭证来抵消，这里允许作废
        
        log.info("作废发票，ID：{}，编号：{}", invoice.getInvoiceId(), invoice.getInvoiceNo());
        
        invoice.setStatus(DocumentStatus.CANCELLED.getCode());
        invoiceMapper.updateById(invoice);
        
        log.info("发票作废成功，ID：{}", invoice.getInvoiceId());
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancelBill(Bill bill) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(bill.getStatus());
        
        if (!currentStatus.canCancel()) {
            throw new BusinessException("账单已作废，无法重复作废");
        }
        
        // 已过账的账单会通过红冲凭证来抵消，这里允许作废
        
        log.info("作废账单，ID：{}，编号：{}", bill.getBillId(), bill.getBillNo());
        
        bill.setStatus(DocumentStatus.CANCELLED.getCode());
        billMapper.updateById(bill);
        
        log.info("账单作废成功，ID：{}", bill.getBillId());
    }
    
    @Override
    public void checkInvoiceCanUpdate(Invoice invoice) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(invoice.getStatus());
        
        if (!currentStatus.canUpdate()) {
            throw new BusinessException(
                String.format("发票状态为 %s，不允许修改。只有草稿状态的发票可以修改。", currentStatus.getDescription()));
        }
    }
    
    @Override
    public void checkBillCanUpdate(Bill bill) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(bill.getStatus());
        
        if (!currentStatus.canUpdate()) {
            throw new BusinessException(
                String.format("账单状态为 %s，不允许修改。只有草稿状态的账单可以修改。", currentStatus.getDescription()));
        }
    }
    
    @Override
    public void checkInvoiceCanDelete(Invoice invoice) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(invoice.getStatus());
        
        if (!currentStatus.canDelete()) {
            throw new BusinessException(
                String.format("发票状态为 %s，不允许删除。只有草稿状态的发票可以删除。", currentStatus.getDescription()));
        }
    }
    
    @Override
    public void checkBillCanDelete(Bill bill) {
        DocumentStatus currentStatus = DocumentStatus.fromCode(bill.getStatus());
        
        if (!currentStatus.canDelete()) {
            throw new BusinessException(
                String.format("账单状态为 %s，不允许删除。只有草稿状态的账单可以删除。", currentStatus.getDescription()));
        }
    }
}

