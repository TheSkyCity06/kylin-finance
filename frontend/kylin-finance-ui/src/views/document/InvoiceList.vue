<template>
  <div class="invoice-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>销售发票</span>
          <div class="header-actions">
            <el-button type="primary" :icon="Plus" @click="showCreateDialog">新增单据</el-button>
            <el-button type="info" :icon="Refresh" @click="loadInvoiceList">刷新</el-button>
          </div>
        </div>
      </template>

      <el-table :data="invoiceList" border stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="invoiceNo" label="发票编号" width="150" />
        <el-table-column prop="invoiceDate" label="发票日期" width="120" />
        <el-table-column prop="customerName" label="客户名称" width="200" />
        <el-table-column label="金额" width="120" align="right">
          <template #default="scope">
            ¥{{ formatAmount(scope.row.totalAmount) }}
          </template>
        </el-table-column>
        <el-table-column prop="dueDate" label="到期日" width="120" />
        <el-table-column label="状态" width="100">
          <template #default="scope">
            <el-tag :type="getStatusType(scope.row.status)">{{ getStatusText(scope.row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="300" fixed="right">
          <template #default="scope">
            <el-button 
              v-if="scope.row.status === 'DRAFT'" 
              type="success" 
              size="small" 
              @click="handleValidate(scope.row)"
            >
              审核
            </el-button>
            <el-button 
              v-if="scope.row.status === 'VALIDATED'" 
              type="primary" 
              size="small" 
              @click="handlePost(scope.row)"
            >
              过账
            </el-button>
            <el-button 
              v-if="scope.row.status !== 'CANCELLED' && scope.row.status !== 'POSTED'" 
              type="warning" 
              size="small" 
              @click="handleCancel(scope.row)"
            >
              作废
            </el-button>
            <el-button type="info" size="small" @click="handleView(scope.row)">
              {{ scope.row.status === 'DRAFT' ? '编辑' : '查看' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="pageNum"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="loadInvoiceList"
        @current-change="loadInvoiceList"
        style="margin-top: 16px"
      />
    </el-card>

    <!-- 创建发票弹窗 -->
    <el-dialog
      v-model="createDialogVisible"
      title="新建销售发票"
      width="1200px"
      :close-on-click-modal="false"
      @close="resetForm"
    >
      <el-form :model="form" label-width="120px" ref="formRef">
        <!-- 基础信息 -->
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="发票编号">
              <el-input
                v-model="form.invoiceNo"
                placeholder="自动生成"
                readonly
              />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="发票日期" required>
              <el-date-picker
                v-model="form.invoiceDate"
                type="date"
                placeholder="选择日期"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="到期日期">
              <el-date-picker
                v-model="form.dueDate"
                type="date"
                placeholder="选择日期"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="客户" required>
              <el-select
                v-model="form.customerId"
                placeholder="请选择客户"
                filterable
                style="width: 100%"
              >
                <el-option
                  v-for="customer in customerList"
                  :key="customer.ownerId"
                  :label="customer.name"
                  :value="customer.ownerId"
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 明细表格 -->
        <el-form-item label="发票明细" required>
          <div class="items-table">
            <el-table :data="form.items" border style="width: 100%" max-height="400">
              <el-table-column label="序号" type="index" width="60" align="center" />
              <el-table-column label="项目描述" min-width="200">
                <template #default="scope">
                  <el-input
                    v-model="scope.row.description"
                    placeholder="请输入项目描述"
                  />
                </template>
              </el-table-column>
              <el-table-column label="收入科目" min-width="250">
                <template #default="scope">
                  <el-select
                    v-model="scope.row.incomeAccountId"
                    placeholder="选择收入科目"
                    filterable
                    style="width: 100%"
                  >
                    <el-option-group
                      v-for="group in incomeAccountGroups"
                      :key="group.type"
                      :label="group.label"
                    >
                      <el-option
                        v-for="account in group.accounts"
                        :key="account.accountId"
                        :label="`${account.accountCode} ${account.accountName}`"
                        :value="account.accountId"
                      />
                    </el-option-group>
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="数量" width="120">
                <template #default="scope">
                  <el-input-number
                    v-model="scope.row.quantity"
                    :precision="2"
                    :min="0"
                    style="width: 100%"
                    @change="calculateItemAmount(scope.$index)"
                  />
                </template>
              </el-table-column>
              <el-table-column label="单价" width="120">
                <template #default="scope">
                  <el-input-number
                    v-model="scope.row.unitPrice"
                    :precision="2"
                    :min="0"
                    style="width: 100%"
                    @change="calculateItemAmount(scope.$index)"
                  />
                </template>
              </el-table-column>
              <el-table-column label="金额" width="120" align="right">
                <template #default="scope">
                  <span>{{ formatAmount(scope.row.amount || 0) }}</span>
                </template>
              </el-table-column>
              <el-table-column label="税率(%)" width="120">
                <template #default="scope">
                  <el-input-number
                    v-model="scope.row.taxRate"
                    :precision="2"
                    :min="0"
                    :max="100"
                    style="width: 100%"
                    @change="calculateItemAmount(scope.$index)"
                  />
                </template>
              </el-table-column>
              <el-table-column label="税额" width="120" align="right">
                <template #default="scope">
                  <span>{{ formatAmount(scope.row.taxAmount || 0) }}</span>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="80" align="center">
                <template #default="scope">
                  <el-button
                    type="danger"
                    size="small"
                    @click="removeItem(scope.$index)"
                    :disabled="form.items.length <= 1"
                  >
                    <el-icon><Delete /></el-icon>
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
            <div style="margin-top: 10px">
              <el-button type="primary" @click="addItem">
                <el-icon><Plus /></el-icon>
                添加明细行
              </el-button>
            </div>
          </div>
        </el-form-item>

        <!-- 金额汇总 -->
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="不含税金额">
              <span class="amount-display">¥{{ formatAmount(calculatedNetAmount) }}</span>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="税额">
              <span class="amount-display">¥{{ formatAmount(calculatedTaxAmount) }}</span>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="含税总金额">
              <span class="amount-display total-amount">¥{{ formatAmount(calculatedTotalAmount) }}</span>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="备注">
          <el-input
            v-model="form.notes"
            type="textarea"
            :rows="3"
            placeholder="请输入备注信息"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="createDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleCreate" :loading="creating">
            保存草稿
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Refresh } from '@element-plus/icons-vue'
import { documentApi, accountApi } from '@/api/finance'
import type { Invoice, InvoiceItem, FinAccount, AccountDTO } from '@/types/finance'

const router = useRouter()

const loading = ref(false)
const invoiceList = ref<Invoice[]>([])
const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)

// 创建弹窗相关
const createDialogVisible = ref(false)
const creating = ref(false)
const formRef = ref()
const customerList = ref<any[]>([])
const incomeAccounts = ref<FinAccount[]>([])

// 表单数据
const form = ref<Invoice & { items: InvoiceItem[] }>({
  invoiceNo: '',
  invoiceDate: new Date().toISOString().split('T')[0],
  dueDate: '',
  customerId: undefined,
  status: 'DRAFT',
  totalAmount: 0,
  taxAmount: 0,
  netAmount: 0,
  notes: '',
  items: [
    {
      description: '',
      incomeAccountId: undefined,
      quantity: 1,
      unitPrice: 0,
      amount: 0,
      taxRate: 0,
      taxAmount: 0
    }
  ]
})

// 计算属性
const calculatedNetAmount = computed(() => {
  return form.value.items.reduce((sum, item) => {
    return sum + (item.amount || 0)
  }, 0)
})

const calculatedTaxAmount = computed(() => {
  return form.value.items.reduce((sum, item) => {
    return sum + (item.taxAmount || 0)
  }, 0)
})

const calculatedTotalAmount = computed(() => {
  return calculatedNetAmount.value + calculatedTaxAmount.value
})

// 收入科目分组
const incomeAccountGroups = computed(() => {
  const groups: Record<string, { type: string; label: string; accounts: FinAccount[] }> = {}
  
  incomeAccounts.value.forEach(account => {
    const type = account.accountType || 'OTHER'
    if (!groups[type]) {
      const typeLabels: Record<string, string> = {
        INCOME: '收入类',
        ASSET: '资产类',
        EXPENSE: '费用类',
        LIABILITY: '负债类',
        EQUITY: '权益类'
      }
      groups[type] = {
        type,
        label: typeLabels[type] || '其他',
        accounts: []
      }
    }
    groups[type].accounts.push(account)
  })
  
  return Object.values(groups)
})

// 加载发票列表
const loadInvoiceList = async () => {
  loading.value = true
  try {
    const response = await documentApi.getInvoiceList(pageNum.value, pageSize.value)
    if (response.code === 200) {
      invoiceList.value = response.data?.records || []
      total.value = response.data?.total || 0
    }
  } catch (error) {
    ElMessage.error('加载发票列表失败')
  } finally {
    loading.value = false
  }
}

// 格式化金额
const formatAmount = (amount: number) => {
  return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

// 获取状态类型
const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    DRAFT: 'info',
    OPEN: 'warning',
    POSTED: 'success',
    PAID: 'success',
    PARTIAL: 'warning',
    CANCELLED: 'danger'
  }
  return statusMap[status] || 'info'
}

// 获取状态文本
const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    DRAFT: '草稿',
    OPEN: '未结清',
    POSTED: '已过账',
    PAID: '已结清',
    PARTIAL: '部分结清',
    CANCELLED: '已取消'
  }
  return statusMap[status] || status
}

// 显示创建弹窗
const showCreateDialog = async () => {
  await loadCustomers()
  await loadIncomeAccounts()
  resetForm()
  createDialogVisible.value = true
}

// 重置表单
const resetForm = () => {
  form.value = {
    invoiceNo: '',
    invoiceDate: new Date().toISOString().split('T')[0],
    dueDate: '',
    customerId: undefined,
    status: 'DRAFT',
    totalAmount: 0,
    taxAmount: 0,
    netAmount: 0,
    notes: '',
    items: [
      {
        description: '',
        incomeAccountId: undefined,
        quantity: 1,
        unitPrice: 0,
        amount: 0,
        taxRate: 0,
        taxAmount: 0
      }
    ]
  }
}

// 加载客户列表
const loadCustomers = async () => {
  try {
    const response = await documentApi.getOwnerList('CUSTOMER')
    if (response.code === 200) {
      customerList.value = response.data || []
    }
  } catch (error) {
    ElMessage.error('加载客户列表失败')
  }
}

// 加载收入科目
const loadIncomeAccounts = async () => {
  try {
    const response = await accountApi.getAccountTree()
    if (response.code === 200) {
      const accounts = response.data || []
      // 过滤出收入类科目（INCOME）
      const filterIncomeAccounts = (accounts: AccountDTO[]): FinAccount[] => {
        const result: FinAccount[] = []
        for (const account of accounts) {
          if (account.accountType === 'INCOME') {
            result.push(account)
          }
          if (account.children) {
            result.push(...filterIncomeAccounts(account.children))
          }
        }
        return result
      }
      incomeAccounts.value = filterIncomeAccounts(accounts)
    }
  } catch (error) {
    ElMessage.error('加载收入科目失败')
  }
}

// 添加明细行
const addItem = () => {
  form.value.items.push({
    description: '',
    incomeAccountId: undefined,
    quantity: 1,
    unitPrice: 0,
    amount: 0,
    taxRate: 0,
    taxAmount: 0
  })
}

// 删除明细行
const removeItem = (index: number) => {
  if (form.value.items.length > 1) {
    form.value.items.splice(index, 1)
    calculateItemAmount(0) // 重新计算
  }
}

// 计算单行金额
const calculateItemAmount = (index: number) => {
  const item = form.value.items[index]
  if (item.quantity && item.unitPrice) {
    item.amount = Number((item.quantity * item.unitPrice).toFixed(2))
  } else {
    item.amount = 0
  }
  
  if (item.amount && item.taxRate) {
    item.taxAmount = Number((item.amount * item.taxRate / 100).toFixed(2))
  } else {
    item.taxAmount = 0
  }
  
  // 更新总金额
  form.value.netAmount = calculatedNetAmount.value
  form.value.taxAmount = calculatedTaxAmount.value
  form.value.totalAmount = calculatedTotalAmount.value
}

// 创建发票
const handleCreate = async () => {
  // 验证必填项
  if (!form.value.invoiceDate) {
    ElMessage.warning('请选择发票日期')
    return
  }
  if (!form.value.customerId) {
    ElMessage.warning('请选择客户')
    return
  }
  if (form.value.items.length === 0 || form.value.items.some(item => !item.description || !item.incomeAccountId || !item.amount)) {
    ElMessage.warning('请填写完整的明细信息')
    return
  }

  creating.value = true
  try {
    // 更新总金额
    form.value.netAmount = calculatedNetAmount.value
    form.value.taxAmount = calculatedTaxAmount.value
    form.value.totalAmount = calculatedTotalAmount.value

    const response = await documentApi.createInvoice(form.value)
    if (response.code === 200) {
      ElMessage.success('创建成功')
      createDialogVisible.value = false
      loadInvoiceList()
    } else {
      ElMessage.error(response.msg || '创建失败')
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.msg || error.message || '创建失败')
  } finally {
    creating.value = false
  }
}

// 审核
const handleValidate = async (row: Invoice) => {
  try {
    await ElMessageBox.confirm('确定要审核此发票吗？审核后将无法修改。', '确认审核', {
      type: 'warning'
    })
    await documentApi.validateInvoice(row.invoiceId!)
    ElMessage.success('审核成功')
    loadInvoiceList()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.msg || error.message || '审核失败')
    }
  }
}

// 过账前校验
const validateBeforePost = (invoice: Invoice): string | null => {
  // 1. 检查单据是否已保存
  if (!invoice.invoiceId) {
    return '发票ID不存在'
  }

  // 2. 检查单据状态是否为 VALIDATED（已审核）
  if (invoice.status !== 'VALIDATED') {
    return `当前状态为 ${invoice.status}，只有已审核状态的发票才能过账。请先审核发票。`
  }

  // 3. 检查金额是否不为0
  if (!invoice.totalAmount || invoice.totalAmount <= 0) {
    return '发票金额不能为0，无法过账'
  }

  // 4. 检查是否已过账
  if (invoice.posted) {
    return '发票已过账，无法重复过账'
  }

  return null
}

// 过账
const handlePost = async (row: Invoice) => {
  // 过账前校验
  const validationError = validateBeforePost(row)
  if (validationError) {
    ElMessage.warning(validationError)
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要过账发票 "${row.invoiceNo}" 吗？过账后将生成会计分录，单据将被锁定无法修改。`,
      '确认过账',
      {
        type: 'warning'
      }
    )
    
    const response = await documentApi.postInvoice(row.invoiceId!)
    if (response.code === 200) {
      // 过账成功后重新加载发票数据以获取凭证ID
      try {
        const invoiceResponse = await documentApi.getInvoiceById(row.invoiceId!)
        if (invoiceResponse.code === 200 && invoiceResponse.data?.transId) {
          ElMessage.success({
            message: `过账成功！凭证已生成，凭证ID：${invoiceResponse.data.transId}`,
            duration: 5000
          })
        } else {
          ElMessage.success('过账成功！凭证已生成')
        }
      } catch (loadError) {
        console.error('重新加载发票数据失败:', loadError)
        ElMessage.success('过账成功！凭证已生成')
      }
      loadInvoiceList()
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
  }
}

// 作废
const handleCancel = async (row: Invoice) => {
  try {
    const message = row.status === 'POSTED' 
      ? '此发票已过账，作废将生成红冲凭证。确定要作废吗？'
      : '确定要作废此发票吗？'
    await ElMessageBox.confirm(message, '确认作废', {
      type: 'warning'
    })
    await documentApi.cancelInvoice(row.invoiceId!)
    ElMessage.success('作废成功')
    loadInvoiceList()
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.msg || error.message || '作废失败')
    }
  }
}

// 查看/编辑
const handleView = (row: Invoice) => {
  router.push(`/document/invoice/${row.invoiceId}`)
}

onMounted(() => {
  loadInvoiceList()
})
</script>

<style scoped lang="scss">
.invoice-list {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;

    .header-actions {
      display: flex;
      gap: 10px;
    }
  }

  .items-table {
    .el-table {
      margin-top: 10px;
    }
  }

  .amount-display {
    font-size: 16px;
    font-weight: 500;
    color: #303133;

    &.total-amount {
      font-size: 18px;
      font-weight: 600;
      color: #409eff;
    }
  }
}
</style>
