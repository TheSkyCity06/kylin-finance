<template>
  <div class="add-voucher">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>录入凭证</span>
          <el-button type="primary" @click="handleSave" :loading="saving">
            <el-icon><Check /></el-icon>
            保存凭证
          </el-button>
        </div>
      </template>

      <!-- 凭证基本信息 -->
      <div class="voucher-basic-info">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="交易日期" required>
              <el-date-picker
                v-model="form.transDate"
                type="date"
                placeholder="选择日期"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                :disabled-date="disabledDate"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="凭证号">
              <el-input
                v-model="form.voucherNo"
                placeholder="自动生成"
                readonly
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="状态">
              <el-tag type="warning">草稿</el-tag>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="凭证摘要" required>
          <el-input
            v-model="form.description"
            placeholder="请输入凭证摘要"
            style="width: 100%"
          />
        </el-form-item>
      </div>

      <!-- 分录列表 -->
      <div class="splits-section">
        <div class="section-header">
          <h3>分录信息</h3>
          <el-button type="primary" @click="addSplit">
            <el-icon><Plus /></el-icon>
            添加分录
          </el-button>
        </div>

        <div class="splits-table">
          <el-table
            :data="form.splits || []"
            style="width: 100%"
            :border="true"
          >
            <el-table-column label="科目" width="400">
              <template #default="scope">
                <el-select
                  v-model="scope.row.accountId"
                  placeholder="选择科目（仅末级科目）"
                  filterable
                  style="width: 100%"
                  @change="onAccountChange(scope.$index)"
                >
                  <el-option-group
                    v-for="accountType in accountTypeGroups"
                    :key="accountType.accountType"
                    :label="getAccountTypeName(accountType.accountType)"
                  >
                    <el-option
                      v-for="account in accountType.accounts"
                      :key="account.accountId"
                      :label="`${account.accountCode} ${account.accountName} (${account.path})`"
                      :value="account.accountId"
                      :class="{ 'suggested-account': suggestedAccounts.includes(account.accountId) }"
                    >
                      <div class="account-option">
                        <div class="account-main">
                          <span class="account-code-option">{{ account.accountCode }}</span>
                          <span class="account-name-option">
                            {{ account.accountName }}
                            <el-tag v-if="suggestedAccounts.includes(account.accountId)" type="success" size="small" style="margin-left: 8px">
                              建议
                            </el-tag>
                          </span>
                        </div>
                        <div class="account-path-option">{{ account.path }}</div>
                      </div>
                    </el-option>
                  </el-option-group>
                </el-select>
              </template>
            </el-table-column>

            <el-table-column label="借贷" width="120">
              <template #default="scope">
                <el-select
                  v-model="scope.row.direction"
                  placeholder="选择"
                  style="width: 100%"
                  @change="onDirectionChange(scope.$index)"
                >
                  <el-option label="借方" value="DEBIT" />
                  <el-option label="贷方" value="CREDIT" />
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
                  @change="calculateBalance"
                />
              </template>
            </el-table-column>

            <el-table-column label="摘要">
              <template #default="scope">
                <el-input
                  v-model="scope.row.memo"
                  placeholder="分录摘要"
                />
              </template>
            </el-table-column>

            <el-table-column label="操作" width="80" align="center">
              <template #default="scope">
                <el-button
                  type="danger"
                  size="small"
                  @click="removeSplit(scope.$index)"
                  :disabled="!form.splits || form.splits.length <= 2"
                >
                  <el-icon><Delete /></el-icon>
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>

        <!-- 借贷平衡提示 -->
        <div class="balance-info">
          <el-alert
            :type="isBalanced ? 'success' : 'error'"
            show-icon
            :closable="false"
          >
            <template #title>
              <div class="balance-title">
                <span>借方合计: <span :class="{ 'balance-highlight': !isBalanced }">¥{{ totalDebit.toFixed(2) }}</span></span>
                <span style="margin: 0 10px">|</span>
                <span>贷方合计: <span :class="{ 'balance-highlight': !isBalanced }">¥{{ totalCredit.toFixed(2) }}</span></span>
                <span v-if="!isBalanced" class="balance-diff">
                  (差异: <span class="balance-diff-amount">¥{{ Math.abs(totalDebit - totalCredit).toFixed(2) }}</span>)
                </span>
              </div>
            </template>
            <template #default>
              <div v-if="isBalanced" class="balance-description">
                借贷平衡，可以保存
              </div>
              <div v-else class="balance-description error-text">
                借贷不平衡，请检查分录。差异金额已高亮显示。
              </div>
            </template>
          </el-alert>
        </div>
        
        <!-- 余额方向风险提示 -->
        <div v-if="balanceWarnings.length > 0" class="balance-warnings">
          <el-alert
            v-for="(warning, index) in balanceWarnings"
            :key="index"
            type="warning"
            :title="warning.title"
            :description="warning.description"
            show-icon
            :closable="false"
            style="margin-bottom: 10px"
          />
        </div>
        
        <!-- 科目方向校验提示 -->
        <div v-if="directionWarning" class="direction-warning">
          <el-alert
            type="warning"
            :title="directionWarning"
            show-icon
            :closable="true"
            @close="directionWarning = ''"
          />
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Check, Plus, Delete } from '@element-plus/icons-vue'
import { voucherApi, accountApi, accountingApi } from '@/api/finance'
import type { FinTransaction, FinSplit, AccountDTO } from '@/types/finance'

interface AccountTypeGroup {
  accountType: string
  accounts: AccountDTO[]
}

// 表单数据
const form = reactive<FinTransaction>({
  transDate: new Date().toISOString().split('T')[0],
  description: '',
  splits: [
    {
      accountId: 0,
      direction: 'DEBIT',
      amount: 0,
      memo: ''
    },
    {
      accountId: 0,
      direction: 'CREDIT',
      amount: 0,
      memo: ''
    }
  ]
})

const saving = ref(false)
const accountTypeGroups = ref<AccountTypeGroup[]>([])
const balanceWarnings = ref<Array<{ title: string; description: string }>>([])
const directionWarning = ref('')
const suggestedAccounts = ref<number[]>([]) // 建议的对应科目ID列表

// 计算属性
const totalDebit = computed(() => {
  if (!form.splits) return 0
  return form.splits
    .filter(split => split.direction === 'DEBIT')
    .reduce((sum, split) => sum + (split.amount || 0), 0)
})

const totalCredit = computed(() => {
  if (!form.splits) return 0
  return form.splits
    .filter(split => split.direction === 'CREDIT')
    .reduce((sum, split) => sum + (split.amount || 0), 0)
})

const isBalanced = computed(() => {
  return Math.abs(totalDebit.value - totalCredit.value) < 0.01
})

// 禁用未来日期
const disabledDate = (date: Date) => {
  return date > new Date()
}

// 获取末级科目并按类型分组
const loadAccountTree = async () => {
  try {
    const res = await accountApi.getLeafAccounts()
    const leafAccounts = res.data

    // 按科目类型分组
    const grouped = leafAccounts.reduce((groups: Record<string, AccountDTO[]>, account) => {
      if (!groups[account.accountType]) {
        groups[account.accountType] = []
      }
      groups[account.accountType].push(account)
      return groups
    }, {})

    accountTypeGroups.value = Object.entries(grouped)
      .filter(([type, accounts]) => accounts && Array.isArray(accounts) && accounts.length > 0)
      .map(([type, accounts]) => ({
        accountType: type,
        accounts: accounts as AccountDTO[]
      }))
  } catch (error) {
    ElMessage.error('加载科目数据失败')
  }
}

// 获取科目类型名称
const getAccountTypeName = (type: string): string => {
  const typeNames: Record<string, string> = {
    ASSET: '资产类',
    LIABILITY: '负债类',
    EQUITY: '所有者权益',
    INCOME: '收入类',
    EXPENSE: '支出类'
  }
  return typeNames[type] || type
}

// 添加分录
const addSplit = () => {
  if (!form.splits) {
    form.splits = []
  }
  form.splits.push({
    accountId: 0,
    direction: 'DEBIT',
    amount: 0,
    memo: ''
  })
}

// 删除分录
const removeSplit = async (index: number) => {
  if (!form.splits || form.splits.length <= 2) {
    ElMessage.warning('凭证至少需要一借一贷两条分录')
    return
  }
  form.splits.splice(index, 1)
  // 如果删除的是第一行，清除建议
  if (index === 0) {
    suggestedAccounts.value = []
  }
  await calculateBalance()
}

// 借贷方向变化时处理
const onDirectionChange = async (index: number) => {
  if (!form.splits) return
  const split = form.splits[index]
  if (split && split.accountId) {
    // 如果是第一行，重新建议对应科目
    if (index === 0) {
      const account = accountTypeGroups.value
        .filter(group => group && group.accounts && Array.isArray(group.accounts))
        .flatMap(group => group.accounts)
        .find(acc => acc && acc.accountId === split.accountId)
      if (account) {
        suggestMatchingAccounts(account, split.direction)
      }
    }
    // 校验科目方向组合
    validateAccountDirection()
    // 检查余额方向
    await checkBalanceDirection()
  }
}

// 科目变化时处理
const onAccountChange = async (index: number) => {
  if (!form.splits) return
  const split = form.splits[index]
  if (split && split.accountId) {
    // 验证是否为末级科目（前端双重验证）
    const account = accountTypeGroups.value
      .filter(group => group && group.accounts && Array.isArray(group.accounts))
      .flatMap(group => group.accounts)
      .find(acc => acc && acc.accountId === split.accountId)
    
    if (account && !account.isLeaf) {
      ElMessage.warning('只能选择末级科目进行凭证录入')
      split.accountId = 0
      return
    }
    
    // 如果是第一行，根据科目类型建议对应的科目
    if (index === 0 && account) {
      suggestMatchingAccounts(account, split.direction)
    }
    
    // 校验科目方向组合
    validateAccountDirection()
    
    // 检查余额方向
    await checkBalanceDirection()
  } else {
    suggestedAccounts.value = []
  }
}

// 计算平衡（用于更新显示）
const calculateBalance = async () => {
  // 计算属性会自动更新
  // 检查余额方向
  await checkBalanceDirection()
}

// 根据第一行选择的科目，建议对应的科目
const suggestMatchingAccounts = (account: AccountDTO, direction: string) => {
  suggestedAccounts.value = []
  
  // 定义常见的科目组合规则
  const suggestions: Record<string, Record<string, string[]>> = {
    // 现金/银行存款的借方，通常对应：
    '1001': { // 库存现金
      DEBIT: ['1122', '6001', '1221', '1121'], // 应收账款收回、收入、其他应收款、应收票据
      CREDIT: ['2202', '2211', '2221', '2001'] // 应付账款、应付职工薪酬、应交税费、短期借款
    },
    '1002': { // 银行存款
      DEBIT: ['1122', '6001', '1221', '1121', '6111'], // 应收账款收回、收入、其他应收款、应收票据、投资收益
      CREDIT: ['2202', '2211', '2221', '2001', '2501'] // 应付账款、应付职工薪酬、应交税费、短期借款、长期借款
    },
    '1122': { // 应收账款
      DEBIT: ['6001'], // 通常对应收入
      CREDIT: ['1001', '1002'] // 收回时对应现金/银行存款
    },
    '6001': { // 主营业务收入
      DEBIT: ['1001', '1002', '1122'], // 收到现金/银行存款/应收账款
      CREDIT: [] // 收入通常在贷方
    }
  }
  
  const accountCode = account.accountCode
  const rules = suggestions[accountCode]
  
  if (rules && rules[direction]) {
    const suggestedCodes = rules[direction]
    suggestedAccounts.value = accountTypeGroups.value
      .flatMap(group => group.accounts)
      .filter(acc => suggestedCodes.includes(acc.accountCode))
      .map(acc => acc.accountId)
  }
}

// 校验科目方向组合
const validateAccountDirection = () => {
  directionWarning.value = ''
  
  if (!form.splits || form.splits.length < 2) return
  
  const debits = form.splits.filter(s => s && s.direction === 'DEBIT' && s.accountId)
  const credits = form.splits.filter(s => s && s.direction === 'CREDIT' && s.accountId)
  
  if (debits.length === 0 || credits.length === 0) return
  
  // 检查现金/银行存款的借方
  const cashDebit = debits.find(s => {
    const account = accountTypeGroups.value
      .filter(group => group && group.accounts && Array.isArray(group.accounts))
      .flatMap(group => group.accounts)
      .find(acc => acc && acc.accountId === s.accountId)
    return account && (account.accountCode === '1001' || account.accountCode === '1002')
  })
  
  if (cashDebit) {
    // 检查贷方是否有不常见的科目
    const creditAccounts = credits
      .map(s => {
        if (!s || !s.accountId) return null
        return accountTypeGroups.value
          .filter(group => group && group.accounts && Array.isArray(group.accounts))
          .flatMap(group => group.accounts)
          .find(acc => acc && acc.accountId === s.accountId)
      })
      .filter(Boolean) as AccountDTO[]
    
    const unusualCredits = creditAccounts.filter(acc => {
      // 长期负债、权益类科目在现金借方的贷方不常见
      return acc.accountType === 'LIABILITY' && 
             (acc.accountCode.startsWith('25') || acc.accountCode.startsWith('27')) ||
             acc.accountType === 'EQUITY'
    })
    
    if (unusualCredits.length > 0) {
      directionWarning.value = `警告：现金/银行存款借方通常对应应收账款收回、收入等科目，当前贷方包含${unusualCredits.map(a => a.accountName).join('、')}，请确认业务是否正确。`
    }
  }
}

// 检查余额方向
const checkBalanceDirection = async () => {
  balanceWarnings.value = []
  
  if (!form.transDate || !form.splits) return
  
  for (const split of form.splits) {
    if (!split || !split.accountId || !split.amount) continue
    
    try {
      const res = await accountingApi.calculateAccountBalance(split.accountId, form.transDate)
      if (!res || !res.data) continue
      
      const account = accountTypeGroups.value
        .filter(group => group && group.accounts && Array.isArray(group.accounts))
        .flatMap(group => group.accounts)
        .find(acc => acc && acc.accountId === split.accountId)
      
      if (!account) continue
      
      const currentBalance = res.data.balance
      let newBalance = currentBalance
      
      // 计算新余额
      if (account.accountType === 'ASSET' || account.accountType === 'EXPENSE') {
        // 资产/支出类：增加计入借方，减少计入贷方
        if (split.direction === 'DEBIT') {
          newBalance = currentBalance + split.amount
        } else {
          newBalance = currentBalance - split.amount
        }
      } else {
        // 负债/权益/收入类：增加计入贷方，减少计入借方
        if (split.direction === 'CREDIT') {
          newBalance = currentBalance + split.amount
        } else {
          newBalance = currentBalance - split.amount
        }
      }
      
      // 检查余额是否反向
      if (newBalance < 0) {
        balanceWarnings.value.push({
          title: `科目"${account.accountName}"余额将变为负数`,
          description: `当前余额：¥${currentBalance.toFixed(2)}，录入后余额：¥${newBalance.toFixed(2)}。请确认业务是否正确。`
        })
      }
    } catch (error) {
      // 忽略错误，可能是科目还没有余额
    }
  }
}

// 保存凭证
const handleSave = async () => {
  if (!form.transDate) {
    ElMessage.error('请选择交易日期')
    return
  }

  if (!form.description.trim()) {
    ElMessage.error('请输入凭证摘要')
    return
  }

  if (!form.splits || form.splits.length < 2) {
    ElMessage.error('凭证至少需要一借一贷两条分录')
    return
  }

  // 检查分录是否完整
  for (let i = 0; i < form.splits.length; i++) {
    const split = form.splits[i]
    if (!split || !split.accountId || split.amount <= 0) {
      ElMessage.error(`第${i + 1}条分录信息不完整`)
      return
    }
    
    // 验证是否为末级科目
    const account = accountTypeGroups.value
      .filter(group => group && group.accounts && Array.isArray(group.accounts))
      .flatMap(group => group.accounts)
      .find(acc => acc && acc.accountId === split.accountId)
    
    if (!account || !account.isLeaf) {
      ElMessage.error(`第${i + 1}条分录的科目必须是末级科目`)
      return
    }
  }

  if (!isBalanced.value) {
    ElMessage.error(`借贷不平衡，无法保存。差异金额：¥${Math.abs(totalDebit.value - totalCredit.value).toFixed(2)}`)
    return
  }
  
  // 如果有余额方向警告，需要用户确认
  if (balanceWarnings.value.length > 0) {
    try {
      await ElMessageBox.confirm(
        `存在${balanceWarnings.value.length}个余额方向风险提示，是否继续保存？`,
        '余额方向风险提示',
        {
          confirmButtonText: '继续保存',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )
    } catch {
      return // 用户取消
    }
  }
  
  // 如果有科目方向警告，需要用户确认
  if (directionWarning.value) {
    try {
      await ElMessageBox.confirm(
        directionWarning.value + '\n\n是否继续保存？',
        '科目方向校验警告',
        {
          confirmButtonText: '继续保存',
          cancelButtonText: '取消',
          type: 'warning'
        }
      )
    } catch {
      return // 用户取消
    }
  }

  try {
    saving.value = true
    await voucherApi.addVoucher(form)
    ElMessage.success('凭证保存成功')

    // 重置表单
    resetForm()
  } catch (error) {
    // 错误已在API层面处理
  } finally {
    saving.value = false
  }
}

// 重置表单
const resetForm = () => {
  form.transDate = new Date().toISOString().split('T')[0]
  form.description = ''
  form.splits = [
    {
      accountId: 0,
      direction: 'DEBIT',
      amount: 0,
      memo: ''
    },
    {
      accountId: 0,
      direction: 'CREDIT',
      amount: 0,
      memo: ''
    }
  ]
}

// 监听工具栏保存事件
const handleToolbarSave = (event: CustomEvent) => {
  console.log('[AddVoucher] 收到 toolbar-save 事件', { detail: event.detail })
  handleSave()
}

onMounted(() => {
  loadAccountTree()
  // 监听工具栏事件
  window.addEventListener('toolbar-save', handleToolbarSave as EventListener)
  console.log('[AddVoucher] 已监听 toolbar-save 事件')
})

onUnmounted(() => {
  // 移除事件监听器
  window.removeEventListener('toolbar-save', handleToolbarSave as EventListener)
  console.log('[AddVoucher] 已移除 toolbar-save 事件监听器')
})
</script>

<style scoped>
.add-voucher {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.voucher-basic-info {
  margin-bottom: 30px;
}

.splits-section {
  margin-top: 30px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h3 {
  margin: 0;
  color: #303133;
}

.splits-table {
  margin-bottom: 20px;
}

.balance-info {
  margin-top: 20px;
}

:deep(.el-table th) {
  background-color: #f5f7fa;
  color: #606266;
  font-weight: 600;
}

:deep(.el-table td) {
  padding: 12px 8px;
}

:deep(.el-form-item) {
  margin-bottom: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #303133;
}

.account-option {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.account-main {
  display: flex;
  align-items: center;
  gap: 8px;
}

.account-code-option {
  font-weight: 600;
  color: #409EFF;
  font-size: 14px;
  min-width: 60px;
}

.account-name-option {
  color: #303133;
  font-size: 14px;
  flex: 1;
}

.account-path-option {
  color: #909399;
  font-size: 12px;
  margin-top: 2px;
  padding-left: 68px;
}

:deep(.el-select-dropdown__item) {
  height: auto;
  padding: 8px 20px;
  line-height: normal;
}

:deep(.el-select-dropdown__item:hover) {
  background-color: #f5f7fa;
}

.balance-title {
  display: flex;
  align-items: center;
}

.balance-highlight {
  color: #f56c6c;
  font-weight: 600;
  font-size: 16px;
}

.balance-diff {
  margin-left: 10px;
  color: #909399;
}

.balance-diff-amount {
  color: #f56c6c;
  font-weight: 600;
}

.balance-description {
  margin-top: 8px;
}

.error-text {
  color: #f56c6c;
}

.balance-warnings {
  margin-top: 15px;
}

.direction-warning {
  margin-top: 15px;
}

.suggested-account {
  background-color: #f0f9ff !important;
}

:deep(.suggested-account:hover) {
  background-color: #e6f7ff !important;
}
</style>
