# GnuCash 风格商业单据流转逻辑实现

本文档描述了麒麟财务管理系统中实现的 GnuCash 风格的商业单据流转逻辑。

## 核心概念

### 1. Invoice（发票）
- **用途**: 向客户收取款项的商业单据
- **过账规则**: 借记应收账款，贷记收入科目和税费
- **示例**:
  ```
  借: 应收账款(客户)    11,300.00
  贷: 主营业务收入      10,000.00
  贷: 应交税费          1,300.00
  ```

### 2. Bill（账单）
- **用途**: 向供应商支付款项的商业单据
- **过账规则**: 借记费用/资产科目，贷记应付账款
- **示例**:
  ```
  借: 管理费用          1,130.00
  贷: 应付账款(供应商)    1,130.00
  ```

### 3. Credit Note（冲销单据）
- **用途**: 更正已过账的发票或账单
- **过账规则**: 生成反向会计分录
- **示例** (冲销上面的发票):
  ```
  借: 主营业务收入      10,000.00
  借: 应交税费          1,300.00
  贷: 应收账款(客户)    11,300.00
  ```

## 数据模型

### 核心实体

#### Invoice (发票)
```java
@TableName("fin_invoice")
public class Invoice extends BaseEntity {
    private String invoiceNo;           // 发票编号
    private LocalDate invoiceDate;      // 发票日期
    private LocalDate dueDate;          // 到期日期
    private Long customerId;            // 客户ID
    private String status;              // 状态: DRAFT/OPEN/PAID/CANCELLED
    private BigDecimal totalAmount;     // 总金额
    private Boolean posted;             // 是否已过账
    private Long transId;               // 关联交易ID
    private List<InvoiceItem> items;    // 条目列表
}
```

#### Bill (账单)
```java
@TableName("fin_bill")
public class Bill extends BaseEntity {
    private String billNo;              // 账单编号
    private LocalDate billDate;         // 账单日期
    private Long vendorId;              // 供应商ID
    private String status;              // 状态
    private BigDecimal totalAmount;     // 总金额
    private Boolean posted;             // 是否已过账
    private Long transId;               // 关联交易ID
    private List<BillItem> items;       // 条目列表
}
```

#### Credit Note (冲销单据)
```java
@TableName("fin_credit_note")
public class CreditNote extends BaseEntity {
    private String creditNoteNo;        // 冲销单据编号
    private LocalDate creditNoteDate;   // 冲销日期
    private String originalDocType;     // 原单据类型: INVOICE/BILL
    private Long originalDocId;         // 原单据ID
    private BigDecimal amount;          // 冲销金额
    private String reason;              // 冲销原因
    private Boolean posted;             // 是否已过账
    private Long transId;               // 关联交易ID
}
```

### 条目实体

#### InvoiceItem (发票条目)
```java
@TableName("fin_invoice_item")
public class InvoiceItem extends BaseEntity {
    private Long invoiceId;             // 发票ID
    private String description;         // 项目描述
    private Long incomeAccountId;       // 收入科目ID
    private BigDecimal quantity;        // 数量
    private BigDecimal unitPrice;       // 单价
    private BigDecimal amount;          // 金额
    private BigDecimal taxRate;         // 税率
    private BigDecimal taxAmount;       // 税额
}
```

#### BillItem (账单条目)
```java
@TableName("fin_bill_item")
public class BillItem extends BaseEntity {
    private Long billId;                // 账单ID
    private String description;         // 项目描述
    private Long expenseAccountId;      // 费用科目ID
    private BigDecimal quantity;        // 数量
    private BigDecimal unitPrice;       // 单价
    private BigDecimal amount;          // 金额
    private BigDecimal taxRate;         // 税率
    private BigDecimal taxAmount;       // 税额
}
```

## 服务接口

### IPostService (过账服务)
```java
public interface IPostService {
    // 发票过账
    FinTransaction postInvoiceToLedger(Invoice invoice);

    // 账单过账
    FinTransaction postBillToLedger(Bill bill);

    // 冲销单据过账
    FinTransaction postCreditNoteToLedger(CreditNote creditNote);

    // 撤销过账
    void unpostInvoice(Long invoiceId);
    void unpostBill(Long billId);
    void unpostCreditNote(Long creditNoteId);
}
```

## 业务流程

### 1. 创建商业单据
```java
// 创建发票
Invoice invoice = new Invoice();
invoice.setInvoiceNo("INV-2024-001");
invoice.setCustomerId(customerId);
invoice.setTotalAmount(new BigDecimal("11300.00"));

// 添加条目
InvoiceItem item = new InvoiceItem();
item.setIncomeAccountId(6001L); // 收入科目
item.setAmount(new BigDecimal("10000.00"));
item.setTaxAmount(new BigDecimal("1300.00"));
```

### 2. 过账到账目
```java
// 过账发票
FinTransaction transaction = postService.postInvoiceToLedger(invoice);
// 生成会计分录并保存交易
```

### 3. 不可篡改性
- 过账后单据状态变为 `POSTED`
- 禁止直接修改已过账单据
- 如需更正，必须创建冲销单据

### 4. 更正流程
```java
// 创建冲销单据
CreditNote creditNote = new CreditNote();
creditNote.setOriginalDocType("INVOICE");
creditNote.setOriginalDocId(invoiceId);
creditNote.setAmount(invoice.getTotalAmount());
creditNote.setReason("金额错误，需要更正");

// 过账冲销单据
FinTransaction reverseTransaction = postService.postCreditNoteToLedger(creditNote);
```

## 数据库设计

### 新增表结构

#### fin_invoice (发票表)
- 基本信息：编号、日期、客户、金额
- 状态管理：status、posted、trans_id
- 关联关系：customer_id、commodity_id

#### fin_bill (账单表)
- 基本信息：编号、日期、供应商、金额
- 状态管理：status、posted、trans_id
- 关联关系：vendor_id、commodity_id

#### fin_invoice_item (发票条目表)
- 项目明细：描述、数量、单价、金额
- 会计关联：income_account_id（收入科目）
- 税务信息：tax_rate、tax_amount

#### fin_bill_item (账单条目表)
- 项目明细：描述、数量、单价、金额
- 会计关联：expense_account_id（费用科目）
- 税务信息：tax_rate、tax_amount

#### fin_credit_note (冲销单据表)
- 冲销信息：编号、日期、原单据引用
- 金额和原因：amount、reason
- 状态管理：posted、trans_id

## 关键特性

### 1. 会计完整性
- 过账时自动生成正确的会计分录
- 确保借贷平衡
- 关联正确的会计科目

### 2. 不可篡改性
- 已过账单据不可修改
- 通过冲销机制实现更正
- 保持完整的审计线索

### 3. 业务实体关联
- 发票关联客户应收账款
- 账单关联供应商应付账款
- 支持多币种和税务计算

### 4. 状态管理
- DRAFT → OPEN → PAID/CANCELLED
- POSTED 状态保护已过账单据
- 支持撤销过账操作

## API 接口

### 过账相关接口
```
POST /finance/invoice/post/{invoiceId}      # 发票过账
POST /finance/bill/post/{billId}            # 账单过账
POST /finance/creditnote/post/{creditNoteId} # 冲销单据过账

POST /finance/invoice/unpost/{invoiceId}    # 撤销发票过账
POST /finance/bill/unpost/{billId}          # 撤销账单过账
POST /finance/creditnote/unpost/{creditNoteId} # 撤销冲销单据过账
```

## 使用示例

完整的业务流程演示请参考 `demo/gnucash_integration_demo.java` 文件。

这个实现完全遵循 GnuCash 的设计理念，将商业单据和会计账目分离，通过过账机制建立联系，确保数据的完整性和不可篡改性。

