<template>
  <div class="payment-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>收付款单</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增收付款单</el-button>
        </div>
      </template>

      <el-table :data="paymentList" border stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="paymentNo" label="单据编号" width="150" />
        <el-table-column prop="paymentDate" label="日期" width="120" />
        <el-table-column label="类型" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.paymentType === 'RECEIPT' ? 'success' : 'warning'">
              {{ scope.row.paymentType === 'RECEIPT' ? '收款' : '付款' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="ownerName" label="往来单位" width="200" />
        <el-table-column label="金额" width="120" align="right">
          <template #default="scope">
            ¥{{ formatAmount(scope.row.amount) }}
          </template>
        </el-table-column>
        <el-table-column prop="accountName" label="结算账户" width="150" />
        <el-table-column label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 'CLEARED' ? 'success' : 'info'">
              {{ scope.row.status === 'CLEARED' ? '已核销' : '未核销' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="scope">
            <el-button type="info" size="small" @click="handleView(scope.row)">查看</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="pageNum"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="loadPaymentList"
        @current-change="loadPaymentList"
        style="margin-top: 16px"
      />
    </el-card>

    <!-- 新增收付款单对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      :close-on-click-modal="false"
      @close="handleDialogClose"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="formRules"
        label-width="120px"
      >
        <el-form-item label="类型" prop="paymentType">
          <el-radio-group v-model="form.paymentType" :disabled="isView">
            <el-radio label="RECEIPT">收款</el-radio>
            <el-radio label="PAYMENT">付款</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="日期" prop="paymentDate">
          <el-date-picker
            v-model="form.paymentDate"
            type="date"
            placeholder="选择日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            style="width: 100%"
            :disabled="isView"
          />
        </el-form-item>

        <el-form-item label="往来单位" prop="ownerId">
          <el-select
            v-model="form.ownerId"
            :placeholder="form.paymentType === 'RECEIPT' ? '选择客户' : '选择供应商'"
            filterable
            style="width: 100%"
            :disabled="isView"
            @change="handleOwnerChange"
          >
            <el-option
              v-for="partner in ownerList"
              :key="partner.partnerId"
              :label="partner.partnerName"
              :value="partner.partnerId"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="结算账户" prop="accountId">
          <el-select
            v-model="form.accountId"
            placeholder="选择结算账户（如现金、银行存款）"
            filterable
            style="width: 100%"
            :disabled="isView"
          >
            <el-option
              v-for="account in settlementAccounts"
              :key="account.accountId"
              :label="`${account.accountCode} ${account.accountName}`"
              :value="account.accountId"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="金额" prop="amount">
          <el-input-number
            v-model="form.amount"
            :precision="2"
            :min="0"
            controls-position="right"
            style="width: 100%"
            placeholder="请输入金额"
            :disabled="isView"
          />
        </el-form-item>

        <el-form-item label="摘要" prop="remark">
          <el-input
            v-model="form.remark"
            type="textarea"
            :rows="3"
            placeholder="请输入摘要说明"
            :disabled="isView"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="dialogVisible = false">{{ isView ? '关闭' : '取消' }}</el-button>
          <el-button v-if="!isView" type="primary" @click="handleSave" :loading="saving">
            保存
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, watch } from 'vue'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { documentApi, accountApi, receiptPaymentApi } from '@/api/finance'
import type { AccountDTO } from '@/types/finance'

interface Payment {
  paymentId?: number
  paymentNo: string
  paymentDate: string
  paymentType: 'RECEIPT' | 'PAYMENT'
  ownerId: number
  ownerName?: string
  amount: number
  accountId: number
  accountName?: string
  status: string
  remark?: string
}

interface Partner {
  partnerId: number
  partnerName: string
  partnerCode?: string
  category?: string
}

const loading = ref(false)
const saving = ref(false)
const paymentList = ref<Payment[]>([])
const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)

// 对话框相关
const dialogVisible = ref(false)
const dialogTitle = ref('新增收付款单')
const formRef = ref<FormInstance>()
const isView = ref(false)

// 表单数据
const form = reactive<Payment>({
  paymentType: 'RECEIPT',
  paymentDate: new Date().toISOString().split('T')[0],
  ownerId: 0,
  amount: 0,
  accountId: 0,
  remark: ''
})

// 往来单位列表（使用标准化的 PartnerDTO 格式）
const ownerList = ref<Partner[]>([])
// 结算账户列表（资产类科目）
const settlementAccounts = ref<AccountDTO[]>([])

// 表单验证规则
const formRules: FormRules = {
  paymentType: [{ required: true, message: '请选择类型', trigger: 'change' }],
  paymentDate: [{ required: true, message: '请选择日期', trigger: 'change' }],
  ownerId: [{ required: true, message: '请选择往来单位', trigger: 'change' }],
  accountId: [{ required: true, message: '请选择结算账户', trigger: 'change' }],
  amount: [
    { required: true, message: '请输入金额', trigger: 'blur' },
    { type: 'number', min: 0.01, message: '金额必须大于0', trigger: 'blur' }
  ]
}

// 加载收付款单列表
const loadPaymentList = async () => {
  loading.value = true
  try {
    const params = {
      pageNum: pageNum.value,
      pageSize: pageSize.value
    }
    console.log('=== 加载收付款单列表 ===')
    console.log('请求参数:', params)
    const res = await receiptPaymentApi.getReceiptPaymentList(params)
    console.log('响应数据 (res):', res)
    console.log('响应数据结构:', {
      code: res.code,
      msg: res.msg,
      hasData: !!res.data,
      dataType: res.data ? typeof res.data : 'null',
      hasRecords: !!(res.data && res.data.records),
      recordsLength: res.data?.records?.length || 0,
      total: res.data?.total || 0
    })
    
    // 后端返回格式: { code: 200, msg: "操作成功", data: { records: [...], total: 100, ... } }
    // 响应拦截器返回: res = { code, msg, data }
    // 所以 res.data 是 IPage 对象，res.data.records 是数组
    let records: any[] = []
    if (res.data && res.data.records) {
      // MyBatis-Plus IPage 格式
      records = res.data.records || []
      total.value = res.data.total || 0
      console.log('✅ 成功加载收付款单列表 (IPage格式)，记录数:', records.length, '总数:', total.value)
    } else if (res.data && Array.isArray(res.data)) {
      // 兼容：如果直接返回数组（不应该发生，但做兼容处理）
      records = res.data
      total.value = res.data.length
      console.warn('⚠️ 响应数据是数组格式（非标准IPage格式）')
    } else {
      console.warn('⚠️ 响应数据格式异常，使用空数组')
      records = []
      total.value = 0
    }
    
    // 映射后端字段到前端接口
    paymentList.value = records.map((item: any) => ({
      paymentId: item.id,
      paymentNo: item.code || '',
      paymentDate: item.date || '',
      paymentType: item.type || 'RECEIPT',
      ownerId: item.ownerId || 0,
      ownerName: item.partnerName || '',
      amount: item.amount || 0,
      accountId: item.accountId || 0,
      accountName: item.accountName || '', // 如果后端返回了账户名称
      status: item.status === 1 ? 'CLEARED' : 'PENDING', // 0=草稿, 1=已过账
      remark: item.remark || ''
    }))
    
    console.log('✅ 映射后的收付款单列表，记录数:', paymentList.value.length)
  } catch (error: any) {
    // 如果是404或接口不存在，静默处理，不显示错误
    if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
      paymentList.value = []
      total.value = 0
      // 不显示错误消息，因为接口可能还未实现
      return
    }
    // 其他错误才显示消息
    if (error.message && !error.message.includes('404')) {
      ElMessage.error(error.message || '加载收付款单列表失败')
    }
  } finally {
    loading.value = false
  }
}

// 加载往来单位列表（根据类型过滤）
const loadOwnerList = async (category?: string) => {
  try {
    // 使用 FinanceController 的标准化接口，返回 PartnerDTO
    const res = await documentApi.getPartnerList(category)
    if (res.code === 200) {
      ownerList.value = res.data || []
    } else {
      ownerList.value = []
      ElMessage.error(res.msg || '加载往来单位列表失败')
    }
  } catch (error: any) {
    // 如果接口不存在，使用空数组，不显示错误
    if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
      ownerList.value = []
      return
    }
    // 其他错误才显示消息
    if (error.message && !error.message.includes('404')) {
      ElMessage.error('加载往来单位列表失败')
    }
    ownerList.value = []
  }
}

// 加载结算账户（资产类科目）
const loadSettlementAccounts = async () => {
  try {
    const accounts = await accountApi.getAccountTree()
    const accountTree = accounts.data || []
    settlementAccounts.value = extractAccountsByType(accountTree, 'ASSET')
  } catch (error: any) {
    // 如果接口不存在，使用空数组
    if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
      settlementAccounts.value = []
      return
    }
    ElMessage.error('加载结算账户失败')
  }
}

// 提取指定类型的科目（仅末级科目）
const extractAccountsByType = (tree: AccountDTO[], type: string): AccountDTO[] => {
  const result: AccountDTO[] = []
  const traverse = (nodes: AccountDTO[]) => {
    for (const node of nodes) {
      if (node.accountType === type && node.isLeaf) {
        result.push(node)
      }
      if (node.children && node.children.length > 0) {
        traverse(node.children)
      }
    }
  }
  traverse(tree)
  return result
}

// 格式化金额
const formatAmount = (amount: number) => {
  return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

// 往来单位选择变化处理
const handleOwnerChange = (partnerId: number) => {
  // 根据选择的 partnerId 找到对应的往来单位，设置 ownerName
  const selectedPartner = ownerList.value.find(partner => partner.partnerId === partnerId)
  if (selectedPartner) {
    form.ownerName = selectedPartner.partnerName
    form.ownerId = partnerId
    console.log('选择往来单位:', { partnerId, ownerName: selectedPartner.partnerName })
  } else {
    form.ownerName = ''
    form.ownerId = 0
    console.warn('未找到对应的往来单位，partnerId:', partnerId)
  }
}

// 监听 paymentType 变化，实现级联加载
watch(
  () => form.paymentType,
  async (newType) => {
    // 当类型变化时，清空当前选择的往来单位
    form.ownerId = 0
    form.ownerName = ''
    
    // 根据类型加载对应的往来单位列表
    if (newType === 'RECEIPT') {
      // 收款：加载客户列表
      await loadOwnerList('CUSTOMER')
    } else if (newType === 'PAYMENT') {
      // 付款：加载供应商列表
      await loadOwnerList('SUPPLIER')
    }
  },
  { immediate: false }
)

// 新增
const handleAdd = async () => {
  dialogTitle.value = '新增收付款单'
  isView.value = false
  resetForm()
  
  // 确保数据已加载
  if (settlementAccounts.value.length === 0) {
    await loadSettlementAccounts()
  }
  
  // 根据默认类型加载对应的往来单位列表
  if (form.paymentType === 'RECEIPT') {
    await loadOwnerList('CUSTOMER')
  } else if (form.paymentType === 'PAYMENT') {
    await loadOwnerList('SUPPLIER')
  }
  
  dialogVisible.value = true
}

// 保存
const handleSave = async () => {
  if (!formRef.value) return

  await formRef.value.validate(async (valid) => {
    if (!valid) return

    saving.value = true
    try {
      // 确保 ownerName 已设置（如果用户选择了往来单位但 ownerName 为空，重新查找）
      if (form.ownerId && !form.ownerName) {
        const selectedPartner = ownerList.value.find(partner => partner.partnerId === form.ownerId)
        if (selectedPartner) {
          form.ownerName = selectedPartner.partnerName
        } else {
          ElMessage.error('请选择有效的往来单位')
          saving.value = false
          return
        }
      }
      
      // 构建提交数据对象，确保字段名与后端实体匹配
      // 后端实体字段：id, code, type, partnerName, ownerId, accountId, amount, date, remark, status
      const payload = {
        id: form.paymentId,
        code: form.paymentNo,
        type: form.paymentType, // 'RECEIPT' 或 'PAYMENT'
        partnerName: form.ownerName || '', // 往来单位名称（后端必填）
        ownerId: Number(form.ownerId),
        accountId: Number(form.accountId),
        amount: Number(form.amount),
        date: form.paymentDate, // YYYY-MM-DD 格式
        remark: form.remark || '',
        status: form.status === 'CLEARED' ? 1 : 0 // 0=草稿, 1=已过账
      }
      
      console.log('保存收付款单 - Payload:', payload)
      console.log('partnerName:', payload.partnerName, 'ownerId:', payload.ownerId)
      
      await receiptPaymentApi.saveReceiptPayment(payload)
      ElMessage.success('保存成功')
      dialogVisible.value = false
      // 等待列表刷新完成
      await loadPaymentList()
    } catch (error: any) {
      console.error('保存收付款单失败:', error)
      console.error('错误详情:', error.response?.data || error.message)
      // 如果是404或网络错误，提示接口未实现
      if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
        ElMessage.warning('后端接口尚未实现，请先实现收付款单保存接口')
      } else {
        ElMessage.error(error.message || '保存失败')
      }
    } finally {
      saving.value = false
    }
  })
}

// 重置表单
const resetForm = () => {
  form.paymentType = 'RECEIPT'
  form.paymentDate = new Date().toISOString().split('T')[0]
  form.ownerId = 0
  form.ownerName = '' // 重置往来单位名称
  form.amount = 0
  form.accountId = 0
  form.remark = ''
  // 清空往来单位列表，等待类型变化时重新加载
  ownerList.value = []
  formRef.value?.clearValidate()
}

// 对话框关闭
const handleDialogClose = () => {
  resetForm()
  isView.value = false
}

// 查看
const handleView = async (row: Payment) => {
  try {
    // 重置表单
    resetForm()
    
    // 设置为查看模式
    isView.value = true
    
    // 调用后端 API 获取详情
    const res = await receiptPaymentApi.getReceiptPaymentById(row.paymentId!)
    
    // 映射后端数据到前端表单
    if (res.data) {
      const data = res.data
      form.paymentId = data.id
      form.paymentNo = data.code || ''
      form.paymentDate = data.date || ''
      form.paymentType = data.type || 'RECEIPT'
      form.ownerId = data.ownerId || 0
      form.ownerName = data.partnerName || ''
      form.amount = data.amount || 0
      form.accountId = data.accountId || 0
      form.remark = data.remark || ''
      form.status = data.status === 1 ? 'CLEARED' : 'PENDING'
    }
    
    // 加载往来单位列表（用于显示）
    if (form.paymentType === 'RECEIPT') {
      await loadOwnerList('CUSTOMER')
    } else if (form.paymentType === 'PAYMENT') {
      await loadOwnerList('SUPPLIER')
    }
    
    // 确保结算账户列表已加载
    if (settlementAccounts.value.length === 0) {
      await loadSettlementAccounts()
    }
    
    // 设置对话框标题
    dialogTitle.value = '查看收付款单'
    
    // 打开对话框
    dialogVisible.value = true
  } catch (error: any) {
    console.error('获取收付款单详情失败:', error)
    ElMessage.error(error.message || '获取收付款单详情失败')
  }
}

onMounted(() => {
  loadPaymentList()
  loadSettlementAccounts()
})
</script>

<style scoped lang="scss">
.payment-list {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .dialog-footer {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
  }

  :deep(.el-form-item) {
    margin-bottom: 20px;
  }

  :deep(.el-form-item__label) {
    font-weight: 500;
    color: #303133;
  }
}
</style>
