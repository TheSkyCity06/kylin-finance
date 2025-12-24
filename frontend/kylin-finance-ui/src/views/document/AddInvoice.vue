<template>
  <div class="add-invoice">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>新增销售发票</span>
          <div>
            <el-button @click="handleCancel">取消</el-button>
            <el-button type="primary" @click="handleSave" :loading="saving" :disabled="!canSave">
              保存草稿
            </el-button>
          </div>
        </div>
      </template>

      <el-form :model="form" label-width="120px" ref="formRef">
        <!-- 基本信息 -->
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="发票编号" required>
              <el-input
                v-model="form.invoiceNo"
                placeholder="自动生成或手动输入"
                :disabled="isReadonly"
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
                :disabled="isReadonly"
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
                :disabled="isReadonly"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="客户" required>
              <el-select
                v-model="form.customerId"
                placeholder="请选择客户"
                filterable
                style="width: 100%"
                :disabled="isReadonly"
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
          <el-col :span="8">
            <el-form-item label="状态">
              <el-tag :type="getStatusType(form.status)">{{ getStatusText(form.status) }}</el-tag>
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 明细行 -->
        <el-form-item label="发票明细" required>
          <div class="items-section">
            <el-table :data="form.items" border style="width: 100%" :class="{ 'readonly-table': isReadonly }">
              <el-table-column label="序号" type="index" width="60" align="center" />
              <el-table-column label="项目描述" min-width="200">
                <template #default="scope">
                  <el-input
                    v-model="scope.row.description"
                    placeholder="请输入项目描述"
                    :disabled="isReadonly"
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
                    :disabled="isReadonly"
                  >
                    <el-option
                      v-for="account in incomeAccounts"
                      :key="account.accountId"
                      :label="`${account.accountCode} ${account.accountName}`"
                      :value="account.accountId"
                    />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column label="数量" width="120">
                <template #default="scope">
                  <el-input-number
                    v-model="scope.row.quantity"
                    :precision="2"
                    :min="0"
                    :controls="false"
                    :disabled="isReadonly"
                    style="width: 100%"
                    @change="calculateItemAmount(scope.$index)"
                    @input="calculateItemAmount(scope.$index)"
                  />
                </template>
              </el-table-column>
              <el-table-column label="单价" width="120">
                <template #default="scope">
                  <el-input-number
                    v-model="scope.row.unitPrice"
                    :precision="2"
                    :min="0"
                    :controls="false"
                    :disabled="isReadonly"
                    style="width: 100%"
                    @change="calculateItemAmount(scope.$index)"
                    @input="calculateItemAmount(scope.$index)"
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
                    :controls="false"
                    :disabled="isReadonly"
                    style="width: 100%"
                    @change="calculateItemAmount(scope.$index)"
                    @input="calculateItemAmount(scope.$index)"
                  />
                </template>
              </el-table-column>
              <el-table-column label="税额" width="120" align="right">
                <template #default="scope">
                  <span>{{ formatAmount(scope.row.taxAmount || 0) }}</span>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="80" align="center" v-if="!isReadonly">
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
            <div v-if="!isReadonly" style="margin-top: 10px">
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
            <el-form-item label="含税总金额" required>
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
            :disabled="isReadonly"
          />
        </el-form-item>
      </el-form>

      <!-- 操作按钮 -->
      <div class="action-buttons" v-if="!isReadonly && form.invoiceId">
        <el-button type="success" @click="handleValidate" :loading="validating">
          审核
        </el-button>
        <el-button type="warning" @click="handleCancel" :loading="cancelling">
          作废
        </el-button>
      </div>
      <div class="action-buttons" v-if="form.status === 'VALIDATED'">
        <el-button type="primary" @click="handlePost" :loading="posting">
          审核过账
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete } from '@element-plus/icons-vue'
import { documentApi, accountApi } from '@/api/finance'
import type { Invoice, FinAccount, AccountDTO } from '@/types/finance'

const route = useRoute()
const router = useRouter()

const formRef = ref()
const saving = ref(false)
const validating = ref(false)
const posting = ref(false)
const cancelling = ref(false)

// 初始化表单数据（默认科目将在 loadIncomeAccounts 中设置）
const form = ref<Invoice & { items: any[] }>({
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
      incomeAccountId: undefined, // 将在 loadIncomeAccounts 后设置为 6001
      quantity: 1,
      unitPrice: 0,
      amount: 0,
      taxRate: 0,
      taxAmount: 0
    }
  ]
})

const customerList = ref<any[]>([])
const incomeAccounts = ref<FinAccount[]>([])

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

const isReadonly = computed(() => {
  return form.value.status === 'VALIDATED' || form.value.status === 'POSTED' || form.value.status === 'CANCELLED'
})

const canSave = computed(() => {
  return form.value.invoiceNo && form.value.invoiceDate && form.value.customerId && 
         form.value.items.length > 0 && form.value.items.every(item => 
           item.description && item.incomeAccountId && item.amount > 0
         )
})

// 格式化金额
const formatAmount = (amount: number) => {
  return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

// 计算单行金额
const calculateItemAmount = (index: number) => {
  const item = form.value.items[index]
  
  // 确保数值有效
  const quantity = Number(item.quantity) || 0
  const unitPrice = Number(item.unitPrice) || 0
  const taxRate = Number(item.taxRate) || 0
  
  // 计算金额 = 数量 * 单价
  item.amount = Number((quantity * unitPrice).toFixed(2))
  
  // 计算税额 = 金额 * 税率%
  if (item.amount > 0 && taxRate > 0) {
    item.taxAmount = Number((item.amount * taxRate / 100).toFixed(2))
  } else {
    item.taxAmount = 0
  }
  
  // 更新总金额（通过计算属性自动更新）
  form.value.netAmount = calculatedNetAmount.value
  form.value.taxAmount = calculatedTaxAmount.value
  form.value.totalAmount = calculatedTotalAmount.value
}

// 添加明细行
const addItem = () => {
  // 查找默认科目 6001 (主营业务收入)
  const defaultAccount = incomeAccounts.value.find(acc => acc.accountCode === '6001')
  
  form.value.items.push({
    description: '',
    incomeAccountId: defaultAccount?.accountId || undefined,
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

// 获取状态类型
const getStatusType = (status: string) => {
  const map: Record<string, string> = {
    DRAFT: 'info',
    VALIDATED: 'warning',
    POSTED: 'success',
    CANCELLED: 'danger'
  }
  return map[status] || 'info'
}

// 获取状态文本
const getStatusText = (status: string) => {
  const map: Record<string, string> = {
    DRAFT: '草稿',
    VALIDATED: '已审核',
    POSTED: '已过账',
    CANCELLED: '已作废'
  }
  return map[status] || status
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

// 查找科目代码为 6001 的主营业务收入科目
const findMainIncomeAccount = (accounts: AccountDTO[]): FinAccount | null => {
  for (const account of accounts) {
    if (account.accountCode === '6001' && account.accountType === 'INCOME') {
      return {
        accountId: account.accountId,
        accountCode: account.accountCode,
        accountName: account.accountName,
        accountType: account.accountType
      }
    }
    if (account.children) {
      const found = findMainIncomeAccount(account.children)
      if (found) return found
    }
  }
  return null
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
            result.push({
              accountId: account.accountId,
              accountCode: account.accountCode,
              accountName: account.accountName,
              accountType: account.accountType
            })
          }
          if (account.children) {
            result.push(...filterIncomeAccounts(account.children))
          }
        }
        return result
      }
      incomeAccounts.value = filterIncomeAccounts(accounts)
      
      // 查找并设置默认科目 6001 (主营业务收入)
      const mainIncomeAccount = findMainIncomeAccount(accounts)
      if (mainIncomeAccount && mainIncomeAccount.accountId) {
        // 为所有明细行设置默认科目
        form.value.items.forEach(item => {
          if (!item.incomeAccountId) {
            item.incomeAccountId = mainIncomeAccount.accountId
          }
        })
      }
    }
  } catch (error) {
    ElMessage.error('加载收入科目失败')
  }
}

// 保存
const handleSave = async () => {
  if (!canSave.value) {
    ElMessage.warning('请填写完整信息')
    return
  }

  saving.value = true
  try {
    // 更新总金额
    form.value.netAmount = calculatedNetAmount.value
    form.value.taxAmount = calculatedTaxAmount.value
    form.value.totalAmount = calculatedTotalAmount.value

    let response
    if (form.value.invoiceId) {
      response = await documentApi.updateInvoice(form.value)
    } else {
      response = await documentApi.createInvoice(form.value)
    }

    if (response.code === 200) {
      ElMessage.success('保存成功')
      router.push('/document/invoice-list')
    } else {
      ElMessage.error(response.msg || '保存失败')
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.msg || error.message || '保存失败')
  } finally {
    saving.value = false
  }
}

// 审核
const handleValidate = async () => {
  if (!form.value.invoiceId) {
    ElMessage.warning('请先保存发票')
    return
  }

  try {
    await ElMessageBox.confirm('确定要审核此发票吗？审核后将无法修改。', '确认审核', {
      type: 'warning'
    })

    validating.value = true
    const response = await documentApi.validateInvoice(form.value.invoiceId!)
    if (response.code === 200) {
      ElMessage.success('审核成功')
      form.value.status = 'VALIDATED'
    } else {
      ElMessage.error(response.msg || '审核失败')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.msg || error.message || '审核失败')
    }
  } finally {
    validating.value = false
  }
}

// 过账前校验
const validateBeforePost = (): string | null => {
  // 1. 检查单据是否已保存
  if (!form.value.invoiceId) {
    return '请先保存发票'
  }

  // 2. 检查单据状态是否为 VALIDATED（已审核）
  if (form.value.status !== 'VALIDATED') {
    return `当前状态为 ${form.value.status}，只有已审核状态的发票才能过账。请先审核发票。`
  }

  // 3. 检查金额是否不为0
  if (!form.value.totalAmount || form.value.totalAmount <= 0) {
    return '发票金额不能为0，请检查明细行金额'
  }

  // 4. 检查科目是否选择完整
  if (!form.value.items || form.value.items.length === 0) {
    return '发票没有明细行，无法过账'
  }

  const missingAccountItems = form.value.items.filter(
    (item, index) => !item.incomeAccountId
  )
  if (missingAccountItems.length > 0) {
    return `第 ${missingAccountItems.map((_, i) => form.value.items.indexOf(missingAccountItems[i]) + 1).join('、')} 行未选择收入科目，请完善后再过账`
  }

  // 5. 检查客户是否已关联应收账款科目（后端会校验，这里做前端提示）
  if (!form.value.customerId) {
    return '请选择客户'
  }

  return null
}

// 过账
const handlePost = async () => {
  // 过账前校验
  const validationError = validateBeforePost()
  if (validationError) {
    ElMessage.warning(validationError)
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要过账发票 "${form.value.invoiceNo}" 吗？过账后将生成会计分录，单据将被锁定无法修改。`,
      '确认过账',
      {
        type: 'warning'
      }
    )

    posting.value = true
    const response = await documentApi.postInvoice(form.value.invoiceId!)
    if (response.code === 200) {
      // 过账成功后重新加载发票数据以获取凭证ID
      try {
        const invoiceResponse = await documentApi.getInvoiceById(form.value.invoiceId!)
        if (invoiceResponse.code === 200 && invoiceResponse.data) {
          form.value.status = invoiceResponse.data.status
          form.value.posted = invoiceResponse.data.posted
          form.value.transId = invoiceResponse.data.transId
          
          // 显示凭证已生成的消息
          if (invoiceResponse.data.transId) {
            ElMessage.success({
              message: `过账成功！凭证已生成，凭证ID：${invoiceResponse.data.transId}`,
              duration: 5000
            })
          } else {
            ElMessage.success('过账成功！凭证已生成')
          }
        } else {
          ElMessage.success('过账成功')
        }
      } catch (loadError) {
        console.error('重新加载发票数据失败:', loadError)
        ElMessage.success('过账成功')
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
    posting.value = false
  }
}

// 作废
const handleCancel = async () => {
  if (!form.value.invoiceId) {
    router.back()
    return
  }

  try {
    await ElMessageBox.confirm(
      form.value.status === 'POSTED' 
        ? '此发票已过账，作废将生成红冲凭证。确定要作废吗？'
        : '确定要作废此发票吗？',
      '确认作废',
      {
        type: 'warning'
      }
    )

    cancelling.value = true
    const response = await documentApi.cancelInvoice(form.value.invoiceId!)
    if (response.code === 200) {
      ElMessage.success('作废成功')
      form.value.status = 'CANCELLED'
    } else {
      ElMessage.error(response.msg || '作废失败')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.msg || error.message || '作废失败')
    }
  } finally {
    cancelling.value = false
  }
}

// 加载发票详情
const loadInvoice = async (invoiceId: number) => {
  try {
    const response = await documentApi.getInvoiceById(invoiceId)
    if (response.code === 200) {
      Object.assign(form.value, response.data)
      if (!form.value.items || form.value.items.length === 0) {
        // 查找默认科目 6001 (主营业务收入)
        const defaultAccount = incomeAccounts.value.find(acc => acc.accountCode === '6001')
        form.value.items = [{
          description: '',
          incomeAccountId: defaultAccount?.accountId || undefined,
          quantity: 1,
          unitPrice: 0,
          amount: 0,
          taxRate: 0,
          taxAmount: 0
        }]
      } else {
        // 为没有科目的明细行设置默认科目
        const defaultAccount = incomeAccounts.value.find(acc => acc.accountCode === '6001')
        form.value.items.forEach(item => {
          if (!item.incomeAccountId && defaultAccount) {
            item.incomeAccountId = defaultAccount.accountId
          }
        })
      }
    }
  } catch (error) {
    ElMessage.error('加载发票详情失败')
  }
}

onMounted(async () => {
  await loadCustomers()
  await loadIncomeAccounts()
  
  const invoiceId = route.params.id as string
  if (invoiceId && invoiceId !== 'new') {
    await loadInvoice(Number(invoiceId))
  }
})
</script>

<style scoped lang="scss">
.add-invoice {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .items-section {
    .readonly-table {
      :deep(.el-input),
      :deep(.el-input-number),
      :deep(.el-select) {
        pointer-events: none;
      }
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

  .action-buttons {
    margin-top: 20px;
    text-align: right;

    .el-button {
      margin-left: 10px;
    }
  }
}
</style>

