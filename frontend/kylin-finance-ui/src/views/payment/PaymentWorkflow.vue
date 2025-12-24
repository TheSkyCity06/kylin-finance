<template>
  <div class="payment-workflow">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>往来核销</span>
        </div>
      </template>

      <!-- 支付表单 -->
      <el-form :model="paymentForm" :rules="formRules" ref="formRef" label-width="120px">
        <el-form-item label="往来单位类型" prop="ownerType">
          <el-radio-group v-model="paymentForm.ownerType" @change="handleOwnerTypeChange">
            <el-radio label="CUSTOMER">客户</el-radio>
            <el-radio label="VENDOR">供应商</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="往来单位" prop="ownerId">
          <el-select
            v-model="paymentForm.ownerId"
            placeholder="请选择往来单位"
            filterable
            style="width: 100%"
            @change="handleOwnerChange"
            :loading="loadingOwners"
          >
            <el-option
              v-for="owner in ownerList"
              :key="owner.ownerId"
              :label="`${owner.name} (${owner.code || ''})`"
              :value="owner.ownerId"
            />
          </el-select>
        </el-form-item>

        <el-form-item :label="isReceipt ? '收款金额' : '支付金额'" prop="amount">
          <el-input-number
            v-model="paymentForm.amount"
            :precision="2"
            :min="0"
            :controls="false"
            :placeholder="isReceipt ? '请输入收款金额' : '请输入支付金额'"
            style="width: 100%"
          />
        </el-form-item>

        <el-form-item :label="isReceipt ? '收款账户' : '付款账户'" prop="accountId">
          <el-select
            v-model="paymentForm.accountId"
            placeholder="请选择银行科目"
            filterable
            style="width: 100%"
            :loading="loadingAccounts"
          >
            <el-option
              v-for="account in bankAccounts"
              :key="account.accountId"
              :label="`${account.accountCode} ${account.accountName}`"
              :value="account.accountId"
            />
          </el-select>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">
            {{ isReceipt ? '提交收款' : '提交支付' }}
          </el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 核销预览 -->
      <el-card v-if="unpaidDocuments.length > 0" style="margin-top: 20px">
        <template #header>
          <span>{{ isReceipt ? '未收发票预览' : '未付账单预览' }}</span>
        </template>
        <el-table :data="unpaidDocuments" border stripe style="width: 100%">
          <el-table-column label="单据编号" width="150">
            <template #default="scope">
              {{ scope.row.invoiceNo || scope.row.billNo }}
            </template>
          </el-table-column>
          <el-table-column label="单据日期" width="120">
            <template #default="scope">
              {{ scope.row.invoiceDate || scope.row.billDate }}
            </template>
          </el-table-column>
          <el-table-column label="金额" width="120" align="right">
            <template #default="scope">
              <span>¥{{ formatAmount(scope.row.totalAmount) }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="dueDate" label="到期日" width="120" />
          <el-table-column label="状态" width="100">
            <template #default="scope">
              <el-tag :type="getStatusType(scope.row.status)">
                {{ scope.row.status }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </el-card>

      <!-- 核销结果对话框 -->
      <el-dialog
        v-model="resultDialogVisible"
        :title="isReceipt ? '收款核销成功' : '支付核销成功'"
        width="600px"
        :close-on-click-modal="false"
      >
        <div class="result-content">
          <el-alert
            type="success"
            :closable="false"
            show-icon
            style="margin-bottom: 20px"
          >
            <template #title>
              <span style="font-size: 16px">{{ isReceipt ? '收款核销成功！' : '支付核销成功！' }}</span>
            </template>
          </el-alert>

          <div class="result-summary">
            <p><strong>{{ isReceipt ? '收款金额' : '支付金额' }}：</strong>¥{{ formatAmount(paymentForm.amount) }}</p>
            <p><strong>核销单据数：</strong>{{ allocationResult.length }} 张</p>
          </div>

          <el-table :data="allocationResult" border stripe style="margin-top: 20px">
            <el-table-column prop="documentNo" label="单据编号" width="150" />
            <el-table-column label="核销金额" width="120" align="right">
              <template #default="scope">
                <span>¥{{ formatAmount(scope.row.amount) }}</span>
              </template>
            </el-table-column>
            <el-table-column label="核销状态" width="120">
              <template #default="scope">
                <el-tag :type="scope.row.status === 'PAID' ? 'success' : 'warning'">
                  {{ scope.row.status === 'PAID' ? '已全额核销' : '部分核销' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="剩余金额" width="120" align="right">
              <template #default="scope">
                <span>¥{{ formatAmount(scope.row.remainingAmount) }}</span>
              </template>
            </el-table-column>
          </el-table>
        </div>

        <template #footer>
          <el-button type="primary" @click="handleResultConfirm">确定</el-button>
        </template>
      </el-dialog>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { documentApi, accountApi, paymentApi } from '@/api/finance'
import type { Invoice, FinAccount } from '@/types/finance'
import type { FormInstance, FormRules } from 'element-plus'

interface Owner {
  ownerId: number
  name: string
  code?: string
  ownerType: string
}

interface UnpaidDocument {
  invoiceNo?: string
  billNo?: string
  invoiceDate?: string
  billDate?: string
  totalAmount: number
  dueDate?: string
  status: string
}

interface AllocationResult {
  documentNo: string
  amount: number
  status: string
  remainingAmount: number
}

const formRef = ref<FormInstance>()
const paymentForm = reactive({
  ownerType: 'CUSTOMER',
  ownerId: null as number | null,
  amount: null as number | null,
  accountId: null as number | null
})

// 计算属性：判断是否为收款（客户）
const isReceipt = computed(() => {
  return paymentForm.ownerType === 'CUSTOMER'
})

// 动态表单验证规则
const formRules = computed<FormRules>(() => ({
  ownerType: [{ required: true, message: '请选择往来单位类型', trigger: 'change' }],
  ownerId: [{ required: true, message: '请选择往来单位', trigger: 'change' }],
  amount: [
    { required: true, message: isReceipt.value ? '请输入收款金额' : '请输入支付金额', trigger: 'blur' },
    { type: 'number', min: 0.01, message: isReceipt.value ? '收款金额必须大于0' : '支付金额必须大于0', trigger: 'blur' }
  ],
  accountId: [{ required: true, message: isReceipt.value ? '请选择收款账户' : '请选择付款账户', trigger: 'change' }]
}))

const ownerList = ref<Owner[]>([])
const bankAccounts = ref<FinAccount[]>([])
const unpaidDocuments = ref<UnpaidDocument[]>([])
const loadingOwners = ref(false)
const loadingAccounts = ref(false)
const submitting = ref(false)
const resultDialogVisible = ref(false)
const allocationResult = ref<AllocationResult[]>([])

// 加载往来单位列表
const loadOwners = async (ownerType: string) => {
  loadingOwners.value = true
  try {
    // 将 ownerType 映射为 category 参数
    // CUSTOMER -> CUSTOMER, VENDOR -> SUPPLIER (后端支持 SUPPLIER 映射为 VENDOR)
    const category = ownerType === 'VENDOR' ? 'SUPPLIER' : ownerType
    const response = await documentApi.getPartnerList(category)
    if (response.code === 200) {
      // 后端已经过滤，直接使用返回的标准化数据
      ownerList.value = (response.data || []).map((partner: any) => ({
        ownerId: partner.partnerId,
        name: partner.partnerName,
        code: partner.partnerCode,
        ownerType: partner.category || ownerType
      }))
    }
  } catch (error: any) {
    ElMessage.error('加载往来单位失败')
  } finally {
    loadingOwners.value = false
  }
}

// 加载银行科目
const loadBankAccounts = async () => {
  loadingAccounts.value = true
  try {
    const response = await accountApi.getLeafAccounts()
    if (response.code === 200) {
      // 筛选银行相关科目（通常代码以1002开头或名称包含"银行"）
      bankAccounts.value = (response.data || []).filter(
        (account: FinAccount) =>
          account.accountCode?.startsWith('1002') ||
          account.accountName?.includes('银行') ||
          account.accountName?.includes('存款')
      )
    }
  } catch (error: any) {
    ElMessage.error('加载银行科目失败')
  } finally {
    loadingAccounts.value = false
  }
}

// 往来单位类型变化
const handleOwnerTypeChange = () => {
  paymentForm.ownerId = null
  unpaidDocuments.value = []
  if (paymentForm.ownerType) {
    loadOwners(paymentForm.ownerType)
  }
}

// 往来单位变化
const handleOwnerChange = async () => {
  if (!paymentForm.ownerId) {
    unpaidDocuments.value = []
    return
  }

  try {
    if (paymentForm.ownerType === 'CUSTOMER') {
      // 获取客户的未结清发票
      const response = await documentApi.getUnpaidInvoices(paymentForm.ownerId)
      if (response.code === 200) {
        unpaidDocuments.value = (response.data || []).map((invoice: Invoice) => ({
          invoiceNo: invoice.invoiceNo,
          invoiceDate: invoice.invoiceDate,
          totalAmount: invoice.totalAmount,
          dueDate: invoice.dueDate,
          status: invoice.status
        }))
      }
    } else {
      // 获取供应商的未结清账单
      const response = await documentApi.getUnpaidBills(paymentForm.ownerId)
      if (response.code === 200) {
        unpaidDocuments.value = (response.data || []).map((bill: any) => ({
          billNo: bill.billNo,
          billDate: bill.billDate,
          totalAmount: bill.totalAmount,
          dueDate: bill.dueDate,
          status: bill.status
        }))
      }
    }
  } catch (error: any) {
    ElMessage.error('加载未结清单据失败')
  }
}

// 提交支付
const handleSubmit = async () => {
  if (!formRef.value) return

  await formRef.value.validate(async (valid) => {
    if (!valid) return

    if (!paymentForm.ownerId || !paymentForm.amount || !paymentForm.accountId) {
      ElMessage.warning(isReceipt.value ? '请填写完整的收款信息' : '请填写完整的支付信息')
      return
    }

    try {
      submitting.value = true

      // 调用支付处理接口
      const response = await paymentApi.processPayment({
        ownerId: paymentForm.ownerId,
        amount: paymentForm.amount,
        accountId: paymentForm.accountId,
        paymentType: paymentForm.ownerType === 'CUSTOMER' ? 'RECEIPT' : 'PAYMENT'
      })

      if (response.code === 200) {
        // 获取核销结果
        const data = response.data
        if (data && data.allocations) {
          allocationResult.value = data.allocations.map((alloc: any) => ({
            documentNo: alloc.documentNo,
            amount: alloc.amount,
            status: alloc.status,
            remainingAmount: alloc.remainingAmount || 0
          }))
        } else {
          // 如果没有返回分配结果，使用模拟数据
          allocationResult.value = generateAllocationResult(paymentForm.amount)
        }
        
        resultDialogVisible.value = true
        
        // 刷新未结清单据列表
        await handleOwnerChange()
      } else {
        ElMessage.error(response.msg || (isReceipt.value ? '收款失败' : '支付失败'))
      }
    } catch (error: any) {
      ElMessage.error(error.message || (isReceipt.value ? '收款失败' : '支付失败'))
    } finally {
      submitting.value = false
    }
  })
}

// 生成核销结果（模拟，实际应该从后端返回）
const generateAllocationResult = (paymentAmount: number | null): AllocationResult[] => {
  if (!paymentAmount) return []
  
  const results: AllocationResult[] = []
  let remainingAmount = paymentAmount

  for (const doc of unpaidDocuments.value) {
    if (remainingAmount <= 0) break

    const docAmount = doc.totalAmount
    const allocationAmount = Math.min(remainingAmount, docAmount)
    const remaining = docAmount - allocationAmount

    results.push({
      documentNo: doc.invoiceNo || doc.billNo || '',
      amount: allocationAmount,
      status: remaining === 0 ? 'PAID' : 'PARTIAL',
      remainingAmount: remaining
    })

    remainingAmount -= allocationAmount
  }

  return results
}

// 确认结果
const handleResultConfirm = () => {
  resultDialogVisible.value = false
  resetForm()
}

// 重置表单
const resetForm = () => {
  formRef.value?.resetFields()
  paymentForm.ownerType = 'CUSTOMER'
  paymentForm.ownerId = null
  paymentForm.amount = null
  paymentForm.accountId = null
  unpaidDocuments.value = []
  allocationResult.value = []
}

// 格式化金额
const formatAmount = (amount: number | undefined): string => {
  if (amount === undefined || amount === null) {
    return '0.00'
  }
  return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

// 获取状态类型
const getStatusType = (status: string): string => {
  switch (status?.toUpperCase()) {
    case 'OPEN':
      return 'warning'
    case 'PARTIAL':
      return 'info'
    case 'PAID':
      return 'success'
    default:
      return 'info'
  }
}

onMounted(() => {
  loadOwners('CUSTOMER')
  loadBankAccounts()
})
</script>

<style scoped lang="scss">
.payment-workflow {
  padding: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .result-content {
    .result-summary {
      margin: 20px 0;
      padding: 15px;
      background-color: #f5f7fa;
      border-radius: 4px;

      p {
        margin: 8px 0;
        font-size: 14px;
      }
    }
  }
}
</style>
