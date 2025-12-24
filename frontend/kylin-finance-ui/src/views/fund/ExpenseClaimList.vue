<template>
  <div class="expense-claim-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>报销单管理</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">
            + 新增报销单
          </el-button>
        </div>
      </template>

      <!-- 查询条件 -->
      <div class="query-form">
        <el-form :model="queryForm" inline>
          <el-form-item label="报销单号">
            <el-input
              v-model="queryForm.claimNo"
              placeholder="输入报销单号"
              clearable
              style="width: 200px"
            />
          </el-form-item>
          <el-form-item label="报销日期">
            <el-date-picker
              v-model="dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              @change="handleDateRangeChange"
            />
          </el-form-item>
          <el-form-item label="状态">
            <el-select
              v-model="queryForm.status"
              placeholder="选择状态"
              clearable
              style="width: 150px"
            >
              <el-option label="草稿" value="DRAFT" />
              <el-option label="已过账" value="POSTED" />
              <el-option label="已冲销" value="REVERSED" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :icon="Search" @click="handleQuery" :loading="loading">
              搜索
            </el-button>
            <el-button :icon="Refresh" @click="resetQuery">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <!-- 报销单列表 -->
      <div class="claim-table">
        <el-table
          :data="claimList"
          border
          stripe
          v-loading="loading"
          style="width: 100%"
        >
          <el-table-column prop="claimNo" label="报销单号" width="150" fixed="left" />
          <el-table-column prop="claimDate" label="报销日期" width="120" />
          <el-table-column prop="applicantName" label="员工姓名" width="120" />
          <el-table-column label="付款账户" width="200">
            <template #default="scope">
              {{ scope.row.creditAccountName || '--' }}
            </template>
          </el-table-column>
          <el-table-column label="总金额" width="150" align="right">
            <template #default="scope">
              <span class="amount-text">¥{{ formatAmount(scope.row.totalAmount) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="100" align="center">
            <template #default="scope">
              <el-tag :type="getStatusType(scope.row.status)">
                {{ getStatusText(scope.row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="280" fixed="right">
            <template #default="scope">
              <el-button
                type="primary"
                size="small"
                :icon="Edit"
                @click="handleEdit(scope.row)"
                :disabled="scope.row.status !== 'DRAFT'"
              >
                编辑
              </el-button>
              <el-button
                type="success"
                size="small"
                :icon="Check"
                @click="handlePost(scope.row)"
                :disabled="scope.row.status !== 'DRAFT'"
              >
                过账
              </el-button>
              <el-button
                type="info"
                size="small"
                :icon="View"
                @click="handleViewVoucher(scope.row)"
                :disabled="!scope.row.voucherId"
              >
                查看凭证
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="pageNum"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadClaimList"
          @current-change="loadClaimList"
        />
      </div>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="900px"
      :close-on-click-modal="false"
      @close="handleDialogClose"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="formRules"
        label-width="120px"
      >
        <!-- 基本信息 -->
        <el-card shadow="never" class="form-section">
          <template #header>
            <span>基本信息</span>
          </template>
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="报销日期" prop="claimDate">
                <el-date-picker
                  v-model="form.claimDate"
                  type="date"
                  placeholder="选择报销日期"
                  format="YYYY-MM-DD"
                  value-format="YYYY-MM-DD"
                  style="width: 100%"
                />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="员工" prop="applicantId">
                <el-input
                  v-model="form.applicantName"
                  placeholder="输入员工姓名"
                  @focus="showEmployeeDialog = true"
                  readonly
                />
              </el-form-item>
            </el-col>
          </el-row>
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="付款账户" prop="creditAccountId">
                <el-select
                  v-model="form.creditAccountId"
                  placeholder="选择付款账户（如银行存款）"
                  filterable
                  style="width: 100%"
                >
                  <el-option
                    v-for="account in assetAccounts"
                    :key="account.accountId"
                    :label="`${account.accountCode} ${account.accountName}`"
                    :value="account.accountId"
                  />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="备注">
                <el-input
                  v-model="form.notes"
                  placeholder="输入备注信息"
                  type="textarea"
                  :rows="2"
                />
              </el-form-item>
            </el-col>
          </el-row>
        </el-card>

        <!-- 费用明细 -->
        <el-card shadow="never" class="form-section" style="margin-top: 20px">
          <template #header>
            <div class="detail-header">
              <span>费用明细</span>
              <el-button type="primary" size="small" :icon="Plus" @click="addDetailRow">
                添加明细
              </el-button>
            </div>
          </template>

          <el-table
            :data="form.details"
            border
            style="width: 100%"
            :summary-method="getSummaries"
            show-summary
          >
            <el-table-column type="index" label="序号" width="60" align="center" />
            <el-table-column label="费用科目" width="300">
              <template #default="scope">
                <el-select
                  v-model="scope.row.debitAccountId"
                  placeholder="选择费用科目"
                  filterable
                  style="width: 100%"
                  @change="onAccountChange(scope.$index)"
                >
                  <el-option-group
                    v-for="group in expenseAccountGroups"
                    :key="group.accountType"
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
            <el-table-column label="金额" width="150">
              <template #default="scope">
                <el-input-number
                  v-model="scope.row.amount"
                  :precision="2"
                  :min="0"
                  controls-position="right"
                  style="width: 100%"
                  @change="calculateTotal"
                />
              </template>
            </el-table-column>
            <el-table-column label="摘要">
              <template #default="scope">
                <el-input
                  v-model="scope.row.description"
                  placeholder="输入摘要说明"
                />
              </template>
            </el-table-column>
            <el-table-column label="操作" width="80" align="center">
              <template #default="scope">
                <el-button
                  type="danger"
                  size="small"
                  :icon="Delete"
                  @click="removeDetailRow(scope.$index)"
                  :disabled="form.details.length <= 1"
                />
              </template>
            </el-table-column>
          </el-table>

          <div class="total-amount">
            <span class="total-label">合计金额：</span>
            <span class="total-value">¥{{ formatAmount(totalAmount) }}</span>
          </div>
        </el-card>
      </el-form>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSave" :loading="saving">
            保存
          </el-button>
          <el-button type="success" @click="handleSaveAndPost" :loading="saving">
            保存并过账
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 员工选择弹窗 -->
    <el-dialog
      v-model="showEmployeeDialog"
      title="选择员工"
      width="600px"
    >
      <el-input
        v-model="employeeSearch"
        placeholder="搜索员工姓名"
        :prefix-icon="Search"
        style="margin-bottom: 20px"
      />
      <el-table
        :data="filteredEmployees"
        @row-click="selectEmployee"
        highlight-current-row
      >
        <el-table-column prop="name" label="员工姓名" />
        <el-table-column prop="department" label="部门" />
      </el-table>
    </el-dialog>

    <!-- 凭证查看弹窗 -->
    <el-dialog
      v-model="voucherDialogVisible"
      title="凭证详情"
      width="800px"
    >
      <div v-if="currentVoucher" class="voucher-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="凭证号">{{ currentVoucher.voucherNo }}</el-descriptions-item>
          <el-descriptions-item label="交易日期">{{ currentVoucher.transDate }}</el-descriptions-item>
          <el-descriptions-item label="摘要" :span="2">{{ currentVoucher.description }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentVoucher.status === 1 ? 'success' : 'warning'">
              {{ currentVoucher.status === 1 ? '已审核' : '草稿' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="录入时间">{{ currentVoucher.enterDate }}</el-descriptions-item>
        </el-descriptions>

        <div class="splits-section" style="margin-top: 20px">
          <h4>分录明细</h4>
          <el-table :data="currentVoucher.splits" border>
            <el-table-column prop="accountCode" label="科目代码" width="120" />
            <el-table-column prop="accountName" label="科目名称" />
            <el-table-column label="借贷" width="100">
              <template #default="scope">
                <el-tag :type="scope.row.direction === 'DEBIT' ? 'primary' : 'success'">
                  {{ scope.row.direction === 'DEBIT' ? '借方' : '贷方' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="amount" label="金额" width="150" align="right">
              <template #default="scope">
                ¥{{ formatAmount(scope.row.amount) }}
              </template>
            </el-table-column>
            <el-table-column prop="memo" label="摘要" />
          </el-table>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { Plus, Search, Refresh, Edit, Check, View, Delete } from '@element-plus/icons-vue'
import { expenseApi } from '@/api/finance/expense'
import type { BizExpenseClaim, BizExpenseClaimDetail } from '@/types/finance'
import { accountApi, type AccountDTO } from '@/api/finance'
import { voucherApi, type FinTransaction } from '@/api/finance'

// 数据定义
const loading = ref(false)
const saving = ref(false)
const claimList = ref<BizExpenseClaim[]>([])
const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)

// 查询表单
const queryForm = reactive({
  claimNo: '',
  startDate: '',
  endDate: '',
  status: ''
})
const dateRange = ref<[string, string] | null>(null)

// 弹窗相关
const dialogVisible = ref(false)
const dialogTitle = ref('新增报销单')
const formRef = ref<FormInstance>()
const form = reactive<BizExpenseClaim>({
  claimId: undefined,
  applicantId: 0,
  applicantName: '',
  claimDate: new Date().toISOString().split('T')[0],
  totalAmount: 0,
  status: 'DRAFT',
  creditAccountId: 0,
  notes: '',
  details: []
})

// 科目数据
const accountTree = ref<AccountDTO[]>([])
const assetAccounts = ref<AccountDTO[]>([]) // 资产类科目（用于付款账户）
const expenseAccountGroups = ref<Array<{
  accountType: string
  label: string
  accounts: AccountDTO[]
}>>([])

// 员工相关
const showEmployeeDialog = ref(false)
const employeeSearch = ref('')
const employees = ref([
  { ownerId: 1, name: '张三', department: '技术部' },
  { ownerId: 2, name: '李四', department: '销售部' },
  { ownerId: 3, name: '王五', department: '财务部' }
])
const filteredEmployees = computed(() => {
  if (!employeeSearch.value) return employees.value
  return employees.value.filter(emp =>
    emp.name.includes(employeeSearch.value) ||
    emp.department.includes(employeeSearch.value)
  )
})

// 凭证查看
const voucherDialogVisible = ref(false)
const currentVoucher = ref<FinTransaction | null>(null)

// 表单验证规则
const formRules: FormRules = {
  claimDate: [{ required: true, message: '请选择报销日期', trigger: 'change' }],
  applicantId: [{ required: true, message: '请选择员工', trigger: 'change' }],
  creditAccountId: [{ required: true, message: '请选择付款账户', trigger: 'change' }]
}

// 计算合计金额
const totalAmount = computed(() => {
  if (!form.details || form.details.length === 0) return 0
  return form.details.reduce((sum, item) => sum + (item.amount || 0), 0)
})

// 加载报销单列表
const loadClaimList = async () => {
  loading.value = true
  try {
    const params = {
      pageNum: pageNum.value,
      pageSize: pageSize.value,
      ...queryForm
    }
    console.log('=== 加载报销单列表 ===')
    console.log('请求参数:', params)
    const res = await expenseApi.getClaimList(params)
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
    if (res.data && res.data.records) {
      claimList.value = res.data.records
      total.value = res.data.total || 0
      console.log('✅ 成功加载报销单列表，记录数:', claimList.value.length, '总数:', total.value)
    } else {
      console.warn('⚠️ 响应数据格式异常，使用空数组')
      claimList.value = []
      total.value = 0
    }
  } catch (error: any) {
    // 如果是404或接口不存在，静默处理，不显示错误
    if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
      claimList.value = []
      total.value = 0
      // 不显示错误消息，因为接口可能还未实现
      return
    }
    // 其他错误才显示消息
    if (error.message && !error.message.includes('404')) {
      ElMessage.error(error.message || '加载报销单列表失败')
    }
  } finally {
    loading.value = false
  }
}

// 加载科目数据
const loadAccounts = async () => {
  try {
    const accounts = await accountApi.getAccountTree()
    accountTree.value = accounts.data || []
    
    // 提取资产类科目（用于付款账户选择）
    assetAccounts.value = extractAccountsByType(accountTree.value, 'ASSET')
    
    // 提取费用类科目（用于费用明细）
    const expenseAccounts = extractAccountsByType(accountTree.value, 'EXPENSE')
    expenseAccountGroups.value = [
      {
        accountType: 'EXPENSE',
        label: '费用类科目',
        accounts: expenseAccounts
      }
    ]
  } catch (error: any) {
    // 如果接口不存在，使用空数组，不显示错误
    if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
      accountTree.value = []
      assetAccounts.value = []
      expenseAccountGroups.value = []
      return
    }
    // 其他错误才显示消息
    if (error.message && !error.message.includes('404')) {
      ElMessage.error('加载科目数据失败')
    }
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

// 查询
const handleQuery = () => {
  pageNum.value = 1
  loadClaimList()
}

// 重置查询
const resetQuery = () => {
  queryForm.claimNo = ''
  queryForm.startDate = ''
  queryForm.endDate = ''
  queryForm.status = ''
  dateRange.value = null
  handleQuery()
}

// 日期范围变化
const handleDateRangeChange = (dates: [string, string] | null) => {
  if (dates) {
    queryForm.startDate = dates[0]
    queryForm.endDate = dates[1]
  } else {
    queryForm.startDate = ''
    queryForm.endDate = ''
  }
}

// 新增
const handleAdd = async () => {
  dialogTitle.value = '新增报销单'
  resetForm()
  
  // 确保科目数据已加载
  if (assetAccounts.value.length === 0) {
    await loadAccounts()
  }
  
  dialogVisible.value = true
}

// 编辑
const handleEdit = async (row: BizExpenseClaim) => {
  dialogTitle.value = '编辑报销单'
  try {
    // 确保科目数据已加载
    if (assetAccounts.value.length === 0) {
      await loadAccounts()
    }
    
    const res = await expenseApi.getClaimById(row.claimId!)
    Object.assign(form, res.data)
    if (!form.details || form.details.length === 0) {
      form.details = [{ debitAccountId: 0, amount: 0, description: '' }]
    }
    dialogVisible.value = true
  } catch (error: any) {
    // 如果是404，说明接口未实现，使用当前行数据
    if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
      Object.assign(form, row)
      if (!form.details || form.details.length === 0) {
        form.details = [{ debitAccountId: 0, amount: 0, description: '' }]
      }
      dialogVisible.value = true
      return
    }
    ElMessage.error(error.message || '加载报销单详情失败')
  }
}

// 过账
const handlePost = async (row: BizExpenseClaim) => {
  try {
    await ElMessageBox.confirm(
      `确定要过账报销单 ${row.claimNo} 吗？过账后将生成凭证并无法修改。`,
      '确认过账',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await expenseApi.postClaim(row.claimId!)
    ElMessage.success('过账成功')
    loadClaimList()
  } catch (error: any) {
    if (error !== 'cancel') {
      // 如果是404或网络错误，提示接口未实现
      if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
        ElMessage.warning('后端接口尚未实现，请先实现报销单过账接口')
      } else {
        ElMessage.error(error.message || '过账失败')
      }
    }
  }
}

// 查看凭证
const handleViewVoucher = async (row: BizExpenseClaim) => {
  if (!row.voucherId) {
    ElMessage.warning('该报销单尚未过账，没有关联凭证')
    return
  }
  try {
    const res = await voucherApi.getVoucherById(row.voucherId)
    currentVoucher.value = res.data
    voucherDialogVisible.value = true
  } catch (error: any) {
    // 如果是404，静默处理
    if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
      ElMessage.warning('凭证数据不存在或接口未实现')
    } else {
      ElMessage.error(error.message || '加载凭证详情失败')
    }
  }
}

// 添加明细行
const addDetailRow = () => {
  if (!form.details) {
    form.details = []
  }
  form.details.push({
    debitAccountId: 0,
    amount: 0,
    description: ''
  })
}

// 删除明细行
const removeDetailRow = (index: number) => {
  if (form.details && form.details.length > 1) {
    form.details.splice(index, 1)
    calculateTotal()
  }
}

// 科目变化
const onAccountChange = (index: number) => {
  // 可以在这里添加科目变化后的逻辑
}

// 计算合计
const calculateTotal = () => {
  form.totalAmount = totalAmount.value
}

// 表格合计行
const getSummaries = (param: any) => {
  const { columns, data } = param
  const sums: string[] = []
  columns.forEach((column: any, index: number) => {
    if (index === 0) {
      sums[index] = '合计'
    } else if (index === 2) {
      sums[index] = `¥${formatAmount(totalAmount.value)}`
    } else {
      sums[index] = ''
    }
  })
  return sums
}

// 选择员工
const selectEmployee = (row: any) => {
  form.applicantId = row.ownerId
  form.applicantName = row.name
  showEmployeeDialog.value = false
  employeeSearch.value = ''
}

// 保存
const handleSave = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    // 验证明细
    if (!form.details || form.details.length === 0) {
      ElMessage.warning('请至少添加一条费用明细')
      return
    }
    
    const hasInvalidDetail = form.details.some(
      detail => !detail.debitAccountId || !detail.amount || detail.amount <= 0
    )
    if (hasInvalidDetail) {
      ElMessage.warning('请完善所有明细行的费用科目和金额')
      return
    }
    
    saving.value = true
    try {
      // 构建提交数据对象
      form.totalAmount = totalAmount.value
      
      // 构建payload，确保数据类型正确
      const payload: BizExpenseClaim = {
        claimId: form.claimId,
        claimNo: form.claimNo,
        applicantId: Number(form.applicantId), // 确保是数字类型
        applicantName: form.applicantName,
        claimDate: form.claimDate, // 已经是 YYYY-MM-DD 格式（通过 value-format 设置）
        totalAmount: form.totalAmount,
        status: form.status || 'DRAFT',
        creditAccountId: Number(form.creditAccountId), // 确保是数字类型
        creditAccountName: form.creditAccountName,
        notes: form.notes,
        voucherId: form.voucherId,
        // 构建明细数组，确保每个字段类型正确
        details: form.details.map(detail => ({
          detailId: detail.detailId,
          claimId: detail.claimId,
          debitAccountId: Number(detail.debitAccountId), // 确保是数字类型
          debitAccountName: detail.debitAccountName,
          amount: Number(detail.amount), // 确保是数字类型
          description: detail.description || ''
        }))
      }
      
      // 打印payload用于调试
      console.log('=== 保存报销单 - Payload ===')
      console.log('完整数据对象:', JSON.stringify(payload, null, 2))
      console.log('报销日期 (claimDate):', payload.claimDate, '类型:', typeof payload.claimDate)
      console.log('员工ID (applicantId):', payload.applicantId, '类型:', typeof payload.applicantId)
      console.log('付款账户ID (creditAccountId):', payload.creditAccountId, '类型:', typeof payload.creditAccountId)
      console.log('费用明细 (details):', payload.details)
      console.log('明细数量:', payload.details?.length)
      payload.details?.forEach((detail, index) => {
        console.log(`  明细[${index}]:`, {
          debitAccountId: detail.debitAccountId,
          debitAccountId类型: typeof detail.debitAccountId,
          amount: detail.amount,
          amount类型: typeof detail.amount,
          description: detail.description
        })
      })
      console.log('总金额 (totalAmount):', payload.totalAmount, '类型:', typeof payload.totalAmount)
      console.log('========================')
      
      if (form.claimId) {
        await expenseApi.updateClaim(payload)
        ElMessage.success('更新成功')
      } else {
        await expenseApi.saveClaim(payload)
        ElMessage.success('保存成功')
      }
      dialogVisible.value = false
      // 等待列表刷新完成
      await loadClaimList()
    } catch (error: any) {
      console.error('保存报销单失败:', error)
      console.error('错误详情:', error.response?.data || error.message)
      // 如果是404或网络错误，提示接口未实现
      if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
        ElMessage.warning('后端接口尚未实现，请先实现报销单保存接口')
      } else {
        ElMessage.error(error.message || '保存失败')
      }
    } finally {
      saving.value = false
    }
  })
}

// 保存并过账
const handleSaveAndPost = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    // 验证明细
    if (!form.details || form.details.length === 0) {
      ElMessage.warning('请至少添加一条费用明细')
      return
    }
    
    const hasInvalidDetail = form.details.some(
      detail => !detail.debitAccountId || !detail.amount || detail.amount <= 0
    )
    if (hasInvalidDetail) {
      ElMessage.warning('请完善所有明细行的费用科目和金额')
      return
    }
    
    try {
      await ElMessageBox.confirm(
        '确定要保存并过账吗？过账后将生成凭证并无法修改。',
        '确认操作',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )
      
      saving.value = true
      
      // 构建提交数据对象
      form.totalAmount = totalAmount.value
      
      // 构建payload，确保数据类型正确
      const payload: BizExpenseClaim = {
        claimId: form.claimId,
        claimNo: form.claimNo,
        applicantId: Number(form.applicantId), // 确保是数字类型
        applicantName: form.applicantName,
        claimDate: form.claimDate, // 已经是 YYYY-MM-DD 格式（通过 value-format 设置）
        totalAmount: form.totalAmount,
        status: form.status || 'DRAFT',
        creditAccountId: Number(form.creditAccountId), // 确保是数字类型
        creditAccountName: form.creditAccountName,
        notes: form.notes,
        voucherId: form.voucherId,
        // 构建明细数组，确保每个字段类型正确
        details: form.details.map(detail => ({
          detailId: detail.detailId,
          claimId: detail.claimId,
          debitAccountId: Number(detail.debitAccountId), // 确保是数字类型
          debitAccountName: detail.debitAccountName,
          amount: Number(detail.amount), // 确保是数字类型
          description: detail.description || ''
        }))
      }
      
      // 打印payload用于调试
      console.log('=== 保存并过账报销单 - Payload ===')
      console.log('完整数据对象:', JSON.stringify(payload, null, 2))
      console.log('报销日期 (claimDate):', payload.claimDate, '类型:', typeof payload.claimDate)
      console.log('员工ID (applicantId):', payload.applicantId, '类型:', typeof payload.applicantId)
      console.log('付款账户ID (creditAccountId):', payload.creditAccountId, '类型:', typeof payload.creditAccountId)
      console.log('费用明细 (details):', payload.details)
      console.log('明细数量:', payload.details?.length)
      payload.details?.forEach((detail, index) => {
        console.log(`  明细[${index}]:`, {
          debitAccountId: detail.debitAccountId,
          debitAccountId类型: typeof detail.debitAccountId,
          amount: detail.amount,
          amount类型: typeof detail.amount,
          description: detail.description
        })
      })
      console.log('总金额 (totalAmount):', payload.totalAmount, '类型:', typeof payload.totalAmount)
      console.log('==================================')
      
      try {
        // 先保存
        if (form.claimId) {
          await expenseApi.updateClaim(payload)
        } else {
          const res = await expenseApi.saveClaim(payload)
          form.claimId = res.data?.claimId
        }
        
        // 再过账
        await expenseApi.postClaim(form.claimId!)
        ElMessage.success('保存并过账成功')
        dialogVisible.value = false
        // 等待列表刷新完成
        await loadClaimList()
      } catch (error: any) {
        console.error('保存并过账报销单失败:', error)
        console.error('错误详情:', error.response?.data || error.message)
        // 如果是404或网络错误，提示接口未实现
        if (error.response?.status === 404 || error.code === 'ERR_NETWORK') {
          ElMessage.warning('后端接口尚未实现，请先实现报销单保存和过账接口')
        } else {
          throw error
        }
      }
    } catch (error: any) {
      if (error !== 'cancel' && !error.response && error.code !== 'ERR_NETWORK') {
        console.error('保存并过账操作失败:', error)
        ElMessage.error(error.message || '操作失败')
      }
    } finally {
      saving.value = false
    }
  })
}

// 重置表单
const resetForm = () => {
  form.claimId = undefined
  form.applicantId = 0
  form.applicantName = ''
  form.claimDate = new Date().toISOString().split('T')[0]
  form.totalAmount = 0
  form.status = 'DRAFT'
  form.creditAccountId = 0
  form.notes = ''
  form.details = [{ debitAccountId: 0, amount: 0, description: '' }]
  formRef.value?.clearValidate()
}

// 弹窗关闭
const handleDialogClose = () => {
  resetForm()
}

// 格式化金额
const formatAmount = (amount: number) => {
  return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

// 获取状态类型
const getStatusType = (status: string) => {
  const statusMap: Record<string, string> = {
    DRAFT: 'info',
    POSTED: 'success',
    REVERSED: 'danger'
  }
  return statusMap[status] || 'info'
}

// 获取状态文本
const getStatusText = (status: string) => {
  const statusMap: Record<string, string> = {
    DRAFT: '草稿',
    POSTED: '已过账',
    REVERSED: '已冲销'
  }
  return statusMap[status] || status
}

// 初始化
onMounted(() => {
  loadAccounts()
  loadClaimList()
})
</script>

<style scoped lang="scss">
.expense-claim-list {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .query-form {
    margin-bottom: 20px;
    padding: 20px;
    background-color: #f8f9fa;
    border-radius: 6px;
  }

  .claim-table {
    margin-bottom: 20px;

    .amount-text {
      font-weight: 600;
      color: #409eff;
    }
  }

  .pagination {
    display: flex;
    justify-content: flex-end;
    margin-top: 20px;
  }

  .form-section {
    margin-bottom: 20px;

    .detail-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .total-amount {
      margin-top: 20px;
      text-align: right;
      padding: 10px;
      background-color: #f5f7fa;
      border-radius: 4px;

      .total-label {
        font-size: 14px;
        color: #606266;
      }

      .total-value {
        font-size: 18px;
        font-weight: 600;
        color: #409eff;
        margin-left: 10px;
      }
    }
  }

  .dialog-footer {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
  }

  .voucher-detail {
    .splits-section {
      margin-top: 20px;

      h4 {
        margin-bottom: 15px;
        color: #303133;
      }
    }
  }
}
</style>
