import request from '../index'

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

// 报销单 API
export const expenseApi = {
  // 查询报销单列表
  getClaimList: (params: {
    pageNum?: number
    pageSize?: number
    claimNo?: string
    startDate?: string
    endDate?: string
    status?: string
  }) => request.post('/finance/biz-expense-claim/list', params),

  // 根据ID查询报销单
  getClaimById: (claimId: number) =>
    request.get(`/finance/biz-expense-claim/${claimId}`),

  // 保存报销单（新增或更新）
  saveClaim: (data: BizExpenseClaim) =>
    request.post('/finance/biz-expense-claim/save', data),

  // 更新报销单
  updateClaim: (data: BizExpenseClaim) =>
    request.put('/finance/biz-expense-claim/update', data),

  // 报销单过账
  postClaim: (claimId: number) =>
    request.post(`/finance/biz-expense-claim/post/${claimId}`),

  // 删除报销单
  deleteClaim: (claimId: number) =>
    request.delete(`/finance/biz-expense-claim/delete/${claimId}`),

  // 查看凭证
  getVoucherById: (voucherId: number) =>
    request.get(`/finance/voucher/${voucherId}`)
}

