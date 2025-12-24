package com.kylin.finance.service;

import com.kylin.finance.entity.document.Invoice;
import com.kylin.finance.entity.document.Bill;
import com.kylin.finance.entity.document.CreditNote;
import com.kylin.finance.entity.FinTransaction;

/**
 * 过账服务接口（参考 GnuCash Post Service）
 * 负责将商业单据（发票/账单）过账到会计账目中
 */
public interface IPostService {

    /**
     * 将发票过账到账目中
     * 生成凭证：借：应收账款（关联客户），贷：收入科目（或税费）
     * @param invoice 发票
     * @return 生成的交易
     */
    FinTransaction postInvoiceToLedger(Invoice invoice);

    /**
     * 将账单过账到账目中
     * 生成凭证：借：费用/资产科目，贷：应付账款（关联供应商）
     * @param bill 账单
     * @return 生成的交易
     */
    FinTransaction postBillToLedger(Bill bill);

    /**
     * 将冲销单据过账到账目中
     * 生成反向凭证，用于更正已过账的单据
     * @param creditNote 冲销单据
     * @return 生成的交易
     */
    FinTransaction postCreditNoteToLedger(CreditNote creditNote);

    /**
     * 取消发票过账（撤销过账）
     * @param invoiceId 发票ID
     */
    void unpostInvoice(Long invoiceId);

    /**
     * 取消账单过账（撤销过账）
     * @param billId 账单ID
     */
    void unpostBill(Long billId);

    /**
     * 取消冲销单据过账（撤销过账）
     * @param creditNoteId 冲销单据ID
     */
    void unpostCreditNote(Long creditNoteId);

    /**
     * 红冲发票（已过账发票的反向凭证）
     * @param invoice 发票
     * @return 生成的红冲交易
     */
    FinTransaction reverseInvoicePosting(Invoice invoice);

    /**
     * 红冲账单（已过账账单的反向凭证）
     * @param bill 账单
     * @return 生成的红冲交易
     */
    FinTransaction reverseBillPosting(Bill bill);
}
