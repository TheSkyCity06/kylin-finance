// 凭证相关类型
export interface FinTransaction {
  transId?: number
  voucherNo?: string
  currencyId?: number
  transDate: string
  enterDate?: string
  description: string
  creatorId?: number
  status?: number
  splits?: FinSplit[]
}

export interface FinSplit {
  splitId?: number
  transId?: number
  accountId: number
  accountName?: string
  accountCode?: string
  direction: 'DEBIT' | 'CREDIT'
  amount: number
  memo?: string
  ownerId?: number
  ownerType?: string
}

// 科目相关类型
export interface FinAccount {
  accountId?: number
  accountCode: string
  accountName: string
  accountType: string
  parentId?: number
  balanceDirection?: 'DEBIT' | 'CREDIT' // 余额方向：借方/贷方
  auxiliaryTags?: {
    customer?: boolean // 客户辅助核算
    supplier?: boolean // 供应商辅助核算
    project?: boolean // 项目辅助核算
  }
}

export interface AccountDTO {
  accountId: number
  accountCode: string
  accountName: string
  accountType: string
  parentId?: number
  children?: AccountDTO[]
  isLeaf?: boolean // 是否为末级科目
  path?: string // 科目层级路径
  balance?: number // 科目余额（用于左侧树显示）
  balanceDirection?: 'DEBIT' | 'CREDIT' // 余额方向：借方/贷方
  auxiliaryTags?: {
    customer?: boolean // 客户辅助核算
    supplier?: boolean // 供应商辅助核算
    project?: boolean // 项目辅助核算
  }
}

// 核算相关类型
export interface AccountBalanceDTO {
  accountId: number
  accountCode: string
  accountName: string
  accountType: string
  debitBalance: number
  creditBalance: number
  balance: number
}

export interface TrialBalanceDTO {
  accountId: number
  accountCode: string
  accountName: string
  accountType: string
  periodBeginDebit: number
  periodBeginCredit: number
  periodDebit: number
  periodCredit: number
  periodEndDebit: number
  periodEndCredit: number
}

// 查询相关类型
export interface VoucherQueryDTO {
  voucherNo?: string
  startDate?: string
  endDate?: string
  accountId?: number
  status?: number
  pageNum?: number
  pageSize?: number
}

// 报表相关类型
export interface BalanceSheetDTO {
  reportDate: string
  assets: BalanceSheetItemDTO[]
  totalAssets: number
  liabilities: BalanceSheetItemDTO[]
  totalLiabilities: number
  equity: BalanceSheetItemDTO[]
  totalEquity: number
  totalLiabilitiesAndEquity: number
}

export interface BalanceSheetItemDTO {
  accountCode: string
  accountName: string
  amount: number
  children?: BalanceSheetItemDTO[]
}

// 商业单据相关类型
export interface Invoice {
  invoiceId?: number
  invoiceNo: string
  invoiceDate: string
  dueDate?: string
  customerId?: number
  customerName?: string
  status: string
  totalAmount: number
  taxAmount?: number
  netAmount?: number
  paidAmount?: number // 已付金额
  balanceAmount?: number // 未付余额（计算字段：totalAmount - paidAmount）
  posted?: boolean
  transId?: number
  shippingStatus?: string
  trackingNo?: string
  notes?: string
  items?: InvoiceItem[]
}

export interface InvoiceItem {
  itemId?: number
  invoiceId?: number
  description: string
  incomeAccountId?: number
  quantity?: number
  unitPrice?: number
  amount?: number
  taxRate?: number
  taxAmount?: number
}

export interface Bill {
  billId?: number
  billNo: string
  billDate: string
  dueDate?: string
  vendorId?: number
  vendorName?: string
  status: string
  totalAmount: number
  taxAmount?: number
  netAmount?: number
  paidAmount?: number // 已付金额
  balanceAmount?: number // 未付余额（计算字段：totalAmount - paidAmount）
  posted?: boolean
  transId?: number
  notes?: string
  items?: BillItem[]
}

// 统一的商业单据类型（用于单据管理页面）
export interface BusinessDocument {
  documentType: 'INVOICE' | 'BILL' // 单据类型
  documentId?: number // 单据ID（invoiceId 或 billId）
  documentNo: string // 单据编号（invoiceNo 或 billNo）
  documentDate: string // 单据日期（invoiceDate 或 billDate）
  dueDate?: string // 到期日
  ownerId?: number // 往来单位ID（customerId 或 vendorId）
  ownerName?: string // 往来单位名称（customerName 或 vendorName）
  status: string // 状态
  totalAmount: number // 总金额
  taxAmount?: number // 税额
  netAmount?: number // 不含税金额
  paidAmount?: number // 已付金额
  balanceAmount?: number // 未付余额
  posted?: boolean // 是否已过账
  transId?: number // 凭证ID
  notes?: string // 备注
}

export interface BillItem {
  itemId?: number
  billId?: number
  description: string
  expenseAccountId?: number
  quantity?: number
  unitPrice?: number
  amount?: number
  taxRate?: number
  taxAmount?: number
}

export interface PageResult<T> {
  records: T[]
  total: number
  size: number
  current: number
  pages: number
}

export interface CashFlowDTO {
  reportDate: string
  operatingActivities: CashFlowItemDTO[]
  netOperatingCashFlow: number
  investingActivities: CashFlowItemDTO[]
  netInvestingCashFlow: number
  financingActivities: CashFlowItemDTO[]
  netFinancingCashFlow: number
  netIncreaseInCash: number
  beginningCashBalance: number
  endingCashBalance: number
}

export interface CashFlowItemDTO {
  itemName: string
  amount: number
  description?: string
}

// API响应类型
export interface ApiResponse<T = any> {
  code: number
  msg: string
  data: T
}

// 报销单相关类型
export interface BizExpenseClaim {
  claimId?: number
  claimNo?: string
  applicantId: number
  applicantName?: string
  claimDate: string
  totalAmount: number
  status: 'DRAFT' | 'POSTED' | 'REVERSED'
  creditAccountId: number
  creditAccountName?: string
  notes?: string
  voucherId?: number
  details?: BizExpenseClaimDetail[]
}

export interface BizExpenseClaimDetail {
  detailId?: number
  claimId?: number
  debitAccountId: number
  debitAccountName?: string
  amount: number
  description?: string
}

// 往来单位相关类型（客户、供应商、员工等）
export interface Owner {
  ownerId?: number
  name: string
  code?: string
  ownerType: 'CUSTOMER' | 'VENDOR' | 'EMPLOYEE' | string
  accountId?: number
  accountName?: string
  contactName?: string
  contactPhone?: string
  contactEmail?: string
  address?: string
}