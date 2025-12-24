import request from '@/utils/request'
import type { VoucherQueryDTO, AccountDTO, AccountBalanceDTO, TrialBalanceDTO, BalanceSheetDTO, CashFlowDTO, FinTransaction, FinAccount, Invoice, PageResult } from '@/types/finance'

// 凭证管理
export const voucherApi = {
  // 录入凭证
  addVoucher: (data: Omit<FinTransaction, 'transId' | 'voucherNo' | 'enterDate'>) =>
    request.post('/finance/voucher/add', data),

  // 更新凭证
  updateVoucher: (data: FinTransaction) =>
    request.put('/finance/voucher/update', data),

  // 删除凭证
  deleteVoucher: (transId: number) =>
    request.delete(`/finance/voucher/delete/${transId}`),

  // 审核凭证
  auditVoucher: (transId: number) =>
    request.post(`/finance/voucher/audit/${transId}`),

  // 查询凭证
  queryVouchers: (params: VoucherQueryDTO) =>
    request.post('/finance/voucher/query', params),

  // 根据ID查询凭证
  getVoucherById: (transId: number) =>
    request.get(`/finance/voucher/${transId}`),

  // 生成凭证号
  generateVoucherNo: () =>
    request.get('/finance/voucher/generateNo')
}

// 科目管理
export const accountApi = {
  // 获取科目树
  getAccountTree: () =>
    request.get('/finance/account/tree'),

  // 获取子科目
  getChildrenByParentId: (parentId: number) =>
    request.get(`/finance/account/children/${parentId}`),

  // 添加科目
  addAccount: (data: Omit<FinAccount, 'accountId'>) =>
    request.post('/finance/account/add', data),

  // 更新科目
  updateAccount: (data: FinAccount) =>
    request.put('/finance/account/update', data),

  // 删除科目
  deleteAccount: (accountId: number) =>
    request.delete(`/finance/account/delete/${accountId}`),

  // 根据ID查询科目
  getAccountById: (accountId: number) =>
    request.get(`/finance/account/${accountId}`),

  // 判断是否为末级科目
  isLeafAccount: (accountId: number) =>
    request.get(`/finance/account/${accountId}/isLeaf`),

  // 获取所有末级科目列表（用于凭证录入）
  getLeafAccounts: () =>
    request.get('/finance/account/leaf'),

  // 获取科目的层级路径
  getAccountPath: (accountId: number) =>
    request.get(`/finance/account/${accountId}/path`)
}

// 核算功能
export const accountingApi = {
  // 计算科目余额
  calculateAccountBalance: (accountId: number, date?: string) =>
    request.get(`/finance/accounting/balance/${accountId}`, { params: { date } }),

  // 计算所有科目余额
  calculateAllAccountBalances: (date?: string) =>
    request.get('/finance/accounting/balance/all', { params: { date } }),

  // 生成试算平衡表
  generateTrialBalance: (startDate: string, endDate: string) =>
    request.get('/finance/accounting/trialBalance', { params: { startDate, endDate } }),

  // 验证试算平衡
  verifyTrialBalance: (date?: string) =>
    request.get('/finance/accounting/verifyBalance', { params: { date } })
}

// 财务报表
export const reportApi = {
  // 生成资产负债表
  generateBalanceSheet: (date?: string) =>
    request.get('/finance/report/balanceSheet', { params: { date } }),

  // 导出资产负债表到Excel
  exportBalanceSheet: (date?: string) =>
    request.get('/finance/report/balance-sheet/export', { 
      params: { date },
      responseType: 'blob' // 重要：设置响应类型为blob以处理Excel文件
    }),

  // 导出试算平衡表到Excel
  exportTrialBalance: (startDate: string, endDate: string) =>
    request.get('/finance/report/trial-balance/export', {
      params: { startDate, endDate },
      responseType: 'blob' // 重要：设置响应类型为blob以处理Excel文件
    }),

  // 生成现金流量表
  generateCashFlowStatement: (startDate: string, endDate: string) =>
    request.get('/finance/report/cashFlow', { params: { startDate, endDate } }),

  // 导出现金流量表到Excel
  exportCashFlow: (startDate: string, endDate: string) =>
    request.get('/reports/cash-flow/export', {
      params: { startDate, endDate },
      responseType: 'blob' // 重要：设置响应类型为blob以处理Excel文件
    })
}

// 商业单据管理
export const documentApi = {
  // 获取往来单位列表（使用 DocumentController 端点，返回 Owner 实体）
  getOwnerList: (ownerType?: string) =>
    request.get('/finance/document/owner/list', { params: ownerType ? { ownerType } : {} }),
  
  // 获取往来单位列表（使用 FinanceController 端点，返回标准化的 PartnerDTO）
  getPartnerList: (category?: string) =>
    request.get('/finance/owner/list', { params: category ? { category } : {} }),

  // 创建往来单位
  createOwner: (data: any) =>
    request.post('/finance/document/owner/create', data),

  // 更新往来单位
  updateOwner: (data: any) =>
    request.put('/finance/document/owner/update', data),

  // 删除往来单位
  deleteOwner: (ownerId: number) =>
    request.delete(`/finance/document/owner/delete/${ownerId}`),

  // 根据ID查询往来单位
  getOwnerById: (ownerId: number) =>
    request.get(`/finance/document/owner/${ownerId}`),

  // 获取发票列表
  getInvoiceList: (pageNum: number = 1, pageSize: number = 10) =>
    request.get('/finance/document/invoice/list', { params: { pageNum, pageSize } }),

  // 创建发票
  createInvoice: (data: any) =>
    request.post('/finance/document/invoice/create', data),

  // 更新发票
  updateInvoice: (data: any) =>
    request.put('/finance/document/invoice/update', data),

  // 删除发票
  deleteInvoice: (invoiceId: number) =>
    request.delete(`/finance/document/invoice/delete/${invoiceId}`),

  // 根据ID查询发票
  getInvoiceById: (invoiceId: number) =>
    request.get(`/finance/document/invoice/${invoiceId}`),

  // 审核发票
  validateInvoice: (invoiceId: number) =>
    request.post(`/finance/document/invoice/validate/${invoiceId}`),

  // 过账发票
  postInvoice: (invoiceId: number) =>
    request.post(`/finance/document/invoice/post/${invoiceId}`),

  // 作废发票
  cancelInvoice: (invoiceId: number) =>
    request.post(`/finance/document/invoice/cancel/${invoiceId}`),

  // 获取客户的未结清发票
  getUnpaidInvoices: (customerId: number) =>
    request.get(`/finance/document/invoice/unpaid/${customerId}`),

  // 获取账单列表
  getBillList: (pageNum: number = 1, pageSize: number = 10) =>
    request.get('/finance/document/bill/list', { params: { pageNum, pageSize } }),

  // 创建账单
  createBill: (data: any) =>
    request.post('/finance/document/bill/create', data),

  // 更新账单
  updateBill: (data: any) =>
    request.put('/finance/document/bill/update', data),

  // 删除账单
  deleteBill: (billId: number) =>
    request.delete(`/finance/document/bill/delete/${billId}`),

  // 根据ID查询账单
  getBillById: (billId: number) =>
    request.get(`/finance/document/bill/${billId}`),

  // 审核账单
  validateBill: (billId: number) =>
    request.post(`/finance/document/bill/validate/${billId}`),

  // 过账账单
  postBill: (billId: number) =>
    request.post(`/finance/document/bill/post/${billId}`),

  // 作废账单
  cancelBill: (billId: number) =>
    request.post(`/finance/document/bill/cancel/${billId}`),

  // 获取供应商的未结清账单
  getUnpaidBills: (vendorId: number) =>
    request.get(`/finance/document/bill/unpaid/${vendorId}`)
}

// 支付管理
export const paymentApi = {
  // 处理客户支付
  processCustomerPayment: (ownerId: number, amount: number, accountId: number) =>
    request.post('/finance/payment/customer', null, {
      params: { ownerId, amount, accountId }
    }),

  // 处理供应商支付
  processVendorPayment: (ownerId: number, amount: number, accountId: number) =>
    request.post('/finance/payment/vendor', null, {
      params: { ownerId, amount, accountId }
    }),

  // 通用支付处理
  processPayment: (data: {
    ownerId: number
    amount: number
    accountId: number
    paymentType: string
  }) => {
    if (data.paymentType === 'RECEIPT') {
      return paymentApi.processCustomerPayment(data.ownerId, data.amount, data.accountId)
    } else {
      return paymentApi.processVendorPayment(data.ownerId, data.amount, data.accountId)
    }
  }
}

// 报销单管理
export const expenseClaimApi = {
  // 提交报销单
  submitClaim: (data: any) =>
    request.post('/finance/expense-claim/submit', data),

  // 审批报销单
  approveClaim: (claimId: number) =>
    request.post(`/finance/expense-claim/approve/${claimId}`),

  // 过账报销单
  postClaim: (claimId: number) =>
    request.post(`/finance/expense-claim/post/${claimId}`)
}

// 收付款单管理
export const receiptPaymentApi = {
  // 保存收付款单
  saveReceiptPayment: (data: any) =>
    request.post('/finance/biz-receipt-payment/save', data),

  // 保存并过账收付款单
  saveAndPostReceiptPayment: (data: any) =>
    request.post('/finance/biz-receipt-payment/save-and-post', data),

  // 获取收付款单列表
  getReceiptPaymentList: (params: {
    pageNum?: number
    pageSize?: number
    type?: string
    status?: number
  }) =>
    request.get('/finance/biz-receipt-payment/list', { params }),

  // 根据ID查询收付款单
  getReceiptPaymentById: (id: number) =>
    request.get(`/finance/biz-receipt-payment/${id}`)
}