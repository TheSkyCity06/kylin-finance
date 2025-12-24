// GnuCash 风格的商业单据流转逻辑示例
// 演示如何使用新实现的 Invoice/Bill/CreditNote 功能

public class GnucashIntegrationDemo {

    @Autowired
    private IPostService postService;

    @Autowired
    private InvoiceMapper invoiceMapper;

    @Autowired
    private BillMapper billMapper;

    @Autowired
    private CreditNoteMapper creditNoteMapper;

    @Autowired
    private InvoiceItemMapper invoiceItemMapper;

    @Autowired
    private BillItemMapper billItemMapper;

    /**
     * 示例1：创建并过账客户发票
     */
    public void createAndPostInvoice() {
        // 1. 创建发票
        Invoice invoice = new Invoice();
        invoice.setInvoiceNo("INV-2024-001");
        invoice.setInvoiceDate(LocalDate.now());
        invoice.setDueDate(LocalDate.now().plusDays(30));
        invoice.setCustomerId(1L); // 假设客户ID为1
        invoice.setCommodityId(1L); // 人民币
        invoice.setStatus("OPEN");
        invoice.setPosted(false);

        // 创建发票条目
        InvoiceItem item = new InvoiceItem();
        item.setDescription("软件开发服务");
        item.setIncomeAccountId(6001L); // 主营业务收入科目
        item.setQuantity(BigDecimal.ONE);
        item.setUnitPrice(new BigDecimal("10000.00"));
        item.setAmount(new BigDecimal("10000.00"));
        item.setTaxRate(new BigDecimal("13.00"));
        item.setTaxAmount(new BigDecimal("1300.00"));

        invoice.setItems(List.of(item));

        // 计算总额
        invoice.setNetAmount(new BigDecimal("10000.00"));
        invoice.setTaxAmount(new BigDecimal("1300.00"));
        invoice.setTotalAmount(new BigDecimal("11300.00"));

        // 保存发票
        invoiceMapper.insert(invoice);
        item.setInvoiceId(invoice.getInvoiceId());
        invoiceItemMapper.insert(item);

        // 2. 过账发票到账目
        FinTransaction transaction = postService.postInvoiceToLedger(invoice);

        System.out.println("发票过账成功，生成交易ID: " + transaction.getTransId());
        System.out.println("生成的会计分录:");
        System.out.println("借: 应收账款(客户) 11,300.00");
        System.out.println("贷: 主营业务收入 10,000.00");
        System.out.println("贷: 应交税费 1,300.00");
    }

    /**
     * 示例2：创建并过账供应商账单
     */
    public void createAndPostBill() {
        // 1. 创建账单
        Bill bill = new Bill();
        bill.setBillNo("BILL-2024-001");
        bill.setBillDate(LocalDate.now());
        bill.setDueDate(LocalDate.now().plusDays(30));
        bill.setVendorId(2L); // 假设供应商ID为2
        bill.setCommodityId(1L); // 人民币
        bill.setStatus("OPEN");
        bill.setPosted(false);

        // 创建账单条目
        BillItem item = new BillItem();
        item.setDescription("办公用品采购");
        item.setExpenseAccountId(6602L); // 管理费用科目
        item.setQuantity(new BigDecimal("10"));
        item.setUnitPrice(new BigDecimal("100.00"));
        item.setAmount(new BigDecimal("1000.00"));
        item.setTaxRate(new BigDecimal("13.00"));
        item.setTaxAmount(new BigDecimal("130.00"));

        bill.setItems(List.of(item));

        // 计算总额
        bill.setNetAmount(new BigDecimal("1000.00"));
        bill.setTaxAmount(new BigDecimal("130.00"));
        bill.setTotalAmount(new BigDecimal("1130.00"));

        // 保存账单
        billMapper.insert(bill);
        item.setBillId(bill.getBillId());
        billItemMapper.insert(item);

        // 2. 过账账单到账目
        FinTransaction transaction = postService.postBillToLedger(bill);

        System.out.println("账单过账成功，生成交易ID: " + transaction.getTransId());
        System.out.println("生成的会计分录:");
        System.out.println("借: 管理费用 1,130.00");
        System.out.println("贷: 应付账款(供应商) 1,130.00");
    }

    /**
     * 示例3：创建冲销单据更正已过账的发票
     */
    public void createCreditNote() {
        // 假设有一张已过账的发票需要更正
        Long originalInvoiceId = 1L;

        // 1. 创建冲销单据
        CreditNote creditNote = new CreditNote();
        creditNote.setCreditNoteNo("CN-2024-001");
        creditNote.setCreditNoteDate(LocalDate.now());
        creditNote.setOriginalDocType("INVOICE");
        creditNote.setOriginalDocId(originalInvoiceId);
        creditNote.setOwnerId(1L); // 客户ID
        creditNote.setAmount(new BigDecimal("11300.00"));
        creditNote.setReason("发票金额错误，需要更正");
        creditNote.setNotes("原发票金额有误，冲销后重新开票");
        creditNote.setPosted(false);

        // 保存冲销单据
        creditNoteMapper.insert(creditNote);

        // 2. 过账冲销单据
        FinTransaction transaction = postService.postCreditNoteToLedger(creditNote);

        System.out.println("冲销单据过账成功，生成交易ID: " + transaction.getTransId());
        System.out.println("生成的冲销会计分录:");
        System.out.println("借: 主营业务收入 10,000.00");
        System.out.println("借: 应交税费 1,300.00");
        System.out.println("贷: 应收账款(客户) 11,300.00");
    }

    /**
     * 示例4：撤销过账
     */
    public void unpostDocument() {
        // 撤销发票过账
        Long invoiceId = 1L;
        postService.unpostInvoice(invoiceId);
        System.out.println("发票过账已撤销");

        // 撤销账单过账
        Long billId = 1L;
        postService.unpostBill(billId);
        System.out.println("账单过账已撤销");
    }
}

/*
完整的业务流程：

1. 创建商业单据（Invoice/Bill）
   - 设置单据基本信息（编号、日期、客户/供应商等）
   - 添加条目（Items），指定收入/费用科目
   - 计算金额（含税、不含税、税额）

2. 过账到会计账目（Post to Ledger）
   - Invoice: 借记应收账款，贷记收入科目和税费
   - Bill: 借记费用/资产科目，贷记应付账款
   - 单据状态变为POSTED，不可直接修改

3. 如果需要更正（不可篡改性）
   - 创建Credit Note（冲销单据）
   - 过账Credit Note，生成反向会计分录
   - 原单据保持不变，但会计影响被抵销

4. 撤销过账（Unpost）
   - 删除生成的会计交易
   - 单据状态恢复为未过账，可以重新修改

这个实现完全遵循GnuCash的设计理念：
- 商业单据（Invoices/Bills）和会计账目（Ledger）分离
- 过账操作生成会计交易，但不修改原始单据
- 通过冲销机制实现更正，而不是直接修改
- 保持完整的审计线索
*/
