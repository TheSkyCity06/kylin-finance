<template>
  <div class="business-document-manager">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>商业单据管理</span>
          <div class="header-actions">
            <el-button type="primary" :icon="Plus" @click="handleAddInvoice">新增发票</el-button>
            <el-button type="success" :icon="Plus" @click="handleAddBill">新增账单</el-button>
            <el-button type="info" :icon="Refresh" @click="loadDocumentList">刷新</el-button>
          </div>
        </div>
      </template>

      <!-- 数据表格 -->
      <el-table
        :data="documentList"
        border
        stripe
        v-loading="loading"
        style="width: 100%"
        @selection-change="handleSelectionChange"
        @row-click="handleRowClick"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column label="单据类型" width="120">
          <template #default="scope">
            <el-tag :type="scope.row.documentType === 'INVOICE' ? 'success' : 'warning'">
              {{ scope.row.documentType === 'INVOICE' ? '销售发票' : '采购账单' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="documentNo" label="单据编号" width="150" />
        
        <el-table-column label="往来单位" width="200">
          <template #default="scope">
            <span>{{ scope.row.ownerName || (scope.row.documentType === 'INVOICE' ? `客户ID: ${scope.row.ownerId}` : `供应商ID: ${scope.row.ownerId}`) }}</span>
          </template>
        </el-table-column>

        <el-table-column label="金额" width="120" align="right">
          <template #default="scope">
            <span class="amount-text">¥{{ formatAmount(scope.row.totalAmount) }}</span>
          </template>
        </el-table-column>

        <el-table-column label="已付金额" width="120" align="right">
          <template #default="scope">
            <span class="paid-amount">¥{{ formatAmount(scope.row.paidAmount || 0) }}</span>
          </template>
        </el-table-column>

        <el-table-column label="未付余额" width="120" align="right">
          <template #default="scope">
            <span :class="getBalanceClass(scope.row)">
              ¥{{ formatAmount(getBalanceAmount(scope.row)) }}
            </span>
          </template>
        </el-table-column>

        <el-table-column prop="dueDate" label="到期日" width="120">
          <template #default="scope">
            {{ scope.row.dueDate || '-' }}
          </template>
        </el-table-column>

        <el-table-column label="状态" width="120">
          <template #default="scope">
            <el-tag :type="getStatusType(scope.row.status)" :effect="scope.row.posted ? 'dark' : 'plain'">
              {{ getStatusText(scope.row) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="凭证ID" width="120">
          <template #default="scope">
            <el-link
              v-if="scope.row.posted && scope.row.transId"
              type="primary"
              @click.stop="handleViewVoucher(scope.row.transId)"
              style="cursor: pointer"
            >
              {{ scope.row.transId }}
            </el-link>
            <span v-else style="color: #909399">-</span>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="150" fixed="right">
          <template #default="scope">
            <el-button
              type="primary"
              size="small"
              :icon="Check"
              @click.stop="handlePost(scope.row)"
              :disabled="scope.row.posted || scope.row.status === 'POSTED'"
              :loading="postingIds.includes(scope.row.documentId!)"
            >
              过账
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handlePageChange"
        />
      </div>
    </el-card>

    <!-- 查看凭证弹窗 -->
    <el-dialog
      v-model="voucherDialogVisible"
      title="凭证明细"
      width="900px"
      :close-on-click-modal="false"
      @close="handleVoucherDialogClose"
    >
      <div v-if="currentVoucher" class="voucher-detail" v-loading="loadingVoucher">
        <!-- 凭证基本信息 -->
        <el-descriptions :column="2" border style="margin-bottom: 20px">
          <el-descriptions-item label="凭证号">{{ currentVoucher.voucherNo || '-' }}</el-descriptions-item>
          <el-descriptions-item label="交易日期">{{ currentVoucher.transDate || '-' }}</el-descriptions-item>
          <el-descriptions-item label="摘要" :span="2">{{ currentVoucher.description || '-' }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentVoucher.status === 1 ? 'success' : 'warning'">
              {{ currentVoucher.status === 1 ? '已审核' : '草稿' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="录入时间">{{ currentVoucher.enterDate || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 分录明细 -->
        <div class="splits-section">
          <h4 style="margin-bottom: 15px">分录明细</h4>
          <el-table
            :data="splitTableData"
            border
            stripe
            style="width: 100%"
            :summary-method="getSummaries"
            show-summary
          >
            <el-table-column prop="accountCode" label="科目代码" width="120" />
            <el-table-column prop="accountName" label="科目名称" min-width="200" />
            <el-table-column label="借方金额" width="150" align="right">
              <template #default="scope">
                <span v-if="scope.row.direction === 'DEBIT'" class="debit-amount">
                  ¥{{ formatAmount(scope.row.amount) }}
                </span>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column label="贷方金额" width="150" align="right">
              <template #default="scope">
                <span v-if="scope.row.direction === 'CREDIT'" class="credit-amount">
                  ¥{{ formatAmount(scope.row.amount) }}
                </span>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column prop="memo" label="摘要" min-width="200" />
          </el-table>

          <!-- 借贷平衡校验 -->
          <div class="balance-check" style="margin-top: 20px">
            <el-alert
              :type="isBalanceValid ? 'success' : 'error'"
              :title="balanceCheckMessage"
              :closable="false"
              show-icon
            />
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh, Check, Plus, Printer } from '@element-plus/icons-vue'
import { documentApi, voucherApi } from '@/api/finance'
import type { Invoice, Bill, BusinessDocument, PageResult, FinTransaction, FinSplit } from '@/types/finance'

const router = useRouter()

const documentList = ref<BusinessDocument[]>([])
const loading = ref(false)
const postingIds = ref<number[]>([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const voucherDialogVisible = ref(false)
const currentVoucher = ref<FinTransaction | null>(null)
const loadingVoucher = ref(false)
const selectedDocuments = ref<BusinessDocument[]>([]) // 选中的单据列表

// 将发票转换为统一单据格式
const convertInvoiceToDocument = (invoice: Invoice): BusinessDocument => {
  return {
    documentType: 'INVOICE',
    documentId: invoice.invoiceId,
    documentNo: invoice.invoiceNo,
    documentDate: invoice.invoiceDate,
    dueDate: invoice.dueDate,
    ownerId: invoice.customerId,
    ownerName: invoice.customerName,
    status: invoice.status,
    totalAmount: invoice.totalAmount,
    taxAmount: invoice.taxAmount,
    netAmount: invoice.netAmount,
    paidAmount: invoice.paidAmount,
    balanceAmount: invoice.balanceAmount,
    posted: invoice.posted,
    transId: invoice.transId,
    notes: invoice.notes
  }
}

// 将账单转换为统一单据格式
const convertBillToDocument = (bill: Bill): BusinessDocument => {
  return {
    documentType: 'BILL',
    documentId: bill.billId,
    documentNo: bill.billNo,
    documentDate: bill.billDate,
    dueDate: bill.dueDate,
    ownerId: bill.vendorId,
    ownerName: bill.vendorName,
    status: bill.status,
    totalAmount: bill.totalAmount,
    taxAmount: bill.taxAmount,
    netAmount: bill.netAmount,
    paidAmount: bill.paidAmount,
    balanceAmount: bill.balanceAmount,
    posted: bill.posted,
    transId: bill.transId,
    notes: bill.notes
  }
}

// 加载所有单据列表（发票+账单）
const loadDocumentList = async () => {
  loading.value = true
  try {
    // 并行加载发票和账单（获取所有数据，前端分页）
    // 注意：实际项目中应该在后端实现统一的单据查询接口
    const [invoiceResponse, billResponse] = await Promise.all([
      documentApi.getInvoiceList(1, 1000), // 获取所有发票
      documentApi.getBillList(1, 1000) // 获取所有账单
    ])

    const documents: BusinessDocument[] = []

    // 处理发票数据
    if (invoiceResponse.code === 200 && invoiceResponse.data) {
      const invoices = invoiceResponse.data.records || []
      documents.push(...invoices.map(convertInvoiceToDocument))
    }

    // 处理账单数据
    if (billResponse.code === 200 && billResponse.data) {
      const bills = billResponse.data.records || []
      documents.push(...bills.map(convertBillToDocument))
    }

    // 按日期倒序排序（最新的在前）
    documents.sort((a, b) => {
      const dateA = a.documentDate ? new Date(a.documentDate).getTime() : 0
      const dateB = b.documentDate ? new Date(b.documentDate).getTime() : 0
      return dateB - dateA
    })

    // 前端分页处理
    total.value = documents.length
    const start = (currentPage.value - 1) * pageSize.value
    const end = start + pageSize.value
    documentList.value = documents.slice(start, end)
  } catch (error: any) {
    ElMessage.error(error.message || '加载失败')
    documentList.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// 过账前校验
const validateBeforePost = (document: BusinessDocument): string | null => {
  // 1. 检查单据是否已保存
  if (!document.documentId) {
    return '单据ID不存在'
  }

  // 2. 检查单据状态是否为 VALIDATED（已审核）
  if (document.status !== 'VALIDATED') {
    const documentTypeName = document.documentType === 'INVOICE' ? '发票' : '账单'
    return `当前状态为 ${document.status}，只有已审核状态的${documentTypeName}才能过账。请先审核${documentTypeName}。`
  }

  // 3. 检查金额是否不为0
  if (document.totalAmount === undefined || document.totalAmount === null || document.totalAmount <= 0) {
    return '单据金额不能为0，无法过账'
  }

  // 4. 检查是否已过账
  if (document.posted) {
    return '单据已过账，无法重复过账'
  }

  return null
}

// 过账操作
const handlePost = async (document: BusinessDocument) => {
  // 过账前校验
  const validationError = validateBeforePost(document)
  if (validationError) {
    ElMessage.warning(validationError)
    return
  }

  const documentTypeName = document.documentType === 'INVOICE' ? '发票' : '账单'

  try {
    await ElMessageBox.confirm(
      `确定要过账${documentTypeName} "${document.documentNo}" 吗？过账后将生成财务凭证，单据将被锁定无法修改。`,
      '确认过账',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    postingIds.value.push(document.documentId!)
    
    // 根据单据类型调用不同的API
    const response = document.documentType === 'INVOICE'
      ? await documentApi.postInvoice(document.documentId!)
      : await documentApi.postBill(document.documentId!)
    
    if (response.code === 200) {
      // 过账成功后重新加载单据数据以获取凭证ID
      try {
        let updatedDocument: BusinessDocument | null = null
        if (document.documentType === 'INVOICE') {
          const invoiceResponse = await documentApi.getInvoiceById(document.documentId!)
          if (invoiceResponse.code === 200 && invoiceResponse.data) {
            updatedDocument = convertInvoiceToDocument(invoiceResponse.data)
          }
        } else {
          const billResponse = await documentApi.getBillById(document.documentId!)
          if (billResponse.code === 200 && billResponse.data) {
            updatedDocument = convertBillToDocument(billResponse.data)
          }
        }

        // 更新本地状态
        const index = documentList.value.findIndex(item => item.documentId === document.documentId)
        if (index !== -1 && updatedDocument) {
          documentList.value[index] = updatedDocument
        } else {
          // 如果更新失败，刷新整个列表
          await loadDocumentList()
        }

        // 显示凭证已生成的消息
        if (updatedDocument?.transId) {
          ElMessage.success({
            message: `过账成功！凭证已生成，凭证ID：${updatedDocument.transId}`,
            duration: 5000
          })
        } else {
          ElMessage.success('过账成功！凭证已生成')
        }
      } catch (loadError) {
        console.error('重新加载单据数据失败:', loadError)
        // 刷新整个列表
        await loadDocumentList()
        ElMessage.success('过账成功！凭证已生成')
      }
    } else {
      ElMessage.error(response.msg || '过账失败')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      const errorMessage = error?.response?.data?.msg || 
                           error?.message || 
                           '过账失败，请检查数据是否正确'
      ElMessage.error(errorMessage)
      console.error('过账失败:', error)
    }
  } finally {
    const index = postingIds.value.indexOf(document.documentId!)
    if (index > -1) {
      postingIds.value.splice(index, 1)
    }
  }
}

// 获取状态类型（用于标签颜色）
const getStatusType = (status: string): string => {
  switch (status?.toUpperCase()) {
    case 'DRAFT':
      return 'info' // 灰色
    case 'POSTED':
      return 'primary' // 蓝色
    case 'PAID':
      return 'success' // 绿色
    case 'OPEN':
      return 'warning' // 橙色
    case 'CANCELLED':
      return 'danger' // 红色
    default:
      return 'info'
  }
}

// 获取状态文本
const getStatusText = (document: BusinessDocument): string => {
  if (document.posted || document.status === 'POSTED') {
    return '已过账'
  }
  
  switch (document.status?.toUpperCase()) {
    case 'DRAFT':
      return '草稿'
    case 'OPEN':
      return '开放'
    case 'PAID':
      return '已支付'
    case 'CANCELLED':
      return '已取消'
    case 'PARTIAL':
      return '部分支付'
    default:
      return document.status || '未知'
  }
}

// 格式化金额
const formatAmount = (amount: number | undefined): string => {
  if (amount === undefined || amount === null) {
    return '0.00'
  }
  return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

// 计算未付余额
const getBalanceAmount = (document: BusinessDocument): number => {
  const total = document.totalAmount || 0
  const paid = document.paidAmount || 0
  return total - paid
}

// 获取余额样式类
const getBalanceClass = (document: BusinessDocument): string => {
  const balance = getBalanceAmount(document)
  if (balance <= 0) {
    return 'balance-paid'
  }
  return 'balance-unpaid'
}

// 处理表格行选中变化
const handleSelectionChange = (selection: BusinessDocument[]) => {
  selectedDocuments.value = selection
  // 触发自定义事件，通知工具栏更新按钮状态
  window.dispatchEvent(new CustomEvent('invoice-selection-change', {
    detail: { selectedCount: selection.length, selectedIds: selection.map(d => d.documentId) }
  }))
}

// 处理行点击事件
const handleRowClick = (row: BusinessDocument) => {
  if (row.documentType === 'INVOICE') {
    router.push(`/document/invoice/${row.documentId}`)
  } else {
    router.push(`/document/bill/${row.documentId}`)
  }
}

// 新增发票
const handleAddInvoice = () => {
  router.push('/document/invoice/add')
}

// 新增账单
const handleAddBill = () => {
  router.push('/document/bill/add')
}

// 分页变化
const handleSizeChange = (size: number) => {
  pageSize.value = size
  currentPage.value = 1
  loadDocumentList()
}

const handlePageChange = (page: number) => {
  currentPage.value = page
  loadDocumentList()
}

// 查看凭证
const handleViewVoucher = async (transId: number) => {
  voucherDialogVisible.value = true
  loadingVoucher.value = true
  currentVoucher.value = null
  
  try {
    const response = await voucherApi.getVoucherById(transId)
    if (response.code === 200) {
      currentVoucher.value = response.data
    } else {
      ElMessage.error(response.msg || '获取凭证详情失败')
      voucherDialogVisible.value = false
    }
  } catch (error: any) {
    ElMessage.error(error.message || '获取凭证详情失败')
    voucherDialogVisible.value = false
  } finally {
    loadingVoucher.value = false
  }
}

// 关闭凭证弹窗
const handleVoucherDialogClose = () => {
  currentVoucher.value = null
}

// 分录表格数据
const splitTableData = computed(() => {
  if (!currentVoucher.value || !currentVoucher.value.splits || !Array.isArray(currentVoucher.value.splits)) {
    return []
  }
  return currentVoucher.value.splits.map((split: FinSplit) => ({
    accountCode: split.accountCode || '',
    accountName: split.accountName || `科目ID: ${split.accountId}`,
    direction: split.direction,
    amount: split.amount || 0,
    memo: split.memo || ''
  }))
})

// 借贷平衡校验
const isBalanceValid = computed(() => {
  if (!currentVoucher.value || !currentVoucher.value.splits || !Array.isArray(currentVoucher.value.splits)) {
    return false
  }
  
  const totalDebit = currentVoucher.value.splits
    .filter((split: FinSplit) => split && split.direction === 'DEBIT')
    .reduce((sum: number, split: FinSplit) => sum + (split.amount || 0), 0)
  
  const totalCredit = currentVoucher.value.splits
    .filter((split: FinSplit) => split && split.direction === 'CREDIT')
    .reduce((sum: number, split: FinSplit) => sum + (split.amount || 0), 0)
  
  return Math.abs(totalDebit - totalCredit) < 0.01 // 允许0.01的误差
})

const balanceCheckMessage = computed(() => {
  if (!currentVoucher.value || !currentVoucher.value.splits || !Array.isArray(currentVoucher.value.splits)) {
    return '无分录数据'
  }
  
  const totalDebit = currentVoucher.value.splits
    .filter((split: FinSplit) => split && split.direction === 'DEBIT')
    .reduce((sum: number, split: FinSplit) => sum + (split.amount || 0), 0)
  
  const totalCredit = currentVoucher.value.splits
    .filter((split: FinSplit) => split && split.direction === 'CREDIT')
    .reduce((sum: number, split: FinSplit) => sum + (split.amount || 0), 0)
  
  const difference = Math.abs(totalDebit - totalCredit)
  
  if (difference < 0.01) {
    return `借贷平衡 ✓ 借方合计：¥${formatAmount(totalDebit)}，贷方合计：¥${formatAmount(totalCredit)}`
  } else {
    return `借贷不平衡 ✗ 借方合计：¥${formatAmount(totalDebit)}，贷方合计：¥${formatAmount(totalCredit)}，差额：¥${formatAmount(difference)}`
  }
})

// 表格合计行
interface SummaryParam {
  columns: Array<{ property?: string }>
  data: Array<{ direction: string; amount: number }>
}

const getSummaries = (param: SummaryParam) => {
  const { columns, data } = param
  const sums: string[] = []
  
  columns.forEach((column, index: number) => {
    if (index === 0) {
      sums[index] = '合计'
      return
    }
    
    if (column.property === 'accountName' || column.property === 'memo') {
      sums[index] = ''
      return
    }
    
    if (column.property === 'accountCode') {
      sums[index] = ''
      return
    }
    
    // 借方合计
    if (index === 2) {
      const values = data
        .map((item) => item.direction === 'DEBIT' ? Number(item.amount) : 0)
      const sum = values.reduce((prev: number, curr: number) => {
        return prev + curr
      }, 0)
      sums[index] = `¥${formatAmount(sum)}`
      return
    }
    
    // 贷方合计
    if (index === 3) {
      const values = data
        .map((item) => item.direction === 'CREDIT' ? Number(item.amount) : 0)
      const sum = values.reduce((prev: number, curr: number) => {
        return prev + curr
      }, 0)
      sums[index] = `¥${formatAmount(sum)}`
      return
    }
    
    sums[index] = ''
  })
  
  return sums
}

// 监听工具栏事件
const handleToolbarPost = async (event: CustomEvent) => {
  if (selectedDocuments.value.length === 0) {
    ElMessage.warning('请先选择要过账的单据')
    return
  }

  // 批量过账前校验
  const invalidDocuments: string[] = []
  for (const doc of selectedDocuments.value) {
    const validationError = validateBeforePost(doc)
    if (validationError) {
      invalidDocuments.push(`${doc.documentNo}: ${validationError}`)
    }
  }

  if (invalidDocuments.length > 0) {
    ElMessage.warning({
      message: `以下单据无法过账：\n${invalidDocuments.join('\n')}`,
      duration: 6000
    })
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要过账选中的 ${selectedDocuments.value.length} 张单据吗？过账后将生成财务凭证，单据将被锁定无法修改。`,
      '确认批量过账',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    let successCount = 0
    let failCount = 0
    const failMessages: string[] = []

    // 批量过账
    for (const document of selectedDocuments.value) {
      if (document.documentId && !document.posted && document.status === 'VALIDATED') {
        try {
          if (document.documentType === 'INVOICE') {
            await documentApi.postInvoice(document.documentId)
          } else {
            await documentApi.postBill(document.documentId)
          }
          successCount++
        } catch (error: any) {
          failCount++
          const errorMessage = error?.response?.data?.msg || error?.message || '过账失败'
          failMessages.push(`${document.documentNo}: ${errorMessage}`)
          console.error(`过账单据 ${document.documentNo} 失败:`, error)
        }
      }
    }

    // 刷新列表
    await loadDocumentList()
    selectedDocuments.value = []

    // 显示结果
    if (failCount === 0) {
      ElMessage.success(`批量过账完成！成功过账 ${successCount} 张单据，凭证已生成`)
    } else {
      ElMessage.warning({
        message: `批量过账完成：成功 ${successCount} 张，失败 ${failCount} 张\n失败详情：\n${failMessages.join('\n')}`,
        duration: 8000
      })
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.message || '批量过账失败')
    }
  }
}

const handleToolbarPrint = () => {
  if (selectedDocuments.value.length === 0) {
    ElMessage.warning('请先选择要打印的单据')
    return
  }

  // 打印选中的单据
  const documentIds = selectedDocuments.value.map(d => d.documentId).filter(Boolean)
  ElMessage.info(`准备打印 ${selectedDocuments.value.length} 张单据`)
  // TODO: 实现打印功能
  console.log('打印单据ID:', documentIds)
}

onMounted(() => {
  loadDocumentList()
  
  // 监听工具栏事件
  window.addEventListener('toolbar-post', handleToolbarPost as EventListener)
  window.addEventListener('toolbar-print', handleToolbarPrint)
})

onUnmounted(() => {
  // 清理事件监听
  window.removeEventListener('toolbar-post', handleToolbarPost as EventListener)
  window.removeEventListener('toolbar-print', handleToolbarPrint)
})
</script>

<style scoped lang="scss">
.business-document-manager {
  padding: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .amount-text {
    font-weight: bold;
    color: #409eff;
  }

  .paid-amount {
    color: #67c23a;
    font-weight: 500;
  }

  .balance-paid {
    color: #67c23a;
    font-weight: 500;
  }

  .balance-unpaid {
    color: #f56c6c;
    font-weight: 500;
  }

  .header-actions {
    display: flex;
    gap: 10px;
  }

  .pagination-container {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }

  // 状态标签样式
  :deep(.el-tag) {
    font-weight: 500;
  }

  .voucher-detail {
    .splits-section {
      margin-top: 20px;

      h4 {
        color: #303133;
        font-size: 16px;
        font-weight: 600;
      }
    }

    .debit-amount {
      color: #409eff;
      font-weight: 500;
    }

    .credit-amount {
      color: #67c23a;
      font-weight: 500;
    }

    .balance-check {
      margin-top: 15px;
    }
  }
}
</style>
